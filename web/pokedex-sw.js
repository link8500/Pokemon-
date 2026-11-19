/* Cache only this application's files; never prefetch the Pokémon collection. */
'use strict';
var BUILD = '__POKEDEX_BUILD__';
var PREFIX = 'pokedex-';
var SHELL = PREFIX + 'shell-' + BUILD;
var IMAGES = PREFIX + 'images-' + BUILD;
var DETAILS = PREFIX + 'details-' + BUILD;
var FULL = PREFIX + 'full-' + BUILD;
var ROOT = new URL('./', self.location.href);
var INDEX = new URL('index.html', ROOT).href;
var SHELL_FILES = [
  'index.html', 'app-loader.js?v=' + BUILD,
  'lite/pokedex-core.js?v=' + BUILD, 'lite/pokedex.js?v=' + BUILD,
  'lite/pokedex.css?v=' + BUILD, 'assets/assets/data/catalog.json?v=' + BUILD,
  'lite/pikachu.webp', 'favicon.svg', 'favicon.svg?v=2',
  'icons/pokedex-32-v2.png',
  'manifest.json?v=2'
];

function save(name, request, response, limit) {
  // Opaque responses can consume several MB of quota even for a tiny image.
  if (!response || !response.ok || response.type === 'opaque') return Promise.resolve();
  var copy = response.clone();
  return caches.open(name).then(function (cache) {
    return cache.put(request, copy).then(function () {
      if (!limit) return;
      return cache.keys().then(function (keys) {
        return Promise.all(keys.slice(0, Math.max(0, keys.length - limit)).map(function (key) {
          return cache.delete(key);
        }));
      });
    });
  }).catch(function () { /* Low storage must not interrupt a successful request. */ });
}

self.addEventListener('install', function (event) {
  event.waitUntil(caches.open(SHELL).then(function (cache) {
    return Promise.all(SHELL_FILES.map(function (path) {
      var url = new URL(path, ROOT).href;
      return fetch(new Request(url, { cache: path === 'index.html' ? 'reload' : 'force-cache' }))
        .then(function (response) {
          if (!response.ok) throw new Error('Missing offline file: ' + path);
          return cache.put(url, response);
        });
    }));
  }).then(function () {
    return caches.open(IMAGES).then(function (cache) {
      // Just the first page, about 12 KB. Other sprites are cached as they are seen.
      return Promise.all(Array.from({ length: 12 }, function (_, index) {
        var url = new URL('lite/sprites/' + (index + 1) + '.png', ROOT).href;
        return fetch(new Request(url, { cache: 'force-cache' })).then(function (response) {
          if (response.ok) return cache.put(url, response);
        });
      }));
    }).catch(function () {});
  }).then(function () { return self.skipWaiting(); }));
});

self.addEventListener('activate', function (event) {
  event.waitUntil(caches.keys().then(function (names) {
    return Promise.all(names.filter(function (name) {
      return name.indexOf(PREFIX) === 0 && [SHELL, IMAGES, DETAILS, FULL].indexOf(name) < 0;
    }).map(function (name) { return caches.delete(name); }));
  }).then(function () { return self.clients.claim(); }));
});

function cachedFirst(event, name, limit) {
  return caches.open(name).then(function (cache) {
    return cache.match(event.request);
  }).catch(function () { return null; }).then(function (cached) {
      if (cached) return cached;
      return fetch(event.request).then(function (response) {
        return save(name, event.request, response, limit).then(function () { return response; });
      });
  });
}

function navigate(request) {
  var timer;
  var offline = function () {
    return caches.open(SHELL).then(function (cache) { return cache.match(INDEX); })
      .then(function (cached) {
        if (cached) return cached;
        return new Response('Conéctate una vez para preparar la Pokédex sin conexión.', {
          status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' }
        });
      });
  };
  if (self.navigator.onLine === false) return offline();
  var timeout = new Promise(function (_, reject) {
    timer = setTimeout(function () { reject(new Error('Navigation timeout')); }, 2500);
  });
  return Promise.race([fetch(request).then(function (response) {
    if (!response.ok) throw new Error('Navigation failed');
    return response;
  }), timeout]).catch(offline).then(function (response) {
    clearTimeout(timer);
    return response;
  });
}

self.addEventListener('fetch', function (event) {
  if (event.request.method !== 'GET') return;
  var url = new URL(event.request.url);
  var sameOrigin = url.origin === ROOT.origin;
  var path = sameOrigin && url.pathname.indexOf(ROOT.pathname) === 0
    ? url.pathname.slice(ROOT.pathname.length) : '';
  if (sameOrigin && event.request.mode === 'navigate') {
    event.respondWith(navigate(event.request));
  } else if (sameOrigin && /^lite\/sprites\/\d+\.png$/.test(path)) {
    event.respondWith(cachedFirst(event, IMAGES, 128));
  } else if (url.origin === 'https://raw.githubusercontent.com' &&
      /^\/PokeAPI\/sprites\/master\/sprites\/pokemon\/shiny\/\d+\.png$/.test(url.pathname)) {
    event.respondWith(cachedFirst(event, IMAGES, 128));
  } else if (url.origin === 'https://pokeapi.co' &&
      /^\/api\/v2\/pokemon-species\/\d+\/?$/.test(url.pathname)) {
    event.respondWith(cachedFirst(event, DETAILS, 20));
  } else if (sameOrigin && (path.indexOf('canvaskit/') === 0 ||
      path.indexOf('assets/') === 0 || /^(main\.dart\.js|flutter_bootstrap\.js)$/.test(path))) {
    event.respondWith(caches.open(SHELL).then(function (cache) {
      return cache.match(event.request);
    }).catch(function () { return null; }).then(function (cached) { return cached || cachedFirst(event, FULL, 32); }));
  } else if (sameOrigin) {
    // Restrict shell caching to known files. Do not cache arbitrary URLs forever.
    event.respondWith(caches.open(SHELL).then(function (cache) {
      return cache.match(event.request);
    }).catch(function () { return null; }).then(function (cached) { return cached || fetch(event.request); }));
  }
});
