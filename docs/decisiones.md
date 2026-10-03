---
tipo: decision
titulo: "Decisiones del repo retirado y lo pendiente"
estado: activo
---
# Decisiones de `scripts_for_zotero`

Registro único de por qué el repo está como está. **Los números son permanentes**: una entrada no
se renumera ni se borra; si deja de regir, lleva al inicio *Superada por §N*. Lo pendiente está al
final.

## 1. El repo se retira; lo sustituye `scripts_for_calibre` (2026-08-09)

Las transformaciones de etiquetas y de nombres quedaron absorbidas por
`scripts_for_calibre/script_sincronizar_zotero`, que lleva a Zotero lo que fija Calibre («Calibre
manda») con copia, bloqueo y comprobación de integridad. Ejecutar los scripts sueltos reintroduce
divergencia que el sync nocturno revierte o amplifica (`meta/diagnosticos/AUDITORIA.md`, A3).
Retirados: `capitalizar_tags/`, `traducir_tags_español/` e `invertir_nombres/`; este último es el
peor caso, porque su intercambio ciego de nombre y apellido rompe la comparación de autores por
tokens del sync y dispara escrituras masivas de conflicto.

## 2. Un solo incrustador de metadatos en PDF (2026-08-09)

Dos incrustadores con mapeos divergentes reescribían los mismos PDF. El canónico es
`scripts_for_calibre/script_metadatos_calibre` (desde el OPF de Calibre), que absorbió el mapeo XMP
de `script_inscrustar_metadatos_pdf/`; este queda retirado, y su operación `limpiar-json` retira los
`zotero_metadata.json` que el viejo sembraba (`meta/diagnosticos/AUDITORIA.md`, A7).

## 3. `series_organizer` sigue vivo, después del sync (2026-08-09)

Solo reorganiza colecciones, sin tocar metadatos ni etiquetas, así que no choca con el sync. Se
corre a mano y **después** de un sync, nunca antes, con copia de seguridad previa y
`modoSimulacion: true` en la primera pasada.

## 4. Aquí no se añaden scripts (2026-08-09)

Una transformación nueva de etiquetas o metadatos de Zotero se propone como regla de
`script_sincronizar_zotero`; incrustar metadatos en PDF es de `script_metadatos_calibre`.

## 5. Lo retirado se conserva, no se borra (2026-08-09; manuales a `historial/` el 2026-10-03)

Cada carpeta retirada guarda su script, su `suite.yml` en `estado: retirado` y un README de una
línea que remite al sustituto; el manual de uso de cada una pasó a `historial/`.

## Pendientes

- **`script_inscrustar_metadatos_pdf/suite.yml`** anuncia como comando
  `bash embed_pdf_metadata.sh <carpeta>`, una orden ejecutable de un script retirado, y su `nota` no
  dice fecha ni sustituto, a diferencia de las otras tres retiradas. Corregirlo y regenerar con
  `core/suites.py generar --aplicar` (que reescribe todos los bloques del workspace).
- **`series_organizer/suite.yml`** anuncia `node --check series_organizer.js`, que falla: el
  `return await` final es válido en la consola de Zotero, no en Node. Sustituirlo por la
  comprobación de `CLAUDE.md`.
- **Sin archivo `LICENSE`** en un repo de remoto público.
