'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const core = require('../web/lite/pokedex-core.js');
const catalog = JSON.parse(fs.readFileSync('assets/data/catalog.json', 'utf8'));
const all = core.index(catalog.rows);
test('The official compact catalog has complete, correctly scaled records and sprites', () => {
  assert.equal(all.length, 1025);
  all.forEach((p, index) => {
    assert.equal(p.id, index + 1);
    assert.equal(p.stats.length, 6);
    assert.ok(p.stats.every(stat => Number.isInteger(stat) && stat > 0));
    assert.ok(p.types.length && p.types.every(type => core.types[type]));
    assert.ok(p.abilities.length);
    assert.ok(fs.statSync('web/lite/sprites/' + p.id + '.png').size > 0);
  });
  const ditto = all[131];
  assert.equal(ditto.height, 0.3);
  assert.equal(ditto.weight, 4);
  assert.deepEqual(ditto.stats, [48, 48, 48, 48, 48, 48]);
});
test('Typos, transpositions, numbers and accented names find the intended Pokémon', () => {
  for (const [query, id] of [['dito',132],['pikchu',25],['bulbasar',1],['pikaHcu',25],['#0132',132],['Nidorán♀',29],['Mr. Mime',122]]) {
    assert.equal(core.search(query, all).entries[0].id, id, query);
  }
  assert.equal(core.search('dito', all).correction, 'Ditto');
  assert.equal(core.search('ditto', all).correction, null);
  assert.equal(core.search('zzzzzzzzzzzzzzzz', all).entries.length, 0);
  assert.equal(core.search('1320', all).entries.length, 0);
});
test('Filters, favorites and descending order compose without network data', () => {
  const result = core.search('', all);
  const filtered = core.filter(result, {type:'electric', generation:1, onlyFavorites:true, favorites:[25,81,172],sort:'number-desc'});
  assert.deepEqual(filtered.map(p => p.id), [81,25]);
  assert.equal(core.filter(result, {favorites:[],generation:9,sort:'number'}).length, 120);
});
test('Favorites keep Flutter storage compatibility and survive unavailable storage', () => {
  const values = {};
  const storage = {getItem:key => values[key],setItem:(key,value) => {values[key] = value;}};
  assert.equal(core.saveFavorites(storage,[25,132]), true);
  assert.equal(values['flutter.pokedex.favorites'], '["25","132"]');
  assert.deepEqual(core.readFavorites(storage),[25,132]);
  values['flutter.pokedex.favorites']='["25",25,"oops",0,9999,1.5]';
  assert.deepEqual(core.readFavorites(storage),[25]);
  assert.deepEqual(core.readFavorites(null),[]);
  assert.equal(core.saveFavorites(null,[25]),false);
});
