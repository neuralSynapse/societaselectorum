/* CHRONICA HARUN · Backend Adapter v1.0
 * Isolated infrastructure asset. Loaded by the live game as a passive backend bridge.
 * No privileged credentials. User identity is derived server-side from Neon Auth JWT.
 */
(function (global) {
  'use strict';

  const DEFAULTS = Object.freeze({
    dataApiBase: 'https://ep-green-hill-acstnnfu.apirest.sa-east-1.aws.neon.tech/chronica_harun/rest/v1',
    healthUrl: 'https://chronica-harun-backend.vercel.app/api/health',
    healthFallbackUrl: null
  });

  const ALLOWED_RPC = new Set([
    'start_run',
    'append_run_event',
    'finish_run',
    'upsert_speculi',
    'unlock_codex',
    'save_campaign',
    'update_world_state',
    'record_relic',
    'record_telemetry',
    'campaign_snapshot'
  ]);

  let config = {
    dataApiBase: DEFAULTS.dataApiBase,
    healthUrl: DEFAULTS.healthUrl,
    healthFallbackUrl: DEFAULTS.healthFallbackUrl,
    tokenProvider: null
  };

  function configure(next) {
    next = next || {};
    if (next.dataApiBase) config.dataApiBase = String(next.dataApiBase).replace(/\/$/, '');
    if (next.healthUrl) config.healthUrl = String(next.healthUrl);
    if (next.healthFallbackUrl) config.healthFallbackUrl = String(next.healthFallbackUrl);
    if (Object.prototype.hasOwnProperty.call(next, 'tokenProvider')) {
      if (next.tokenProvider !== null && typeof next.tokenProvider !== 'function') {
        throw new TypeError('tokenProvider must be a function or null');
      }
      config.tokenProvider = next.tokenProvider;
    }
    return api;
  }

  async function getToken() {
    if (typeof config.tokenProvider !== 'function') {
      throw new Error('CHRONICA backend auth tokenProvider is not configured');
    }
    const token = await config.tokenProvider();
    if (!token || typeof token !== 'string') throw new Error('Missing Neon Auth JWT');
    return token;
  }

  async function decodeResponse(response) {
    const raw = await response.text();
    let body = null;
    if (raw) {
      try { body = JSON.parse(raw); } catch (_) { body = raw; }
    }
    if (!response.ok) {
      const detail = body && typeof body === 'object'
        ? (body.message || body.error || JSON.stringify(body))
        : (body || response.statusText);
      const error = new Error('CHRONICA backend request failed: ' + detail);
      error.status = response.status;
      error.body = body;
      throw error;
    }
    return body;
  }

  async function rpc(name, payload) {
    if (!ALLOWED_RPC.has(name)) throw new Error('RPC not allowed by CHRONICA adapter: ' + name);
    const token = await getToken();
    const response = await fetch(config.dataApiBase + '/rpc/' + name, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(payload || {}),
      cache: 'no-store'
    });
    return decodeResponse(response);
  }

  function findHealth(value, depth) {
    if (depth > 6 || value == null) return null;
    if (value && value.ok === true) return value;
    if (Array.isArray(value)) {
      for (let i = 0; i < value.length; i += 1) {
        const found = findHealth(value[i], depth + 1);
        if (found) return found;
      }
      return null;
    }
    if (typeof value === 'object') {
      for (const key of ['data', 'result', 'response', 'body']) {
        if (Object.prototype.hasOwnProperty.call(value, key)) {
          const found = findHealth(value[key], depth + 1);
          if (found) return found;
        }
      }
    }
    return null;
  }

  async function healthRequest(url) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8000);
    try {
      const method = /\/api\/health(?:[?#]|$)/.test(url) ? 'GET' : 'POST';
      const options = {
        method,
        headers: { 'Accept': 'application/json' },
        cache: 'no-store',
        signal: controller.signal
      };
      if (method !== 'GET') {
        options.headers['Content-Type'] = 'application/json';
        options.body = '{}';
      }
      const response = await fetch(url, options);
      const body = await decodeResponse(response);
      const found = findHealth(body, 0);
      if (!found) throw new Error('CHRONICA health response is invalid');
      return found;
    } finally {
      clearTimeout(timer);
    }
  }

  async function health() {
    try {
      return await healthRequest(config.healthUrl);
    } catch (directError) {
      if (!config.healthFallbackUrl || config.healthFallbackUrl === config.healthUrl) throw directError;
      try {
        return await healthRequest(config.healthFallbackUrl);
      } catch (fallbackError) {
        fallbackError.cause = directError;
        throw fallbackError;
      }
    }
  }

  const api = Object.freeze({
    configure,
    health,
    startRun: (seed, characterKey, buildVersion) => rpc('start_run', {
      p_seed: seed,
      p_character_key: characterKey,
      p_build_version: buildVersion
    }),
    appendRunEvent: (runId, eventType, roomKey, payload) => rpc('append_run_event', {
      p_run_id: runId,
      p_event_type: eventType,
      p_room_key: roomKey == null ? null : roomKey,
      p_payload: payload || {}
    }),
    finishRun: (runId, result, durationMs, stats) => rpc('finish_run', {
      p_run_id: runId,
      p_result: result,
      p_duration_ms: durationMs,
      p_stats: stats || {}
    }),
    upsertSpeculi: (entryKey, entryType, content, causality, sourceRunId) => rpc('upsert_speculi', {
      p_entry_key: entryKey,
      p_entry_type: entryType,
      p_content: content || {},
      p_causality: causality || {},
      p_source_run_id: sourceRunId == null ? null : sourceRunId
    }),
    unlockCodex: (codexKey, provenance, sourceRunId, state) => rpc('unlock_codex', {
      p_codex_key: codexKey,
      p_provenance: provenance == null ? null : provenance,
      p_source_run_id: sourceRunId == null ? null : sourceRunId,
      p_state: state || {}
    }),
    saveCampaign: (slot, state, checksum) => rpc('save_campaign', {
      p_slot: slot,
      p_state: state,
      p_checksum: checksum == null ? null : checksum
    }),
    updateWorldState: (attention, state) => rpc('update_world_state', {
      p_attention: attention,
      p_state: state || {}
    }),
    recordRelic: (runId, relicKey, deformationKey, state) => rpc('record_relic', {
      p_run_id: runId,
      p_relic_key: relicKey,
      p_deformation_key: deformationKey == null ? null : deformationKey,
      p_state: state || {}
    }),
    recordTelemetry: (sessionId, eventName, buildVersion, payload) => rpc('record_telemetry', {
      p_session_id: sessionId == null ? null : sessionId,
      p_event_name: eventName,
      p_build_version: buildVersion == null ? null : buildVersion,
      p_payload: payload || {}
    }),
    campaignSnapshot: (slot) => rpc('campaign_snapshot', { p_slot: slot == null ? 1 : slot })
  });

  Object.defineProperty(global, 'CHRONICA_BACKEND', {
    value: api,
    writable: false,
    configurable: false
  });
})(window);
