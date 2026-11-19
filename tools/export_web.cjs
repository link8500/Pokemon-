'use strict';
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const result = spawnSync('flutter build web --release --base-href / --no-wasm-dry-run', {
  cwd: path.resolve(__dirname, '..'), shell: true, stdio: 'inherit'
});
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status || 1);
require('./finalize_web.cjs');
