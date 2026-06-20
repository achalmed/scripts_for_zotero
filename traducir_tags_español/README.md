# Traducir Tags al Español — Script para Zotero

Script de JavaScript para Zotero que **traduce automáticamente los tags
(etiquetas) en inglés al español**, usando un diccionario interno
ampliable. Si el ítem ya tiene el tag equivalente en español, simplemente
elimina el duplicado en inglés.

```
ejemplo: "economics" → "economía"
ejemplo: "data analysis" (no está en el diccionario) → se deja igual y se reporta
```

## ¿Para qué sirve?

Útil cuando importas referencias de bases de datos académicas en inglés
(Scopus, JSTOR, Google Scholar, etc.) pero organizas tu biblioteca en
español. El script normaliza el idioma de tus tags sin que tengas que
revisarlos uno por uno.

## Requisitos

- Zotero 6 o superior (con la consola de Ejecutar JavaScript habilitada).
- No requiere plugins adicionales.

## Instalación / Uso

1. Abre Zotero.
2. Selecciona uno o más ítems cuyos tags quieras traducir.
3. Ve a **Herramientas → Desarrollador → Ejecutar JavaScript**.
4. Pega el contenido completo de `traducir_tags_español.js`.
5. Haz clic en **Run** (Ejecutar).
6. El mensaje de resultado indica cuántos ítems se actualizaron y, si
   hubo tags sin traducir, en qué archivo se guardó la lista.

## Cómo funciona (resumen técnico)

1. Obtiene los ítems seleccionados y filtra solo los que tienen tags.
2. Procesa los ítems en **lotes de 100**.
3. Por cada ítem:
   - Identifica qué tags ya están en español (presentes como valor en el
     diccionario) para no duplicarlos.
   - Por cada tag en inglés que coincide con una clave del diccionario,
     lo reemplaza por su traducción, conservando el **tipo de tag**
     (manual o automático).
   - Si la traducción ya existe en el ítem, simplemente borra el tag en
     inglés duplicado.
   - Los tags que no están en el diccionario **no se tocan**, pero se
     registran para reportarlos al final.
4. Si hubo tags sin traducir, los guarda en un archivo de texto:
   `untranslated_tags.txt`, dentro de la carpeta de perfil de Zotero
   (`Zotero.getProfileDirectory()`).

## Precauciones

- ⚠️ El script modifica tus ítems de forma **permanente**.
- Haz una copia de seguridad de tu biblioteca antes de ejecutarlo sobre
  una selección grande.
- Los tags no traducidos no se eliminan ni alteran: simplemente se
  reportan en el archivo `untranslated_tags.txt` para que decidas qué
  hacer con ellos (por ejemplo, agregarlos al diccionario y volver a
  correr el script).

## Cómo ampliar el diccionario

Agrega nuevas entradas dentro de `DICCIONARIO_TRADUCCION`, con el formato:

```javascript
"termino en ingles": "término en español",
```

La comparación se hace siempre en minúsculas, así que no necesitas
duplicar variantes con mayúsculas/minúsculas distintas (por ejemplo, no
hace falta tener `"Economics"` y `"economics"` por separado).

## Revisar tags pendientes de traducción

Después de ejecutar el script, abre el archivo indicado en el mensaje de
resultado (`untranslated_tags.txt`) para ver qué términos no estaban en el
diccionario. Puedes:

1. Agregarlos al diccionario manualmente y volver a correr el script.
2. Dejarlos como están si prefieres mantenerlos en inglés (por ejemplo,
   nombres propios o términos técnicos sin traducción directa).

## Autor

Edison Achalma