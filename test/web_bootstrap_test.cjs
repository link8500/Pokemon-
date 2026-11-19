const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

const bootstrap = fs.readFileSync(path.join(__dirname, '../web/flutter_bootstrap.js'), 'utf8')
  .replace(/\{\{flutter_js\}\}/g, '')
  .replace(/\{\{flutter_build_config\}\}/g, '');

function configuration(navigator, search = '') {
  let received;
  vm.runInNewContext(bootstrap, {
    navigator,
    URLSearchParams,
    window: { location: { search } },
    _flutter: { loader: { load: (options) => { received = options.config; } } },
  });
  return received;
}

test('Android uses software rendering to avoid WebGL loss on tab resume', () => {
  assert.equal(configuration({ userAgent: 'Mozilla/5.0 (Linux; Android 14) Chrome/130 Mobile', platform: 'Linux', maxTouchPoints: 5 }).canvasKitForceCpuOnly, true);
});
test('iPhone and iPad use the same compatibility path', () => {
  assert.equal(configuration({ userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)', platform: 'iPhone', maxTouchPoints: 5 }).canvasKitForceCpuOnly, true);
  assert.equal(configuration({ userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)', platform: 'MacIntel', maxTouchPoints: 5 }).canvasKitForceCpuOnly, true);
});
test('desktop retains hardware rendering with a bounded surface count', () => {
  const config = configuration({ userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', platform: 'Win32', maxTouchPoints: 0 });
  assert.equal(config.canvasKitForceCpuOnly, false);
  assert.equal(config.canvasKitMaximumSurfaces, 2);
  assert.equal(config.canvasKitBaseUrl, 'canvaskit/');
});
test('the mobile rendering path can also be verified on desktop', () => {
  const config = configuration({ userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', platform: 'Win32', maxTouchPoints: 0 }, '?render=software');
  assert.equal(config.canvasKitForceCpuOnly, true);
});
