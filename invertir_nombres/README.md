# Intercambio de Nombres y Apellidos — Script para Zotero

Script de JavaScript para Zotero que **intercambia los campos de nombre
(`firstName`) y apellido (`lastName`)** de todos los creadores (autores,
editores, traductores, etc.) en los ítems seleccionados.

```
Antes:    firstName: "García"   | lastName: "Juan"
Después:  firstName: "Juan"     | lastName: "García"
```

## ¿Para qué sirve?

Es muy común que al importar referencias desde catálogos, archivos RIS, o
metadatos de Calibre, los campos de nombre y apellido queden invertidos.
Este script corrige ese problema de forma masiva sobre los ítems que
selecciones.

## Requisitos

- Zotero 6 o superior (con la consola de Ejecutar JavaScript habilitada).
- No requiere plugins adicionales.

## Instalación / Uso

1. Abre Zotero.
2. Selecciona uno o más ítems cuyos autores tengan nombre/apellido
   invertidos.
3. Ve a **Herramientas → Desarrollador → Ejecutar JavaScript**.
4. Pega el contenido completo de `invertir_nombres.js`.
5. Haz clic en **Run** (Ejecutar).
6. Revisa el reporte de resultado (ítems procesados, modificados, creadores
   intercambiados y errores).

## Cómo funciona (resumen técnico)

1. Obtiene los ítems seleccionados en el panel de Zotero.
2. Filtra solo ítems "regulares" (omite notas independientes y adjuntos
   sueltos).
3. Por cada ítem, recorre su lista de creadores (`getCreators()`).
4. Para cada creador, **solo si tiene ambos campos** (`firstName` y
   `lastName`) completos, intercambia sus valores.
5. Los creadores con un solo campo (por ejemplo, nombres de instituciones
   registrados como "nombre único") se omiten para evitar daños.
6. Guarda los cambios del ítem con `item.saveTx()`.
7. Al final, genera un reporte con estadísticas completas.

## Precauciones

- ⚠️ El script modifica tus ítems de forma **permanente**.
- Se recomienda hacer una copia de seguridad de tu biblioteca antes de
  ejecutarlo sobre muchos ítems.
- Prueba primero con 1–2 ítems para confirmar que el intercambio es
  correcto en tu caso de uso.
- Si algo sale mal, puedes deshacer con `Ctrl+Z` (`Cmd+Z` en Mac)
  inmediatamente después, o restaurar desde una copia de seguridad.

## Variantes incluidas en el código (comentadas)

Al final del archivo encontrarás bloques de comentario con variantes
opcionales que puedes activar copiando el fragmento correspondiente dentro
del script:

1. **Solo procesar autores** (ignorar editores, traductores, etc.).
2. **Confirmación previa** con `window.confirm()` antes de guardar cambios.
3. **Detectar apellidos compuestos**: solo intercambiar si `firstName`
   tiene más de una palabra.
4. **Crear respaldo en consola** antes de modificar (útil para poder
   revisar manualmente qué había antes).

## Solución de problemas

| Problema | Solución |
|---|---|
| `"ZoteroPane is not defined"` | Asegúrate de ejecutar el script en Zotero Desktop, no en el navegador. |
| `"Cannot read property 'length' of null"` | Selecciona al menos un ítem antes de ejecutar el script. |
| Los cambios no se guardan | Verifica que tienes permisos de escritura en tu biblioteca. |
| Script muy lento con muchos ítems | Selecciona menos ítems por ejecución (lotes de 100–500). |
| Se intercambiaron nombres que no debían | Usa `Ctrl+Z` inmediatamente o restaura desde copia de seguridad. |

## Mejoras futuras sugeridas

- Opción de previsualización sin guardar.
- Detección inteligente automática de qué campo es nombre y cuál apellido.
- Soporte para sufijos (Jr., Sr., III, etc.).
- Interfaz gráfica con botones de confirmación.
- Exportar reporte de cambios a CSV.
- Opción de deshacer cambios desde el mismo script.

## Autor

Edison Achalma — 2024