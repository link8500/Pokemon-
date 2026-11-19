'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('web/pokedex-sw.js','utf8').replaceAll('__POKEDEX_BUILD__','test-build');
function worker() {
  const listeners={}, stores=new Map(), calls=[];
  let online=true, failWrites=false, opaque=false;
  const key = request => typeof request==='string'?request:request.url;
  const cache = name => {
    if(!stores.has(name))stores.set(name,new Map());
    const data=stores.get(name);
    return {match:async request => data.get(key(request))?.clone(),
      put:async(request,response)=>{if(failWrites)throw Error('Quota');data.set(key(request),response.clone());},
      keys:async()=>Array.from(data.keys()),delete:async request=>data.delete(key(request))};
  };
  const caches={open:async name=>cache(name),keys:async()=>Array.from(stores.keys()),delete:async name=>stores.delete(name)};
  const self={location:{href:'https://example.test/pokedex-sw.js?v=test-build'},navigator:{onLine:true},
    clients:{claim:async()=>{}},skipWaiting:async()=>{},addEventListener:(name,handler)=>{listeners[name]=handler;}};
  const fetch=async request=>{
    calls.push(key(request));if(!online)throw Error('Offline');
    const response=new Response('network:'+key(request),{status:200});
    if(opaque)Object.defineProperty(response,'type',{value:'opaque'});
    return response;
  };
  vm.runInNewContext(source,{self,caches,fetch,Request,Response,URL,Promise,Array,Error,setTimeout,clearTimeout});
  return {calls,stores,setOnline:value=>{online=value;self.navigator.onLine=value;},setFailWrites:value=>{failWrites=value;},
    setOpaque:value=>{opaque=value;},
    lifecycle:async name=>{let pending;listeners[name]({waitUntil:promise=>{pending=promise;}});await pending;},
    request:async(url,mode='cors')=>{let result;listeners.fetch({request:{url,mode,method:'GET'},respondWith:promise=>{result=promise;}});return result;}};
}
test('Offline install preloads only the small shell and first 12 sprites, never Flutter or the full collection',async()=>{
  const app=worker();await app.lifecycle('install');
  assert.equal(app.calls.filter(url=>url.includes('/sprites/')).length,12);
  assert.ok(app.calls.length<30);
  assert.ok(!app.calls.some(url=>/main\.dart|canvaskit|pokeapi\.co/.test(url)));
  app.setOnline(false);
  assert.equal((await app.request('https://example.test/?view=lite','navigate')).status,200);
  assert.equal((await app.request('https://example.test/assets/assets/data/catalog.json?v=test-build')).status,200);
  assert.equal((await app.request('https://example.test/lite/sprites/1.png')).status,200);
});
test('Viewed sprites survive disconnection and runtime image cache is bounded',async()=>{
  const app=worker();await app.lifecycle('install');
  for(let id=13;id<=145;id++)await app.request('https://example.test/lite/sprites/'+id+'.png');
  assert.equal(app.stores.get('pokedex-images-test-build').size,128);
  app.setOnline(false);
  const count=app.calls.length;
  assert.equal((await app.request('https://example.test/lite/sprites/145.png')).status,200);
  assert.equal(app.calls.length,count);
});
test('Quota failures and opaque responses do not break requests or fill the cache',async()=>{
  const app=worker();await app.lifecycle('install');
  app.setFailWrites(true);
  assert.equal((await app.request('https://example.test/lite/sprites/132.png')).status,200);
  assert.equal(app.stores.get('pokedex-images-test-build').size,12);
  app.setFailWrites(false);app.setOpaque(true);
  await app.request('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/132.png');
  assert.equal(app.stores.get('pokedex-images-test-build').size,12);
});
test('An upgrade only deletes obsolete Pokédex caches',async()=>{
  const app=worker();app.stores.set('unrelated-app',new Map());app.stores.set('pokedex-shell-old',new Map());
  await app.lifecycle('install');await app.lifecycle('activate');
  assert.ok(app.stores.has('unrelated-app'));
  assert.ok(!app.stores.has('pokedex-shell-old'));
  assert.ok(app.stores.has('pokedex-shell-test-build'));
});
