(function () {
  const root = document.documentElement;
  const saved = localStorage.getItem('crs-theme');
  const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  root.dataset.theme = saved || (prefersDark ? 'dark' : 'light');

  window.CRSTheme = {
    toggle: function () {
      const next = root.dataset.theme === 'dark' ? 'light' : 'dark';
      root.dataset.theme = next;
      localStorage.setItem('crs-theme', next);
      document.querySelectorAll('[data-theme-icon]').forEach(function (el) {
        el.textContent = next === 'dark' ? '☀' : '☾';
      });
    }
  };

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('[data-theme-icon]').forEach(function (el) {
      el.textContent = root.dataset.theme === 'dark' ? '☀' : '☾';
    });
    if (!document.querySelector('[data-crs-auto-theme]')) {
      const button = document.createElement('button');
      button.type = 'button';
      button.dataset.crsAutoTheme = 'true';
      button.className = 'crs-auto-theme-toggle';
      button.setAttribute('aria-label', 'Toggle theme');
      button.textContent = root.dataset.theme === 'dark' ? '☀' : '☾';
      button.addEventListener('click', function () {
        window.CRSTheme.toggle();
        button.textContent = root.dataset.theme === 'dark' ? '☀' : '☾';
      });
      document.body.appendChild(button);
    }
  });
})();
