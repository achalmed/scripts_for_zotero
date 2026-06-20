# Organizador Automático de Series — Script para Zotero

Script de JavaScript para Zotero (v2.0) que **organiza automáticamente los
ítems de una colección en subcolecciones según su campo "Series"**. Por
ejemplo, si tienes 10 libros de la serie "Economía Asiática", el script
crea una subcolección llamada "Economía Asiática" dentro de tu colección
principal y mueve ahí esos 10 ítems.

## ¿Para qué sirve?

Si importas tu biblioteca desde Calibre (u otra fuente que mantiene el
campo "Series" en sus metadatos), terminas con cientos de ítems sueltos en
una sola colección. Este script los reorganiza automáticamente en
subcolecciones por serie, sin perder notas, anotaciones ni archivos
adjuntos (porque mueve el ítem padre completo, no toca sus hijos
individualmente).

## Requisitos

- Zotero 6 o superior (con la consola de Ejecutar JavaScript habilitada).
- No requiere plugins adicionales.
- Una colección existente cuyo nombre coincida con el configurado en
  `CONFIG.nombreColeccionPrincipal` (por defecto: `"Calibre"`).

## Instalación / Uso

1. Abre Zotero.
2. Ve a **Herramientas → Desarrollador → Ejecutar JavaScript**.
3. Pega el contenido completo de `series_organizer.js`.
4. **Antes de ejecutar**, revisa y ajusta la sección `CONFIG` al inicio del
   script (ver tabla de opciones más abajo).
5. Haz clic en **Run** (Ejecutar).
6. Revisa la consola de desarrollador para ver el detalle completo del
   proceso, fase por fase.

## Opciones de configuración (`CONFIG`)

| Opción | Valor por defecto | Descripción |
|---|---|---|
| `nombreColeccionPrincipal` | `"Calibre"` | Nombre exacto de la colección a procesar. Debe coincidir tal cual aparece en Zotero. |
| `modoSimulacion` | `false` | Si es `true`, el script solo **muestra** qué haría, sin modificar nada. Ideal para probar antes de aplicar cambios reales. |
| `modoVerboso` | `true` | Si es `true`, muestra el detalle de cada elemento procesado en la consola. |
| `prefijoSeries` | `""` | Texto que se antepone al nombre de cada subcolección creada (ej. `"Serie: "`). |
| `mantenerEnColeccionPrincipal` | `false` | Si es `true`, los ítems se **copian** a la subcolección pero permanecen también en la colección principal. Si es `false`, se **mueven** (se quitan de la principal). |
| `limitePrueba` | `0` | Límite de ítems a procesar por ejecución. `0` = sin límite. Útil para probar con pocos ítems primero (ej. `10`). |

## Flujo del script (4 fases)

1. **Recopilación de elementos**: obtiene todos los ítems "regulares"
   (no notas ni adjuntos sueltos) de la colección principal.
2. **Agrupación por series**: lee el campo `series` de cada ítem y los
   agrupa en un mapa en memoria por nombre de serie.
3. **Creación/actualización de subcolecciones**: por cada serie única,
   busca si ya existe una subcolección con ese nombre; si no existe, la
   crea. Luego mueve (o copia, según `mantenerEnColeccionPrincipal`) los
   ítems correspondientes.
4. **Verificación final**: cuenta cuántos elementos quedaron en cada
   subcolección y cuántos permanecen en la colección principal, para que
   puedas confirmar que el proceso se completó correctamente.

Al final se imprime un resumen con tiempo total de ejecución, número de
series procesadas, subcolecciones creadas/reutilizadas, elementos movidos,
elementos sin serie y errores encontrados.

## Precauciones

- ⚠️ El script modifica permanentemente la estructura de colecciones de tu
  biblioteca. **Haz una copia de seguridad antes de ejecutarlo.**
- Prueba primero con `modoSimulacion: true` para ver qué haría sin aplicar
  ningún cambio real.
- También puedes combinar `modoSimulacion: false` con `limitePrueba: 10`
  para aplicar cambios reales pero solo sobre un grupo pequeño de prueba.
- El proceso es reversible manualmente (puedes volver a mover los ítems a
  mano), pero puede tomar tiempo si la biblioteca es grande, así que es
  mejor confirmar el comportamiento antes de correrlo sobre todo.

## Solución de problemas

| Problema | Causa probable / Solución |
|---|---|
| `No se encontró la colección "Calibre"` | El nombre en `CONFIG.nombreColeccionPrincipal` no coincide exactamente con el de Zotero. El mensaje de error lista las colecciones disponibles para que copies el nombre correcto. |
| `No se encontraron elementos con series` | Ninguno de los ítems en la colección tiene el campo "Series" lleno. Verifica los metadatos de tus ítems. |
| Aparecen advertencias de "No se detectan elementos en la subcolección" | Puede deberse a una recarga de caché de Zotero; vuelve a revisar la subcolección manualmente en la interfaz. |
| El script va lento | Es normal con bibliotecas grandes, ya que cada movimiento de ítem usa su propia transacción. Considera usar `limitePrueba` para procesar por partes. |

## Autor

Edison Achalma — Diciembre 2025