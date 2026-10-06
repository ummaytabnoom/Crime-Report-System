(function () {
  const root = document.documentElement;

  function applyTheme(theme) {
    root.dataset.theme = theme;
    localStorage.setItem('crs-theme', theme);
    document.querySelectorAll('[data-theme-icon]').forEach(function (el) {
      el.textContent = theme === 'dark' ? '☀' : '☾';
    });
  }

  const saved = localStorage.getItem('crs-theme');
  const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  applyTheme(saved || (prefersDark ? 'dark' : 'light'));

  window.CRSTheme = {
    toggle: function () {
      applyTheme(root.dataset.theme === 'dark' ? 'light' : 'dark');
    }
  };

  // Backward-compatible function for older JSPs. The implementation is shared.
  window.toggleMenu = function () {
    const menu = document.getElementById('dropdownMenu');
    if (menu) menu.classList.toggle('show');
  };

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('[data-theme-icon]').forEach(function (el) {
      el.textContent = root.dataset.theme === 'dark' ? '☀' : '☾';
    });

    const accountTrigger = document.querySelector('.crs-account-trigger');
    const accountMenu = document.querySelector('.crs-account-menu');
    if (accountTrigger && accountMenu) {
      accountTrigger.addEventListener('click', function (event) {
        event.stopPropagation();
        const open = accountMenu.classList.toggle('is-open');
        accountTrigger.setAttribute('aria-expanded', String(open));
      });
    }

    const mobileTrigger = document.querySelector('.crs-mobile-menu');
    const mobileNav = document.getElementById('crsMobileNav');
    if (mobileTrigger && mobileNav) {
      mobileTrigger.addEventListener('click', function (event) {
        event.stopPropagation();
        const open = mobileNav.classList.toggle('is-open');
        mobileTrigger.setAttribute('aria-expanded', String(open));
      });
    }

    document.addEventListener('click', function (event) {
      if (accountMenu && accountTrigger && !accountMenu.contains(event.target) && !accountTrigger.contains(event.target)) {
        accountMenu.classList.remove('is-open');
        accountTrigger.setAttribute('aria-expanded', 'false');
      }
      if (mobileNav && mobileTrigger && !mobileNav.contains(event.target) && !mobileTrigger.contains(event.target)) {
        mobileNav.classList.remove('is-open');
        mobileTrigger.setAttribute('aria-expanded', 'false');
      }
      const legacyMenu = document.getElementById('dropdownMenu');
      if (legacyMenu && !event.target.closest('.menu-icon') && !event.target.closest('#dropdownMenu')) {
        legacyMenu.classList.remove('show');
      }
    });
  });
})();