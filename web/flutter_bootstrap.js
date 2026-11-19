{{flutter_js}}
{{flutter_build_config}}

(() => {
  const isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  // Allows testing the exact mobile rendering path on a desktop browser too.
  const forceSoftware = new URLSearchParams(window.location.search).get('render') === 'software';

  _flutter.loader.load({
    config: {
      // Mobile browsers can discard WebGL contexts while a tab is hidden.
      // This mostly static catalogue can use CanvasKit's software renderer
      // without relying on the discarded GPU context when the user returns.
      canvasKitForceCpuOnly: isMobile || forceSoftware,
      canvasKitMaximumSurfaces: 2,
      // Ship the engine with the site instead of relying on a third-party CDN.
      canvasKitBaseUrl: 'canvaskit/',
    },
  });
})();
