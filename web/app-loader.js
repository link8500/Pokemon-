(function () {
  'use strict';
  var release = '__POKEDEX_BUILD__';
  var viewMatch = /(?:^\?|&)view=(lite|full)(?:&|$)/.exec(window.location.search);
  var mobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  var connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
  var limited = (navigator.deviceMemory && navigator.deviceMemory <= 2) ||
    (navigator.hardwareConcurrency && navigator.hardwareConcurrency <= 4);
  var preference;
  try { preference = localStorage.getItem('pokedex.view'); } catch (_) {}
  var requested = (viewMatch && viewMatch[1]) || preference;
  var lite = requested === 'lite' || (requested !== 'full' &&
    (mobile || limited || (connection && connection.saveData) || !window.WebAssembly));

  window.POKEDEX_RELEASE = release;
  window.POKEDEX_MODE = lite ? 'lite' : 'full';
  document.documentElement.setAttribute('data-mode', window.POKEDEX_MODE);

  function resource(path) { return path + '?v=' + encodeURIComponent(release); }
  function script(path, loaded) {
    var element = document.createElement('script');
    element.src = resource(path);
    if (loaded) element.onload = loaded;
    element.onerror = function () {
      var loading = document.getElementById('loading');
      if (loading) loading.textContent = 'No se pudo abrir la Pokédex. Revisa la conexión y vuelve a cargar.';
    };
    document.body.appendChild(element);
  }

  if (lite) {
    var style = document.createElement('link');
    style.rel = 'stylesheet';
    style.href = resource('lite/pokedex.css');
    document.head.appendChild(style);
    script('lite/pokedex-core.js', function () { script('lite/pokedex.js'); });
  } else {
    script('flutter_bootstrap.js');
    var switcher = document.createElement('a');
    switcher.href = '?view=lite';
    switcher.textContent = 'Activar ahorro de datos';
    switcher.style.cssText = 'position:fixed;right:12px;bottom:10px;z-index:2147483647;padding:12px 16px;background:#fff;color:#a72c34;border:1px solid #efd6d8;border-radius:10px;font:13px system-ui;text-decoration:none';
    switcher.onclick = function () { try { localStorage.setItem('pokedex.view', 'lite'); } catch (_) {} };
    document.body.appendChild(switcher);
  }

  // Do not register an unversioned worker after a plain, unfinished build.
  // The export script replaces this token with a hash of the shipped files.
  if ('serviceWorker' in navigator && release.indexOf('__') !== 0) {
    navigator.serviceWorker.register(resource('pokedex-sw.js'), { updateViaCache: 'none' })
      .catch(function () { /* The application also works if storage is disabled. */ });
  }
})();
