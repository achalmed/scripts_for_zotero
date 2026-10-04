---
tipo: guia_ia
estado: activo
---
# CLAUDE.md — scripts_for_zotero

Guía para el asistente. En español, como todo el ecosistema. `AGENTS.md` es un enlace a este
archivo.
**Repo retirado salvo `series_organizer/`; lo sustituye `scripts_for_calibre/`.** Léase antes:
`README.md`, `docs/README.md`, `docs/decisiones.md` (qué se retiró, por qué y qué está pendiente),
`series_organizer/README.md` y `scripts_for_calibre/script_sincronizar_zotero/README.md` (la
política que absorbió a estos scripts).

## Reglas que no se negocian

- **Vivo solo `series_organizer/series_organizer.js`.** Retirados: `capitalizar_tags/`,
  `traducir_tags_español/`, `invertir_nombres/` (absorbidos por
  `scripts_for_calibre/script_sincronizar_zotero`) y `script_inscrustar_metadatos_pdf/` (absorbido
  por `scripts_for_calibre/script_metadatos_calibre`).
- **No se ejecuta ningún script retirado, ni en pruebas**, ni nada que toque `zotero.sqlite` desde
  el asistente. Reintroducen divergencia que el timer `ecosistema-metadatos` revierte o amplifica;
  `invertir_nombres.js` es el peor caso: rompe la comparación de autores del sync y dispara
  escrituras masivas de conflicto.
- **No se añaden scripts aquí.** Una transformación nueva de etiquetas o metadatos de Zotero se
  propone como regla de `script_sincronizar_zotero` (que escribe con respaldo, bloqueo e
  `integrity_check`); incrustar metadatos en PDF es de `script_metadatos_calibre`.
- **`series_organizer` corre después del sync, nunca antes**, con copia de seguridad de Zotero y
  `modoSimulacion: true` en la primera pasada; solo reorganiza colecciones, no toca metadatos.
- **Lo retirado se conserva**: cada carpeta guarda su script, su `suite.yml` en `estado: retirado` y
  un README de una línea; el manual de uso está en `docs/historial/`. No se borra.
- **Lo generado no se edita**: los bloques `suite:`/`suites:` de los README (los escribe
  `core/suites.py generar --aplicar`) y el bloque `docs:` de `docs/README.md`
  (`core/docs.py indice`).
- **Sin rutas de máquina** (`/home/…`) en docs ni scripts; nada del despacho.
- **Dónde va cada cosa nueva.** En la raíz solo `README.md`, `CLAUDE.md`, `AGENTS.md`, `.gitignore`
  y, cuando el autor la decida, `LICENSE` (NORMATIVA §15.11); los manifiestos son por carpeta
  (`<carpeta>/suite.yml`). Cualquier otro `.md` en la raíz está fuera de lugar.

  | lo que apareció | va a | nunca a |
  |---|---|---|
  | cómo se usa `series_organizer` | `series_organizer/README.md` | el README raíz |
  | qué hacía un script retirado | `docs/historial/` (no se edita) | la carpeta del script |
  | una transformación nueva de Zotero | una regla de `script_sincronizar_zotero` | un script nuevo aquí |
  | por qué se decidió algo; un pendiente | `docs/decisiones.md` (§Pendientes con fecha y dueño) | un `NOTAS.md` o `TODO.md` |
  | lo que se hizo en la sesión | el mensaje de commit | un `.md` con fecha o de sesión |

  Lo que hiciste en esta sesión va al mensaje de commit, no a un archivo. Si nada encaja, pregunta
  antes de crear un documento.

## Cómo se verifica un cambio

Desde `~/Documents`:

```bash
python3 core/archivos.py validar scripts_for_zotero   # A01–A14 y D01–D12
python3 core/docs.py verificar scripts_for_zotero      # el índice de docs/ al día
python3 core/suites.py validar                         # series_organizer avisa: no tiene main.sh
python3 core/suites.py generar                         # ¿bloques de README desfasados? (simula)
meta/doctor/main.sh --breve
```

La sintaxis de `series_organizer.js` **no** se comprueba con `node --check` (falla por el
`return await` final, válido en Zotero): se usa la orden de `series_organizer/README.md` §Uso, que
construye la función asíncrona como Zotero sin llamarla. Un cambio de lógica se prueba en Zotero con
`modoSimulacion: true` y después con `limitePrueba: 10` sobre una colección pequeña.

## Detalles que cuesta redescubrir

- **Los nombres reales de los scripts son los de sus carpetas** (`capitalizar_tags.js`,
  `traducir_tags_español.js`, `invertir_nombres.js`, `series_organizer.js`).
- **`series_organizer` mueve el ítem padre**, así que notas, anotaciones y adjuntos viajan con él;
  con `mantenerEnColeccionPrincipal: false` el ítem sale de la colección principal. En simulación no
  crea subcolecciones, solo las anuncia.
- **`traducir_tags_español.js` escribía `untranslated_tags.txt` en el perfil de Zotero**: si aparece
  un archivo así, es un resto de aquella época.
- **El incrustador retirado sembraba `zotero_metadata.json` junto a los PDF**; los retira
  `script_metadatos_calibre limpiar-json`.
- **La carpeta `traducir_tags_español` lleva tilde**: en `git ls-files` sale escapada
  (`traducir_tags_espa\303\261ol`); es la misma carpeta. Su manual en `docs/historial/` va sin
  tilde.
- **Dos `suite.yml` anuncian comandos que no deben usarse** (`embed_pdf_metadata.sh` y
  `node --check`): pendientes en `docs/decisiones.md`; corregirlos exige regenerar todos los
  bloques del workspace.

## Dónde está cada cosa

| pregunta | documento |
|---|---|
| qué se retiró, cuándo, por qué; lo pendiente | `docs/decisiones.md`, `meta/diagnosticos/AUDITORIA.md` (A3, A7) |
| cómo usar el único script vivo | `series_organizer/README.md` |
| qué hacía un script retirado | `docs/historial/` |
| la política que sustituye a los scripts | `scripts_for_calibre/script_sincronizar_zotero/README.md` |
| el incrustador vigente de PDF | `scripts_for_calibre/script_metadatos_calibre/README.md` |
| el contrato de suite y el índice | `core/suite.schema.yml`, `meta/INDICE_SCRIPTS.md` |
