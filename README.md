# Zotero Power Tools – Scripts en JavaScript (Run JavaScript)

![Zotero](https://img.shields.io/badge/Zotero-6%2B%20&%207-blue) ![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-yellow) ![license](https://img.shields.io/github/license/tu-usuario/zotero-power-tools)

**Cuatro scripts ultraútiles** para limpiar, normalizar y organizar automáticamente tu biblioteca de Zotero.  
Ejecútalos desde **Herramientas → Desarrollador → Ejecutar JavaScript** (Run JavaScript).

| # | Nombre del script | ¿Qué hace? | Ideal para… |
|---|-------------------|------------|-------------|
| 1 | `capitalize-tags.js` | Convierte todas las etiquetas seleccionadas a **Título Capitalizado** (Primera Letra Mayúscula) | Tener etiquetas perfectamente formateadas en segundos |
| 2 | `translate-tags-to-spanish.js` | Traduce automáticamente cientos de etiquetas del inglés al español (diccionario ampliable). Guarda en un .txt las que no pudo traducir | Bibliotecas bilingües o importadas desde fuentes en inglés |
| 3 | `swap-first-last-name.js` | Intercambia nombre ↔ apellido en todos los autores/editores de los ítems seleccionados | Cuando Zotero o un importador (RIS, BibTeX, etc.) invirtió los campos |
| 4 | `organize-by-series.js` | Crea subcolecciones automáticas dentro de una colección (ej: “Calibre”) usando el campo **Series** y mueve los libros a su sitio correspondiente | Organizar colecciones enormes de sagas, cursos, editoriales, etc. |

## Cómo usarlos (todos funcionan igual)

1. Abre Zotero  
2. Selecciona los ítems que quieras procesar (o nada si el script no lo requiere)  
3. Ve a **Herramientas → Desarrollador → Ejecutar JavaScript**  
4. Pega el contenido completo del script que necesites  
5. Haz clic en **Run**  
6. ¡Listo! El resultado aparece en la ventana y en la consola

> **Consejo:** Antes de ejecutar masivamente, prueba siempre con 5–10 ítems y haz una copia de seguridad de tu biblioteca (Archivo → Exportar biblioteca → Zotero RDF con archivos).

## Detalle de cada script

### 1. capitalize-tags.js – Etiquetas en Título Capitalizado
```js
// Ejemplo: "machine learning" → "Machine Learning"
//         "DATA analysis"    → "Data Analysis"
```
- Procesa en lotes de 100 ítems (muy rápido incluso con miles)
- No toca la fecha de modificación
- Solo modifica etiquetas que realmente cambian

### 2. translate-tags-to-spanish.js – Traductor automático de etiquetas
- Diccionario con más de 70 términos comunes (fácil de ampliar)
- Evita duplicados (si ya existe la versión en español, elimina la inglesa)
- Guarda automáticamente un archivo `untranslated_tags.txt` en tu perfil de Zotero con las etiquetas que no encontró (para que las añadas al diccionario)

### 3. swap-first-last-name.js – Intercambio masivo de nombres y apellidos
```js
// Antes:  firstName: "García Márquez" | lastName: "Gabriel"
// Después: firstName: "Gabriel"       | lastName: "García Márquez"
```
- Mensaje final súper detallado con estadísticas
- Ignora autores que solo tienen un campo
- 100 % transaccional y con logs claros

### 4. organize-by-series.js – Organizador automático por Series (v2.0 corregida)
- Crea subcolecciones dentro de “Calibre” (o la colección que indiques)
- Mueve los libros a su serie correspondiente
- Modo simulación (`modoSimulacion: true`) para ver qué haría sin tocar nada
- Opción de mantener los ítems también en la colección padre
- Logs extremadamente detallados y verificación final

```js
// Cambia estas líneas al inicio del script:
nombreColeccionPrincipal: "Calibre",   // ← tu colección
modoSimulacion: false,                // ← false para aplicar cambios
mantenerEnColeccionPrincipal: false   // ← true si quieres duplicados
```

## Licencia

**MIT License** – úsalos, modifícalos y compártelos libremente.

## Autor

Edison Achalma – 2024-2025  
Hecho con mucho cariño para la comunidad hispanohablante de Zotero

---

**¡Dale una estrella si estos scripts te ahorran horas de trabajo manual!**