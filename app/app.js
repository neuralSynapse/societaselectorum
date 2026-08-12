(() => {
  'use strict';

  const views = [...document.querySelectorAll('[data-view]')];
  const navButtons = [...document.querySelectorAll('[data-nav]')];
  const bottomNavButtons = [...document.querySelectorAll('.bottom-nav [data-nav]')];
  const toast = document.getElementById('toast');
  const installButton = document.getElementById('installButton');
  const installCta = document.getElementById('installCta');
  const installHelp = document.getElementById('installHelp');
  let deferredInstallPrompt = null;
  let toastTimer = null;

  function showToast(message) {
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add('is-visible');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('is-visible'), 2600);
  }

  function activateView(name, pushState = true) {
    const target = document.querySelector(`[data-view="${name}"]`);
    if (!target) return;
    views.forEach(view => view.classList.toggle('is-active', view === target));
    bottomNavButtons.forEach(button => {
      const active = button.dataset.nav === name;
      button.classList.toggle('is-active', active);
      active ? button.setAttribute('aria-current', 'page') : button.removeAttribute('aria-current');
    });
    document.title = name === 'centro' ? 'Societas Electorum' : `${name[0].toUpperCase()}${name.slice(1)} · Societas Electorum`;
    if (pushState) history.replaceState(null, '', `#${name}`);
    try { localStorage.setItem('se:last-view', name); } catch (_) {}
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  navButtons.forEach(button => button.addEventListener('click', event => {
    const target = button.dataset.nav;
    if (!target) return;
    event.preventDefault();
    activateView(target);
  }));

  const initialHash = location.hash.replace('#', '');
  let savedView = '';
  try { savedView = localStorage.getItem('se:last-view') || ''; } catch (_) {}
  activateView(initialHash || savedView || 'centro', false);

  window.addEventListener('beforeinstallprompt', event => {
    event.preventDefault();
    deferredInstallPrompt = event;
    if (installButton) installButton.hidden = false;
    if (installCta) installCta.hidden = false;
    if (installHelp) installHelp.textContent = 'Seu navegador permite instalar esta versão como aplicativo.';
  });

  async function requestInstall() {
    if (deferredInstallPrompt) {
      deferredInstallPrompt.prompt();
      const result = await deferredInstallPrompt.userChoice;
      deferredInstallPrompt = null;
      if (installButton) installButton.hidden = true;
      showToast(result.outcome === 'accepted' ? 'Instalação iniciada.' : 'Instalação cancelada.');
      return;
    }
    const isIOS = /iphone|ipad|ipod/i.test(navigator.userAgent);
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
    if (isStandalone) showToast('A Societas já está aberta como aplicativo.');
    else if (isIOS) {
      showToast('No Safari: Compartilhar → Adicionar à Tela de Início.');
      if (installHelp) installHelp.textContent = 'No iPhone, abra no Safari e use Compartilhar → Adicionar à Tela de Início.';
    } else showToast('Use o menu do navegador e escolha Instalar aplicativo ou Adicionar à tela inicial.');
  }

  installButton?.addEventListener('click', requestInstall);
  installCta?.addEventListener('click', requestInstall);
  window.addEventListener('appinstalled', () => {
    deferredInstallPrompt = null;
    if (installButton) installButton.hidden = true;
    if (installHelp) installHelp.textContent = 'Aplicativo instalado neste dispositivo.';
    showToast('Societas Electorum instalada.');
  });

  const catalog = Array.isArray(window.SOCIETAS_CATALOG) ? window.SOCIETAS_CATALOG : [];
  const chips = [...document.querySelectorAll('#libraryFilters .chip')];
  const librarySearch = document.getElementById('librarySearch');
  const libraryState = document.getElementById('libraryState');
  const libraryCount = document.getElementById('libraryCount');
  let activeFilter = 'todos';

  const escapeHtml = value => String(value ?? '').replace(/[&<>'"]/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#039;','"':'&quot;'}[char]));

  function matchesFilter(item) {
    const type = (item.type || '').toLowerCase();
    const access = (item.access || '').toLowerCase();
    if (activeFilter === 'todos') return true;
    if (activeFilter === 'publico') return access.includes('público') || access.includes('publico');
    return type.includes(activeFilter);
  }

  function renderCatalog() {
    if (!libraryState) return;
    const query = (librarySearch?.value || '').trim().toLowerCase();
    const items = catalog.filter(item => {
      const haystack = [item.title,item.subtitle,item.author,item.category,item.type,item.access].join(' ').toLowerCase();
      return matchesFilter(item) && (!query || haystack.includes(query));
    });

    if (libraryCount) libraryCount.textContent = `${items.length} ${items.length === 1 ? 'publicação' : 'publicações'}`;
    if (!items.length) {
      libraryState.innerHTML = '<div class="library-empty"><div class="empty-symbol">⌕</div><h2>Nenhum resultado</h2><p>Ajuste a busca ou o filtro. O catálogo exibido contém apenas registros publicados.</p></div>';
      return;
    }

    libraryState.innerHTML = items.map(item => {
      const target = item.url || window.SOCIETAS_CONFIG?.routes?.library || 'https://www.sociedadedoseleitos.com/biblioteca';
      const meta = [item.type, item.minutes ? `${item.minutes} min` : null].filter(Boolean).join(' · ');
      return `<a class="book-card" href="${escapeHtml(target)}" aria-label="Abrir ${escapeHtml(item.title)}">
        <div class="book-cover-wrap">${item.cover ? `<img class="book-cover" src="${escapeHtml(item.cover)}" alt="Capa de ${escapeHtml(item.title)}" loading="lazy">` : '<div class="book-cover-placeholder">SE</div>'}</div>
        <div class="book-copy">
          <small>${escapeHtml(item.category)}</small>
          <h2>${escapeHtml(item.title)}</h2>
          <p>${escapeHtml(item.subtitle || '')}</p>
          <div class="book-meta"><span>${escapeHtml(item.author)}</span><span>${escapeHtml(meta)}</span></div>
          <span class="access-tag">${escapeHtml(item.access)}</span>
        </div>
      </a>`;
    }).join('');
  }

  chips.forEach(chip => chip.addEventListener('click', () => {
    chips.forEach(item => item.classList.remove('is-active'));
    chip.classList.add('is-active');
    activeFilter = chip.dataset.filter || 'todos';
    renderCatalog();
  }));
  librarySearch?.addEventListener('input', renderCatalog);
  renderCatalog();

  const timerDisplay = document.getElementById('timerDisplay');
  const timerRange = document.getElementById('timerRange');
  const timerStart = document.getElementById('timerStart');
  const timerReset = document.getElementById('timerReset');
  let timerId = null;
  let secondsRemaining = Number(timerRange?.value || 5) * 60;
  let timerRunning = false;

  function renderTimer() {
    if (!timerDisplay) return;
    const minutes = Math.floor(secondsRemaining / 60);
    const seconds = secondsRemaining % 60;
    timerDisplay.textContent = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
  }
  function stopTimer() {
    clearInterval(timerId); timerId = null; timerRunning = false;
    if (timerStart) timerStart.textContent = 'Iniciar';
  }
  timerRange?.addEventListener('input', () => { stopTimer(); secondsRemaining = Number(timerRange.value) * 60; renderTimer(); });
  timerStart?.addEventListener('click', () => {
    if (timerRunning) return stopTimer();
    if (secondsRemaining <= 0) secondsRemaining = Number(timerRange?.value || 5) * 60;
    timerRunning = true; timerStart.textContent = 'Pausar';
    timerId = setInterval(() => {
      secondsRemaining -= 1; renderTimer();
      if (secondsRemaining <= 0) {
        stopTimer();
        showToast('Prática concluída. O registro será sincronizado quando a conta estiver integrada.');
        if ('vibrate' in navigator) navigator.vibrate([120,80,120]);
      }
    }, 1000);
  });
  timerReset?.addEventListener('click', () => { stopTimer(); secondsRemaining = Number(timerRange?.value || 5) * 60; renderTimer(); });
  renderTimer();

  if ('serviceWorker' in navigator) window.addEventListener('load', () => {
    navigator.serviceWorker.register('./service-worker.js', { scope: './' }).catch(() => console.info('Service worker indisponível neste ambiente de prévia.'));
  });
})();
