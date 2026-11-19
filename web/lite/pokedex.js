(function () {
  'use strict';
  var core=window.PokedexCore;
  var release=window.POKEDEX_RELEASE;
  var all=[],timer=null,lastFocus=null,activePokemon=null,shiny=false;
  var storage;
  try { storage=window.localStorage; } catch(_) { storage=null; }
  var state={query:'',type:'',generation:0,sort:'number',onlyFavorites:false,favorites:core.readFavorites(storage),page:0};
  var pageSize=12;
  var descriptions={};
  try { descriptions=JSON.parse(storage.getItem('pokedex.descriptions.v1')||'{}')||{}; } catch(_) {}
  if(typeof descriptions!=='object'||Array.isArray(descriptions))descriptions={};

  function element(tag,className,text) {
    var value=document.createElement(tag);
    if(className) value.className=className;
    if(text!==undefined) value.textContent=text;
    return value;
  }
  function get(id) { return document.getElementById(id); }
  function numberLabel(id) { return '#'+(id<10?'00':id<100?'0':'')+id; }
  function fetchJson(url) {
    // XHR also gives older mobile browsers a reliable request timeout.
    return new Promise(function(resolve,reject){
      var request=new XMLHttpRequest();
      request.open('GET',url,true);
      request.timeout=18000;
      request.onload=function(){
        if(request.status!==200) return reject(new Error('HTTP '+request.status));
        try{resolve(JSON.parse(request.responseText));}catch(error){reject(error);}
      };
      request.onerror=request.ontimeout=function(){reject(new Error('Sin conexión'));};
      request.send();
    });
  }
  function sprite(id,isShiny) {
    return isShiny?'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/'+id+'.png':'lite/sprites/'+id+'.png';
  }
  function image(id,label,isShiny) {
    var img=element('img');
    img.width=96;img.height=96;img.alt=label;
    img.loading='lazy';img.decoding='async';
    if(isShiny) img.crossOrigin='anonymous';
    img.src=sprite(id,isShiny);
    img.onerror=function(){
      var fallback=element('span','ball');fallback.setAttribute('aria-label','Imagen no disponible');
      if(img.parentNode) img.parentNode.replaceChild(fallback,img);
    };
    return img;
  }
  function styleFor(p) { return core.types[p.types[0]]||core.types.normal; }
  function badge(type) {
    var style=core.types[type]||core.types.normal;
    var tag=element('span','badge');
    tag.style.color=style[1];tag.style.background=style[2];
    tag.appendChild(element('span','',style[3]));tag.appendChild(document.createTextNode(style[0]));
    return tag;
  }
  function badges(p) {
    var row=element('div','badges');
    p.types.forEach(function(type){row.appendChild(badge(type));});
    return row;
  }
  function favoriteButton(p,inModal) {
    var saved=state.favorites.indexOf(p.id)!==-1;
    var button=element('button','favorite'+(saved?' saved':''),saved?'♥':'♡');
    button.type='button';
    button.setAttribute('aria-label',(saved?'Quitar ':'Guardar ')+p.label+' '+(saved?'de':'en')+' favoritos');
    button.setAttribute('aria-pressed',String(saved));
    button.onclick=function(){
      var position=state.favorites.indexOf(p.id);
      if(position===-1) state.favorites.push(p.id); else state.favorites.splice(position,1);
      core.saveFavorites(storage,state.favorites);
      if(inModal) {
        var replacement=favoriteButton(p,true);
        button.parentNode.replaceChild(replacement,button);
      }
      render();
    };
    return button;
  }
  function card(p) {
    var style=styleFor(p), item=element('article','card'),open=element('button','card-open');
    open.type='button';open.setAttribute('aria-label','Ver ficha de '+p.label);
    var art=element('div','art');art.style.background=style[2];
    var number=element('span','number',numberLabel(p.id));number.style.color=style[1];
    art.appendChild(number);art.appendChild(image(p.id,p.label,false));
    var info=element('div','card-info');info.appendChild(element('h3','',p.label));info.appendChild(badges(p));
    open.appendChild(art);open.appendChild(info);open.onclick=function(){detail(p,open);};
    item.appendChild(open);item.appendChild(favoriteButton(p,false));
    return item;
  }

  var root=element('div','pokedex-lite');
  root.innerHTML='<header class="top"><div class="wrap"><button type="button" class="brand" id="home" aria-label="Inicio de Pokédex"><span class="ball" aria-hidden="true"></span><span>poké<b>dex</b></span></button><nav class="nav" aria-label="Navegación principal"><button type="button" id="explore" class="active">▦ Explorar</button><button type="button" id="favorites">♡ Favoritos <small id="fav-count"></small></button></nav></div></header>'+
    '<main class="wrap"><section class="hero" aria-label="Bienvenida"><div class="intro"><p class="eyebrow">EXPLORA. DESCUBRE. ATRÁPALOS TODOS.</p><h1>Un mundo Pokémon.<br><em>Infinitas aventuras.</em></h1><p class="muted">Encuentra a tus favoritos, descubre sus habilidades y conoce a tu próximo compañero.</p><div class="metrics"><div class="metric"><strong>1.025</strong><small>Pokémon</small></div><div class="metric"><strong>9</strong><small>generaciones</small></div><div class="metric"><strong>18</strong><small>tipos por explorar</small></div></div></div><aside class="feature"><small>UN CLÁSICO QUE ENAMORA</small><h2>¡Hola,<br>entrenador!</h2><p>Tu próxima aventura<br>empieza aquí.</p><button type="button" id="random">⤨ Sorpréndeme</button><img src="lite/pikachu.webp" width="192" height="192" alt="Pikachu"></aside></section>'+
    '<form id="search-form" class="search-box" role="search"><span class="search-symbol" aria-hidden="true">⌕</span><input id="search" type="search" inputmode="search" autocomplete="off" maxlength="50" aria-label="Buscar Pokémon por nombre o número" placeholder="Nombre o número de Pokémon…"><button type="button" id="clear" class="clear" aria-label="Limpiar búsqueda" hidden>×</button><button type="submit" class="primary">Buscar</button></form><p class="hint"><span>✦</span> También entendemos «dito» o «pikchu». Busca sin preocuparte por pequeñas faltas.</p>'+
    '<section aria-label="Filtros de Pokémon"><h2 class="type-title">UN TIPO PARA CADA AVENTURA</h2><div class="types" id="types" role="group" aria-label="Filtrar por tipo"></div></section>'+
    '<section id="catalog" aria-label="Catálogo de Pokémon"><div class="catalog-head"><div class="catalog-title"><h2 id="catalog-title">Descubre Pokémon</h2><span id="count" class="count">…</span></div><div class="selects"><select id="generation" aria-label="Filtrar por generación"></select><select id="sort" aria-label="Ordenar Pokémon"><option value="number">Número ↑</option><option value="number-desc">Número ↓</option><option value="name">Nombre A–Z</option><option value="name-desc">Nombre Z–A</option></select></div></div><div class="correction" id="correction" hidden><p id="correction-text"></p><button id="correct" type="button">Ver</button></div><div id="offline" class="offline-message" hidden>Sin conexión. Puedes buscar y consultar los datos guardados; las imágenes ya vistas siguen disponibles.</div><div class="grid" id="grid" aria-live="polite" aria-busy="true"></div><div class="pagination" id="pagination" hidden><span id="range"></span><div class="page-buttons"><button type="button" id="previous" aria-label="Página anterior">←</button><span id="page-label"></span><button type="button" id="next" aria-label="Página siguiente">→</button></div></div></section>'+
    '<footer class="footer"><span>Hecho con curiosidad. Datos de PokéAPI.</span><span class="status" id="status">Ahorro de datos activado</span><a id="full-view" href="?view=full">Versión completa</a><span>Pokémon pertenece a Nintendo, Game Freak y Creatures.</span></footer></main>'+
    '<div class="overlay" id="overlay" hidden><section class="modal" id="modal" role="dialog" aria-modal="true" aria-labelledby="detail-name" tabindex="-1"></section></div>';
  document.body.appendChild(root);

  function removeLoading(){var loading=get('loading');if(loading&&loading.parentNode)loading.parentNode.removeChild(loading);}
  function networkStatus(){get('offline').hidden=navigator.onLine!==false;}
  function reset(){
    state.query='';state.type='';state.generation=0;state.sort='number';state.page=0;
    get('search').value='';get('generation').value='0';get('sort').value='number';render();
  }
  function runSearch(){clearTimeout(timer);state.query=get('search').value;state.page=0;render();}
  get('search').addEventListener('input',function(){clearTimeout(timer);timer=setTimeout(runSearch,260);});
  get('search-form').onsubmit=function(event){event.preventDefault();runSearch();get('search').blur();};
  get('clear').onclick=function(){get('search').value='';runSearch();get('search').focus();};
  get('home').onclick=function(){state.onlyFavorites=false;reset();window.scrollTo(0,0);};
  get('explore').onclick=function(){state.onlyFavorites=false;state.page=0;render();};
  get('favorites').onclick=function(){state.onlyFavorites=true;state.page=0;render();};
  get('generation').onchange=function(){state.generation=Number(this.value);state.page=0;render();};
  get('sort').onchange=function(){state.sort=this.value;state.page=0;render();};
  get('random').onclick=function(){if(all.length)detail(all[Math.floor(Math.random()*all.length)],this);};
  get('full-view').onclick=function(){try{storage.setItem('pokedex.view','full');}catch(_){}};
  get('previous').onclick=function(){state.page--;render();get('catalog').scrollIntoView();};
  get('next').onclick=function(){state.page++;render();get('catalog').scrollIntoView();};
  core.regions.forEach(function(label,index){var option=element('option','',label);option.value=index;get('generation').appendChild(option);});

  function typeButton(type){
    var style=core.types[type],button=element('button','type-button',(style?style[3]+' '+style[0]:'▦ Todos'));
    button.type='button';button.setAttribute('data-type',type);button.setAttribute('aria-pressed','false');
    button.onclick=function(){state.type=type;state.page=0;render();};
    return button;
  }
  get('types').appendChild(typeButton(''));
  Object.keys(core.types).forEach(function(type){get('types').appendChild(typeButton(type));});

  function render(){
    var result=core.search(state.query,all),entries=core.filter(result,state),pages=Math.ceil(entries.length/pageSize);
    state.page=Math.max(0,Math.min(state.page,Math.max(0,pages-1)));
    get('catalog-title').textContent=state.onlyFavorites?'Tus favoritos':'Descubre Pokémon';
    get('count').textContent=entries.length;
    get('fav-count').textContent=state.favorites.length?String(state.favorites.length):'';
    get('explore').className=state.onlyFavorites?'':'active';get('favorites').className=state.onlyFavorites?'active':'';
    get('explore').setAttribute('aria-pressed',String(!state.onlyFavorites));get('favorites').setAttribute('aria-pressed',String(state.onlyFavorites));
    get('clear').hidden=!get('search').value;
    var typeButtons=get('types').children;
    for(var t=0;t<typeButtons.length;t++){
      var selected=typeButtons[t].getAttribute('data-type')===state.type;
      typeButtons[t].className='type-button'+(selected?' active':'');
      typeButtons[t].setAttribute('aria-pressed',String(selected));
    }
    get('correction').hidden=!result.correction;
    if(result.correction){
      get('correction-text').textContent='¿Buscabas '+result.correction+'? Estas son las coincidencias más cercanas.';
      get('correct').onclick=function(){get('search').value=result.correction;runSearch();};
    }
    var grid=get('grid'),fragment=document.createDocumentFragment();
    while(grid.firstChild)grid.removeChild(grid.firstChild);
    if(!entries.length){
      var empty=element('div','empty');
      var emptyFavorites=state.onlyFavorites&&!state.favorites.length;
      empty.appendChild(element('h3','',emptyFavorites?'Tu equipo empieza aquí':'No encontramos coincidencias'));
      empty.appendChild(element('p','',emptyFavorites?'Toca el corazón de un Pokémon para guardarlo aquí.':'Prueba otro nombre o número, o limpia los filtros para ampliar la búsqueda.'));
      var button=element('button','primary',emptyFavorites?'Explorar Pokémon':'Limpiar filtros');button.type='button';
      button.onclick=function(){if(emptyFavorites)state.onlyFavorites=false;reset();};empty.appendChild(button);fragment.appendChild(empty);
    } else {
      entries.slice(state.page*pageSize,(state.page+1)*pageSize).forEach(function(p){fragment.appendChild(card(p));});
    }
    grid.appendChild(fragment);grid.setAttribute('aria-busy','false');
    get('pagination').hidden=pages<=1;
    get('page-label').textContent=(state.page+1)+' / '+Math.max(1,pages);
    get('previous').disabled=state.page===0;get('next').disabled=state.page+1>=pages;
    get('range').textContent='Mostrando '+(state.page*pageSize+1)+'–'+Math.min((state.page+1)*pageSize,entries.length)+' de '+entries.length+' Pokémon';
    networkStatus();
  }

  function closeDetail(){
    get('overlay').hidden=true;document.body.classList.remove('no-scroll');activePokemon=null;
    if(lastFocus&&document.body.contains(lastFocus))lastFocus.focus();else get('search').focus();
  }
  get('overlay').addEventListener('click',function(event){if(event.target===this)closeDetail();});
  document.addEventListener('keydown',function(event){
    if(get('overlay').hidden)return;
    if(event.key==='Escape')return closeDetail();
    if(event.key==='Tab'){
      var focusable=get('modal').querySelectorAll('button:not([disabled]),a[href],input,select,[tabindex="0"]');
      if(!focusable.length)return;
      var first=focusable[0],last=focusable[focusable.length-1];
      if(event.shiftKey&&document.activeElement===first){event.preventDefault();last.focus();}
      else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first.focus();}
    }
  });

  function description(p,container){
    while(container.firstChild)container.removeChild(container.firstChild);
    if(descriptions[p.id]){container.textContent=descriptions[p.id];return;}
    var button=element('button','retry','Cargar descripción');button.type='button';
    container.appendChild(button);container.appendChild(element('span','',' · Se descarga solo al solicitarla.'));
    button.onclick=function(){
      if(navigator.onLine===false){container.lastChild.textContent=' · Conéctate para cargarla por primera vez.';return;}
      button.disabled=true;button.textContent='Cargando…';
      fetchJson('https://pokeapi.co/api/v2/pokemon-species/'+p.species+'/').then(function(data){
        var spanish=(data.flavor_text_entries||[]).filter(function(entry){return entry.language.name==='es';});
        var text=spanish.length?spanish[spanish.length-1].flavor_text.replace(/[\n\r\f]+/g,' '):'Todavía no hay una descripción en español para este Pokémon.';
        descriptions[p.id]=text;
        var keys=Object.keys(descriptions);while(keys.length>40){delete descriptions[keys.shift()];}
        try{storage.setItem('pokedex.descriptions.v1',JSON.stringify(descriptions));}catch(_){}
        if(activePokemon&&activePokemon.id===p.id)container.textContent=text;
      }).catch(function(){button.disabled=false;button.textContent='Reintentar descripción';});
    };
  }

  function detail(p,opener){
    lastFocus=opener||document.activeElement;activePokemon=p;shiny=false;
    var modal=get('modal');while(modal.firstChild)modal.removeChild(modal.firstChild);
    var style=styleFor(p),art=element('div','detail-art');art.style.background=style[2];
    var number=element('span','number',numberLabel(p.id));number.style.color=style[1];art.appendChild(number);
    var artwork=image(p.id,p.label,false);art.appendChild(artwork);
    var close=element('button','close-modal','×');close.type='button';close.setAttribute('aria-label','Cerrar ficha');close.onclick=closeDetail;art.appendChild(close);
    var shinyButton=element('button','shiny','✦ Ver variocolor');shinyButton.type='button';
    shinyButton.onclick=function(){
      shiny=!shiny;var next=image(p.id,p.label+(shiny?' variocolor':''),shiny);
      if(artwork.parentNode)artwork.parentNode.replaceChild(next,artwork);else art.insertBefore(next,close);
      artwork=next;shinyButton.textContent=shiny?'Ver original':'✦ Ver variocolor';
    };art.appendChild(shinyButton);modal.appendChild(art);
    var content=element('div','detail-content'),title=element('div','detail-title'),name=element('h2','',p.label);name.id='detail-name';
    title.appendChild(name);title.appendChild(favoriteButton(p,true));content.appendChild(title);content.appendChild(badges(p));
    var desc=element('p','description');description(p,desc);content.appendChild(desc);
    var measures=element('div','measurements');
    [[p.height.toFixed(1)+' m','Altura'],[p.weight.toFixed(1)+' kg','Peso'],['Gen. '+p.generation,'Generación']].forEach(function(pair){var item=element('div');item.appendChild(element('strong','',pair[0]));item.appendChild(element('small','',pair[1]));measures.appendChild(item);});content.appendChild(measures);
    content.appendChild(element('h3','','Estadísticas base'));
    ['PS','Ataque','Defensa','Ataque esp.','Defensa esp.','Velocidad'].forEach(function(label,index){
      var row=element('div','stat');row.appendChild(element('span','stat-name',label));row.appendChild(element('span','stat-value',p.stats[index]));
      var bar=element('span','bar'),fill=element('i');fill.style.width=Math.min(100,p.stats[index]/255*100)+'%';fill.style.background=style[1];bar.appendChild(fill);row.appendChild(bar);content.appendChild(row);
    });
    content.appendChild(element('h3','','Habilidades'));
    p.abilities.forEach(function(ability){content.appendChild(element('span','ability',core.pretty(ability)));});
    content.appendChild(element('p','detail-note','Datos de PokéAPI · El catálogo funciona sin descargar fichas completas.'));
    modal.appendChild(content);get('overlay').hidden=false;document.body.classList.add('no-scroll');close.focus();
  }

  window.addEventListener('offline',networkStatus);window.addEventListener('online',networkStatus);
  fetchJson('assets/assets/data/catalog.json?v='+encodeURIComponent(release)).then(function(data){
    if(data.version!==1||!Array.isArray(data.rows)||!data.rows.length)throw new Error('Catálogo inválido');
    all=core.index(data.rows);
    removeLoading();render();
  }).catch(function(){
    removeLoading();get('grid').setAttribute('aria-busy','false');
    var box=element('div','empty');box.appendChild(element('h3','','No pudimos cargar el catálogo'));
    box.appendChild(element('p','','Para abrirlo por primera vez necesitas conexión. Después podrás consultar los datos guardados.'));
    var retry=element('button','primary','Reintentar');retry.type='button';retry.onclick=function(){window.location.reload();};box.appendChild(retry);get('grid').appendChild(box);
  });
})();
