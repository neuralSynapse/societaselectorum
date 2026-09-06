/* CHRONICA HARUN · Backend Bootstrap v1.0
 * Passive bridge between the live runtime and the backend adapter.
 * Does not patch camera/audio/narrative/rendering or force remote persistence.
 */
(function (global) {
  'use strict';

  const QUEUE_KEY = 'chronica_backend_queue_v1';
  const QUEUE_MAX = 200;
  const WRITE_METHODS = new Set([
    'startRun',
    'appendRunEvent',
    'finishRun',
    'upsertSpeculi',
    'unlockCodex',
    'saveCampaign',
    'updateWorldState',
    'recordRelic',
    'recordTelemetry'
  ]);

  let tokenProvider = null;
  let flushing = false;
  let lastStatus = Object.freeze({
    state: 'booting',
    backend: 'unknown',
    auth: 'unconfigured',
    queued: 0,
    checkedAt: null,
    detail: null
  });

  function adapter() {
    const value = global.CHRONICA_BACKEND;
    if (!value || typeof value.health !== 'function') {
      throw new Error('CHRONICA_BACKEND adapter is not loaded');
    }
    return value;
  }

  function readQueue() {
    try {
      const raw = global.localStorage && global.localStorage.getItem(QUEUE_KEY);
      if (!raw) return [];
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed.slice(-QUEUE_MAX) : [];
    } catch (_) {
      return [];
    }
  }

  function writeQueue(queue) {
    try {
      if (!global.localStorage) return false;
      const bounded = Array.isArray(queue) ? queue.slice(-QUEUE_MAX) : [];
      global.localStorage.setItem(QUEUE_KEY, JSON.stringify(bounded));
      return true;
    } catch (_) {
      return false;
    }
  }

  function emit(next) {
    const merged = Object.assign({}, lastStatus, next || {}, {
      queued: readQueue().length,
      checkedAt: new Date().toISOString()
    });
    lastStatus = Object.freeze(merged);
    global.__CHRONICA_BACKEND_STATUS__ = lastStatus;
    try {
      global.dispatchEvent(new CustomEvent('chronica:backend-status', { detail: lastStatus }));
    } catch (_) {}
    return lastStatus;
  }

  function queueWrite(method, args) {
    if (!WRITE_METHODS.has(method)) throw new Error('Method is not queueable: ' + method);
    const queue = readQueue();
    queue.push({
      id: String(Date.now()) + '-' + Math.random().toString(36).slice(2, 10),
      method: method,
      args: Array.isArray(args) ? args : [],
      createdAt: new Date().toISOString(),
      attempts: 0
    });
    const stored = writeQueue(queue);
    emit({
      state: stored ? 'queued' : 'local-only',
      auth: tokenProvider ? 'configured' : 'unconfigured',
      detail: stored ? 'Remote write queued until an authenticated token provider is available.' : 'Queue storage unavailable.'
    });
    return { queued: stored, remote: false, id: stored ? queue[queue.length - 1].id : null };
  }

  function configureTokenProvider(provider) {
    if (typeof provider !== 'function') throw new TypeError('tokenProvider must be a function');
    tokenProvider = provider;
    adapter().configure({ tokenProvider: provider });
    emit({ state: 'ready', auth: 'configured', detail: 'Authenticated token provider configured.' });
    void flush();
    return api;
  }

  function clearTokenProvider() {
    tokenProvider = null;
    adapter().configure({ tokenProvider: null });
    emit({ state: 'ready', auth: 'unconfigured', detail: 'Remote persistence paused; local runtime remains available.' });
    return api;
  }

  async function health() {
    try {
      const result = await adapter().health();
      emit({ state: 'ready', backend: 'healthy', detail: null });
      return result;
    } catch (error) {
      emit({ state: 'degraded', backend: 'unreachable', detail: error && error.message ? error.message : String(error) });
      throw error;
    }
  }

  async function invoke(method) {
    const args = Array.prototype.slice.call(arguments, 1);
    const target = adapter()[method];
    if (typeof target !== 'function') throw new Error('Unknown CHRONICA backend method: ' + method);

    if (WRITE_METHODS.has(method) && !tokenProvider) return queueWrite(method, args);

    try {
      const result = await target.apply(null, args);
      emit({ state: 'ready', auth: tokenProvider ? 'configured' : lastStatus.auth, detail: null });
      return result;
    } catch (error) {
      const message = error && error.message ? error.message : String(error);
      if (WRITE_METHODS.has(method) && (/tokenProvider|Missing Neon Auth JWT|401|403/i).test(message)) {
        return queueWrite(method, args);
      }
      emit({ state: 'degraded', detail: message });
      throw error;
    }
  }

  async function flush() {
    if (flushing || !tokenProvider) return { flushed: 0, remaining: readQueue().length };
    flushing = true;
    let queue = readQueue();
    let flushed = 0;
    const remaining = [];

    try {
      for (let i = 0; i < queue.length; i += 1) {
        const item = queue[i];
        if (!item || !WRITE_METHODS.has(item.method)) continue;
        try {
          const fn = adapter()[item.method];
          if (typeof fn !== 'function') throw new Error('Adapter method missing: ' + item.method);
          await fn.apply(null, Array.isArray(item.args) ? item.args : []);
          flushed += 1;
        } catch (error) {
          item.attempts = Number(item.attempts || 0) + 1;
          item.lastError = error && error.message ? String(error.message).slice(0, 240) : String(error).slice(0, 240);
          remaining.push(item);
          for (let j = i + 1; j < queue.length; j += 1) remaining.push(queue[j]);
          break;
        }
      }
      writeQueue(remaining);
      emit({
        state: remaining.length ? 'degraded' : 'ready',
        auth: 'configured',
        detail: remaining.length ? 'Queue flush paused after a backend error.' : null
      });
      return { flushed: flushed, remaining: remaining.length };
    } finally {
      flushing = false;
    }
  }

  function status() {
    return lastStatus;
  }

  function pending() {
    return readQueue().slice();
  }

  const api = Object.freeze({
    configureTokenProvider: configureTokenProvider,
    clearTokenProvider: clearTokenProvider,
    health: health,
    flush: flush,
    status: status,
    pending: pending,
    startRun: function () { return invoke.apply(null, ['startRun'].concat(Array.prototype.slice.call(arguments))); },
    appendRunEvent: function () { return invoke.apply(null, ['appendRunEvent'].concat(Array.prototype.slice.call(arguments))); },
    finishRun: function () { return invoke.apply(null, ['finishRun'].concat(Array.prototype.slice.call(arguments))); },
    upsertSpeculi: function () { return invoke.apply(null, ['upsertSpeculi'].concat(Array.prototype.slice.call(arguments))); },
    unlockCodex: function () { return invoke.apply(null, ['unlockCodex'].concat(Array.prototype.slice.call(arguments))); },
    saveCampaign: function () { return invoke.apply(null, ['saveCampaign'].concat(Array.prototype.slice.call(arguments))); },
    updateWorldState: function () { return invoke.apply(null, ['updateWorldState'].concat(Array.prototype.slice.call(arguments))); },
    recordRelic: function () { return invoke.apply(null, ['recordRelic'].concat(Array.prototype.slice.call(arguments))); },
    recordTelemetry: function () { return invoke.apply(null, ['recordTelemetry'].concat(Array.prototype.slice.call(arguments))); },
    campaignSnapshot: function () { return invoke.apply(null, ['campaignSnapshot'].concat(Array.prototype.slice.call(arguments))); }
  });

  Object.defineProperty(global, 'CHRONICA_BACKEND_BRIDGE', {
    value: api,
    writable: false,
    configurable: false
  });

  global.addEventListener('chronica:auth-token-provider', function (event) {
    const provider = event && event.detail && event.detail.tokenProvider;
    if (typeof provider === 'function') configureTokenProvider(provider);
  });

  emit({ state: 'booting', detail: 'Backend bridge loaded; remote persistence is opt-in behind authentication.' });
  Promise.resolve().then(health).catch(function () {});
})(window);
