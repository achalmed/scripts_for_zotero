# Capitalizar Tags — Script para Zotero

Script de JavaScript para Zotero que **capitaliza automáticamente los tags
(etiquetas)** de los ítems seleccionados: pone en mayúscula la primera letra
de cada palabra y el resto en minúscula.

```
ejemplo: "ciencia de datos" → "Ciencia De Datos"
```

## ¿Para qué sirve?

Si tu biblioteca de Zotero tiene tags escritos de forma inconsistente
(todo en minúscula, todo en mayúscula, mezclado, etc.), este script los
normaliza en un solo formato de "Título" para que se vean uniformes en el
panel de tags.

## Requisitos

- Zotero 6 o superior (con la consola de Ejecutar JavaScript habilitada).
- No requiere plugins adicionales.

## Instalación / Uso

1. Abre Zotero.
2. Selecciona en tu biblioteca uno o varios ítems cuyos tags quieras
   capitalizar.
3. Ve a **Herramientas → Desarrollador → Ejecutar JavaScript**
   (*Tools → Developer → Run JavaScript*).
4. Copia y pega el contenido completo de `capitalizar_tags.js`.
5. Haz clic en **Run** (Ejecutar).
6. Aparecerá un mensaje indicando cuántos ítems fueron actualizados.

## Cómo funciona (resumen técnico)

1. Obtiene los ítems seleccionados en el panel activo de Zotero.
2. Filtra solo los que tienen al menos un tag.
3. Procesa los ítems en **lotes de 100** (para no sobrecargar una sola
   transacción de base de datos).
4. Por cada tag, separa el texto por espacios, capitaliza la primera letra
   de cada palabra y vuelve a unirlas.
5. Si el tag cambió, elimina el original y agrega el nuevo conservando su
   **tipo** (manual o automático).
6. Guarda el ítem solo si hubo cambios reales, sin actualizar la fecha de
   "Modificado" (`skipDateModifiedUpdate: true`).

## Precauciones

- ⚠️ El script modifica tus ítems de forma **permanente**. Haz una copia de
  seguridad de tu biblioteca antes de ejecutarlo sobre una selección grande.
- Pruébalo primero con 1–2 ítems para confirmar que el resultado es el
  esperado en tu caso (por ejemplo, si usas tags con acrónimos como "BCRP"
  o "PBI", revisa que el resultado te siga pareciendo legible, ya que el
  script los convertirá a "Bcrp" o "Pbi").

## Limitaciones conocidas

- No distingue acrónimos ni nombres propios compuestos: capitaliza letra a
  letra por palabra, sin excepciones.
- Solo capitaliza, no traduce ni reordena tags (para eso usa
  `traducir_tags_español.js`).

## Personalización rápida

Si quieres excluir ciertos tags de la capitalización (por ejemplo, siglas),
puedes agregar una lista de excepciones antes del `.map()`:

```javascript
const EXCEPCIONES = ["BCRP", "PBI", "INEI"];

let tagCapitalizado = EXCEPCIONES.includes(tagOriginal)
    ? tagOriginal
    : tagOriginal.split(' ').map(p => p.charAt(0).toUpperCase() + p.slice(1).toLowerCase()).join(' ');
```

## Autor

Edison Achalma