# Rendimiento y publicación

Los móviles abren automáticamente una Pokédex ligera con HTML, CSS y JavaScript,
sin descargar ni ejecutar Flutter, CanvasKit, fuentes externas o WebGL. También
se activa con ahorro de datos, hasta 2 GB de memoria declarada, hasta 4 hilos
de CPU o sin WebAssembly. Una elección manual tiene prioridad: `?view=lite`
o `?view=full`. Ambas vistas tienen un enlace para cambiar de versión.

La versión ligera mantiene búsqueda tolerante a errores, números, filtros,
generaciones, orden, paginación, favoritos, habilidades y estadísticas.
Los favoritos son compartidos con Flutter en el mismo navegador.

## Consumo medido

| Archivos de arranque | Bytes originales | Estimación con gzip |
| --- | ---: | ---: |
| Flutter anterior: HTML, cargador, aplicación, CanvasKit y fuente | 10.101.526 | 3.770.661 |
| Versión ligera, catálogo completo, primera página y preparación sin conexión | 162.805 | 66.795 |

Reducción estimada del **98,2 %** en el presupuesto comprimido. La referencia
anterior ni siquiera incluye las fichas de API e ilustraciones de sus tarjetas.
La comparación usa gzip nivel 9 y conserva PNG/WebP sin recomprimir; excluye
cabeceras HTTP, iconos adicionales que pueda solicitar el navegador y consultas
opcionales. No es una medición de la red móvil ni de la compresión de Netlify.
La referencia usa CanvasKit genérico; algunos navegadores eligen su variante Chromium.
Se puede repetir el cálculo con `node tools/measure_web.cjs`.

El catálogo de 1.025 Pokémon ocupa 95.969 bytes sin comprimir y procede de los
[datos oficiales de PokéAPI](https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv).
Buscar, filtrar y abrir estadísticas no descarga fichas completas. Flutter
también utiliza este catálogo y miniaturas pequeñas para sus tarjetas.
En la vista ligera, descripción y variocolor se descargan al pulsar sus botones.

## Caché y límites

Después de completar la primera visita, el service worker guarda la interfaz,
el catálogo y las 12 imágenes iniciales. Guarda otras imágenes a medida que
se consultan: máximo 128, y hasta 20 respuestas de descripciones. El texto de
hasta 40 descripciones se conserva localmente. Una imagen no guardada necesita
conexión; el navegador puede desalojar la caché si falta espacio.

No hay animaciones permanentes, fuentes descargadas ni sondeos periódicos en
la vista ligera. La interfaz solo mantiene 12 tarjetas. Una visita en línea
puede comprobar actualizaciones; consultar contenido nuevo requiere datos.
Sin conexión se puede buscar y abrir los datos guardados sin nuevas descargas.

No se ha medido temperatura, batería o rendimiento en un Galaxy J1 físico.
El resultado depende del dispositivo y de un navegador compatible. El modo
sin conexión necesita HTTPS (Netlify lo ofrece), o localhost durante pruebas,
y un navegador que admita service workers. El navegador original de algunos
Android antiguos puede carecer de funciones necesarias.

## Exportar para Netlify

Desde la carpeta del proyecto:

```sh
node tools/export_web.cjs
```

El comando compila Flutter en release y asigna una versión a la caché a partir
de los archivos finales. Requiere Flutter y Node en PATH. Sube **todo el contenido
de `build/web`** al mismo sitio de Netlify, incluyendo `lite`, `assets`,
`pokedex-sw.js` y `_headers`. Si usas ZIP, `index.html` debe quedar en su raíz.

Para automatizar un despliegue con compilación, usa el mismo comando y publica
`build/web` en un entorno que tenga Flutter y Node instalados. Un `flutter build
web` aislado deja la página funcionando en línea, pero no prepara la caché
versionada de esta exportación.

El catálogo es una instantánea, no una descarga completa en cada visita.
`tools/build_catalog.py --refresh` actualiza sus tablas de origen y necesita
Python con Pillow; después hay que volver a exportar. Las imágenes existentes
se reutilizan. El README original de Flutter se conserva.

## Comprobaciones realizadas

- 23 pruebas Flutter: catálogo sin HTTP, unidades, caché de descripciones,
  búsqueda, filtros, favoritos, tamaños de pantalla y regreso desde segundo plano.
- 15 pruebas JavaScript: selección automática, correcciones, catálogo completo,
  compatibilidad de favoritos, caché acotada, fallos de almacenamiento y limpieza
  de versiones anteriores.
- `flutter analyze` sin incidencias.
- Navegador: diseños de 320 y 390 píxeles, búsqueda `dito`, filtros combinados,
  paginación, favoritos persistentes, descripción y variocolor opcionales.
- Recarga con el servidor local apagado: búsqueda y ficha de Ditto con su imagen
  y descripción guardadas; Flutter también abrió el catálogo y corrigió `dito`.
