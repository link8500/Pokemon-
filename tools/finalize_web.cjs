'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..', 'build', 'web');
const source = path.resolve(__dirname, '..', 'web');
const hash = crypto.createHash('sha256');
const required = ['main.dart.js', 'index.html', 'app-loader.js', 'pokedex-sw.js',
  'lite/pokedex-core.js', 'lite/pokedex.js', 'lite/pokedex.css',
  'lite/pikachu.webp', 'assets/assets/data/catalog.json'];
for (const file of required) {
  if (!fs.existsSync(path.join(root, file))) throw new Error('Falta en build/web: ' + file);
  // Normalize the stamp so re-running this finalizer is idempotent.
  const content = ['app-loader.js', 'pokedex-sw.js'].includes(file)
    ? fs.readFileSync(path.join(source, file))
    : file === 'index.html'
      ? fs.readFileSync(path.join(root, file), 'utf8').replace(/app-loader\.js\?v=[^"\s]+/, 'app-loader.js?v=__POKEDEX_BUILD__')
      : fs.readFileSync(path.join(root, file));
  hash.update(file).update(content);
}
for (let id = 1; id <= 1025; id++) hash.update(fs.readFileSync(path.join(root, 'lite/sprites', id + '.png')));
const build = hash.digest('hex').slice(0, 16);
for (const file of ['app-loader.js', 'pokedex-sw.js']) {
  fs.writeFileSync(path.join(root, file), fs.readFileSync(path.join(source, file), 'utf8').replaceAll('__POKEDEX_BUILD__', build));
}
const index = path.join(root, 'index.html');
fs.writeFileSync(index, fs.readFileSync(index, 'utf8').replace(/app-loader\.js\?v=[^"\s]+/, 'app-loader.js?v=' + build));
console.log('Pokédex lista para Netlify. Versión de caché: ' + build);
