(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.PokedexCore = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  var types = {
    grass:['Planta','#438e65','#e7f4ea','♣'], fire:['Fuego','#c76d39','#ffede4','♨'],
    water:['Agua','#4f87c8','#e7f1fc','●'], electric:['Eléctrico','#a78015','#fff6d9','ϟ'],
    psychic:['Psíquico','#c75c89','#fcebf2','✦'], ghost:['Fantasma','#8273b3','#efecf8','☾'],
    normal:['Normal','#777b87','#eeeff2','○'], poison:['Veneno','#9b65b0','#f2e9f7','◆'],
    bug:['Bicho','#7a8b35','#f0f4e3','❋'], flying:['Volador','#767fb8','#eeeffb','≋'],
    ground:['Tierra','#9a763e','#f6eedd','▲'], fairy:['Hada','#b56b9d','#fbeaf5','★'],
    fighting:['Lucha','#b7615c','#f7e8e6','✊'], rock:['Roca','#8f7d40','#f2eedf','⬟'],
    steel:['Acero','#607e8c','#e8f0f3','⬡'], ice:['Hielo','#3d8795','#e5f6f7','❄'],
    dragon:['Dragón','#6f6db9','#ecebfa','✧'], dark:['Siniestro','#6c6578','#edebf0','◐']
  };
  var ends = [151,251,386,493,649,721,809,905,1025];
  var regions = ['Todas las generaciones','Kanto · Gen. I','Johto · Gen. II','Hoenn · Gen. III',
    'Sinnoh · Gen. IV','Teselia · Gen. V','Kalos · Gen. VI','Alola · Gen. VII','Galar · Gen. VIII','Paldea · Gen. IX'];
  function normalize(value) {
    var accents = {'á':'a','é':'e','í':'i','ó':'o','ú':'u','ü':'u','ñ':'n','♀':'f','♂':'m'};
    return String(value).toLowerCase().replace(/[áéíóúüñ♀♂]/g, function (c) { return accents[c]; }).replace(/[^a-z0-9]/g, '');
  }
  function pretty(value) {
    return value.split('-').map(function (word) { return word.charAt(0).toUpperCase() + word.slice(1); }).join(' ');
  }
  function generation(id) {
    for (var i=0; i<ends.length; i++) if (id<=ends[i]) return i+1;
    return 0;
  }
  function index(rows) {
    return rows.map(function (row) {
      return {id:row[0],name:row[1],normalized:normalize(row[1]),label:pretty(row[1]),types:row[2],
        height:row[3]/10,weight:row[4]/10,stats:row[5],abilities:row[6],species:row[7],generation:generation(row[0])};
    });
  }
  function distance(a,b) {
    var rows=[],i,j,cost;
    for (i=0;i<=a.length;i++) { rows[i]=[i]; for(j=1;j<=b.length;j++) rows[i][j]=i===0?j:0; }
    for(i=1;i<=a.length;i++) for(j=1;j<=b.length;j++) {
      cost=a[i-1]===b[j-1]?0:1;
      rows[i][j]=Math.min(rows[i-1][j]+1,rows[i][j-1]+1,rows[i-1][j-1]+cost);
      if(i>1&&j>1&&a[i-1]===b[j-2]&&a[i-2]===b[j-1]) rows[i][j]=Math.min(rows[i][j],rows[i-2][j-2]+1);
    }
    return rows[a.length][b.length];
  }
  function search(query,all) {
    var term=normalize(query), exact,partial,scored=[],limit;
    if(!term) return {entries:all.slice(),correction:null};
    if(/^\d+$/.test(term)) return {entries:all.filter(function(p){return p.id===Number(term);}),correction:null};
    exact=all.filter(function(p){return p.normalized===term;});
    if(exact.length) return {entries:exact,correction:null};
    partial=all.filter(function(p){return p.normalized.indexOf(term)!==-1;});
    if(partial.length) return {entries:partial,correction:null};
    if(term.length<3) return {entries:[],correction:null};
    limit=term.length<=4?1:term.length<=8?2:3;
    all.forEach(function(p){
      if(Math.abs(p.normalized.length-term.length)>limit) return;
      var d=distance(term,p.normalized), similarity=1-d/Math.max(term.length,p.normalized.length);
      if(d<=limit&&similarity>=0.55) scored.push({p:p,d:d,s:similarity});
    });
    scored.sort(function(a,b){return a.d-b.d||b.s-a.s||a.p.id-b.p.id;});
    return {entries:scored.slice(0,8).map(function(item){return item.p;}),correction:scored.length?scored[0].p.label:null};
  }
  function filter(result,state) {
    var entries=result.entries.filter(function(p){
      return (!state.type||p.types.indexOf(state.type)!==-1)&&(!state.generation||p.generation===state.generation)&&
        (!state.onlyFavorites||state.favorites.indexOf(p.id)!==-1);
    });
    if(!result.correction||state.sort!=='number') entries.sort(function(a,b){
      if(state.sort==='name') return a.name.localeCompare(b.name);
      if(state.sort==='name-desc') return b.name.localeCompare(a.name);
      return state.sort==='number-desc'?b.id-a.id:a.id-b.id;
    });
    return entries;
  }
  function readFavorites(storage) {
    try {
      var value=JSON.parse(storage.getItem('flutter.pokedex.favorites')||'[]');
      if(!Array.isArray(value)) return [];
      return value.map(Number).filter(function(id,i,list){return id>=1&&id<=1025&&Math.floor(id)===id&&list.indexOf(id)===i;});
    } catch(_) { return []; }
  }
  function saveFavorites(storage,ids) {
    try { storage.setItem('flutter.pokedex.favorites',JSON.stringify(ids.map(String))); return true; }
    catch(_) { return false; }
  }
  return {types:types,regions:regions,normalize:normalize,pretty:pretty,index:index,search:search,filter:filter,
    generation:generation,readFavorites:readFavorites,saveFavorites:saveFavorites};
});
