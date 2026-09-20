---
tipo: guia_ia
estado: activo
---
# CLAUDE.md — scripts_for_zotero

Guía para el asistente. En español, como todo el ecosistema. `AGENTS.md` es un enlace a este archivo.
Léase antes: `README.md` (el aviso de retiro y qué sigue vivo), `series_organizer/README.md`, y
`scripts_for_calibre/script_sincronizar_zotero/README.md` (la política que absorbió a estos scripts).

## Reglas que no se negocian

- **El repo está retirado salvo `series_organizer/`** (auditoría 2026-08-09, hallazgo A3 de
  `meta/diagnosticos/AUDITORIA.md`). Vivo: `series_organizer/series_organizer.js`. Retirados:
  `capitalizar_tags/`, `traducir_tags_español/`, `invertir_nombres/`, `script_inscrustar_metadatos_pdf/`.
- **No se ejecuta ningún script retirado, ni en pruebas.** Sus transformaciones están absorbidas por
  `scripts_for_calibre/script_sincronizar_zotero` («Calibre manda» en vocabulario y metadatos; autores
  comparados por tokens); ejecutarlos reintroduce divergencia que el timer `ecosistema-metadatos` (04:30)
  revierte o amplifica. `invertir_nombres.js` es el peor caso: intercambio ciego de nombre y apellido que
  dispara escrituras masivas de conflicto en el siguiente sync.
- **No se añaden scripts aquí.** Una transformación nueva de etiquetas o metadatos de Zotero se propone
  como regla de `script_sincronizar_zotero` (que escribe con backup, lock e `integrity_check`), no como
  `.js` suelto. Incrustar metadatos en PDF es de `scripts_for_calibre/script_metadatos_calibre`.
- **`series_organizer` corre después del sync, nunca antes**, con copia de seguridad de Zotero y
  `modoSimulacion: true` en la primera pasada; solo reorganiza colecciones, no toca metadatos.
- **Cada carpeta lleva `suite.yml`** (`core/suite.schema.yml`): `estado: retirado` con `nota:` (causa,
  fecha, sustituto) en las cuatro retiradas, `activo` en `series_organizer`. Los bloques de README
  entre `<!-- suite:inicio -->` y `<!-- suites:inicio -->` los genera `core/suites.py generar --aplicar`.
- **Sin rutas de máquina** (`/home/…`) en docs ni scripts; nada del despacho.

## Cómo se verifica un cambio

```bash
python3 core/archivos.py validar scripts_for_zotero    # A01–A14 y D01–D12, desde ~/Documents
python3 core/suites.py validar                          # los 5 suite.yml; series_organizer solo avisa (sin main.sh)
python3 core/suites.py generar                          # ¿bloques de README e índice desfasados? (simula)
node --check series_organizer/series_organizer.js       # sintaxis del único script vivo
meta/doctor/main.sh --breve                             # desde ~/Documents
```

Un cambio en `series_organizer.js` se prueba en Zotero con `modoSimulacion: true` y después con
`limitePrueba: 10` sobre una colección pequeña; no hay otra prueba posible fuera de Zotero.

## Detalles que cuesta redescubrir

- **Los nombres reales de los scripts son los de sus carpetas** (`capitalizar_tags.js`,
  `traducir_tags_español.js`, `invertir_nombres.js`, `series_organizer.js`); el README antiguo citaba
  cuatro nombres en inglés que nunca existieron.
- **`series_organizer` mueve el ítem padre**, así que notas, anotaciones y adjuntos viajan con él; con
  `mantenerEnColeccionPrincipal: false` el ítem sale de la colección principal.
- **`traducir_tags_español.js` escribía `untranslated_tags.txt` en el perfil de Zotero**: si aparece un
  archivo así, es un resto de aquella época, no de ninguna suite viva.
- **La carpeta `traducir_tags_español` lleva tilde en el nombre**: en `git ls-files` sale escapada
  (`traducir_tags_espa\303\261ol`); es la misma carpeta.
- `.Rhistory` en la raíz era un artefacto de RStudio ajeno al repo (retirado en DOC6).

## Dónde está cada cosa

| pregunta | documento |
|---|---|
| qué se retiró, cuándo y por qué | `README.md` (aviso), `meta/diagnosticos/AUDITORIA.md` (A3, A7) |
| cómo usar el único script vivo | `series_organizer/README.md` |
| la política que sustituye a los scripts | `scripts_for_calibre/script_sincronizar_zotero/README.md` |
| el incrustador vigente de PDF | `scripts_for_calibre/script_metadatos_calibre/README.md` |
| el contrato de suite y el índice | `core/suite.schema.yml`, `meta/INDICE_SCRIPTS.md` |
