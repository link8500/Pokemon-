'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('web/app-loader.js','utf8').replaceAll('__POKEDEX_BUILD__','123456');
function boot(overrides = {}) {
  const scripts=[], styles=[], registrations=[];
  const document={documentElement:{setAttribute(){}},head:{appendChild:node=>styles.push(node)},
    body:{appendChild:node=>{if(node.tag==='script'){scripts.push(node.src);if(node.onload)node.onload();}}},
    createElement:tag=>({tag,style:{}})};
  const navigator=Object.assign({userAgent:'Desktop Chrome',hardwareConcurrency:8,deviceMemory:8,
    serviceWorker:{register:(url,options)=>{registrations.push([url,options]);return Promise.resolve();}}},overrides.navigator);
  const window={location:{search:overrides.query||''},WebAssembly:overrides.noWasm?undefined:{}};
  const localStorage={getItem:()=>overrides.preference,setItem(){}};
  vm.runInNewContext(source,{window,navigator,document,localStorage,encodeURIComponent});
  return {mode:window.POKEDEX_MODE,scripts,styles,registrations};
}
test('Mobile never loads the Flutter engine, including phones reporting few features',()=>{
  for(const ua of ['Android 5.1 SM-J120M Chrome/81','iPhone Safari','Android Chrome/130']){
    const result=boot({navigator:{userAgent:ua}});
    assert.equal(result.mode,'lite');
    assert.deepEqual(result.scripts,['lite/pokedex-core.js?v=123456','lite/pokedex.js?v=123456']);
  }
});
test('Save-data, weak hardware and missing WebAssembly choose lite automatically',()=>{
  for(const options of [{navigator:{connection:{saveData:true}}},{navigator:{deviceMemory:1}},
    {navigator:{hardwareConcurrency:2}},{noWasm:true}]) assert.equal(boot(options).mode,'lite');
});
test('Desktop retains Flutter and explicit view choices override auto-detection',()=>{
  assert.deepEqual(boot().scripts,['flutter_bootstrap.js?v=123456']);
  assert.equal(boot({query:'?view=full',navigator:{userAgent:'Android'}}).mode,'full');
  assert.equal(boot({query:'?view=lite'}).mode,'lite');
  assert.equal(boot({preference:'lite'}).mode,'lite');
  assert.equal(boot({preference:'full',query:'?view=lite'}).mode,'lite');
  assert.equal(boot().registrations[0][1].updateViaCache,'none');
});
