'use strict';
// Comparable file sizes, not a claim about any particular carrier or server.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const root = path.resolve(__dirname, '..', 'build', 'web');
const files = ['index.html','app-loader.js','pokedex-sw.js','lite/pokedex-core.js',
  'lite/pokedex.js','lite/pokedex.css','assets/assets/data/catalog.json',
  'lite/pikachu.webp','favicon.svg','icons/pokedex-32-v2.png','manifest.json',
  ...Array.from({length:12},(_,index)=>'lite/sprites/'+(index+1)+'.png')];
const rows = files.map(file => {
  const bytes = fs.readFileSync(path.join(root,file));
  // Already compressed images are transferred as-is rather than recompressed.
  const compressed = /\.(png|webp)$/.test(file) ? bytes : zlib.gzipSync(bytes,{level:9});
  return {file,bytes:bytes.length,estimated_gzip_bytes:compressed.length};
});
const report = {note:'Unique first-visit lite files, including offline setup and 12 sprites. Gzip level 9 estimate; excludes HTTP headers and optional requests.',
  raw_bytes:rows.reduce((sum,row)=>sum+row.bytes,0),
  estimated_gzip_bytes:rows.reduce((sum,row)=>sum+row.estimated_gzip_bytes,0),files:rows};
if (process.argv[2]) fs.writeFileSync(process.argv[2],JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
