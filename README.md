---
tipo: readme
estado: activo
---
# scripts_for_zotero/ — scripts «Run JavaScript» para Zotero, repo retirado salvo `series_organizer`

<!-- suites:inicio -->
Suites de esta carpeta (5); índice global en `meta/INDICE_SCRIPTS.md`. Patrón: M main · C config · L lib.

| Suite | Carpeta | Objetivo | Escribe en | Simula | Timer | Estado | Patrón |
|---|---|---|---|---|---|---|---|
| `capitalizar_tags` | [scripts_for_zotero/capitalizar_tags](capitalizar_tags/) | biblioteca | zotero | no |  | retirado | `···` |
| `invertir_nombres` | [scripts_for_zotero/invertir_nombres](invertir_nombres/) | biblioteca | zotero | no |  | retirado | `···` |
| `inscrustar_metadatos_pdf` | [scripts_for_zotero/script_inscrustar_metadatos_pdf](script_inscrustar_metadatos_pdf/) | biblioteca | archivos | no |  | retirado | `···` |
| `series_organizer` | [scripts_for_zotero/series_organizer](series_organizer/) | biblioteca | zotero | no |  | activo | `···` |
| `traducir_tags_español` | [scripts_for_zotero/traducir_tags_español](traducir_tags_español/) | biblioteca | zotero | no |  | retirado | `···` |

<sub>Bloque generado desde los `suite.yml` por `core/suites.py generar` (2026-09-20); no se edita a mano.</sub>
<!-- suites:fin -->

> ⚠️ **REPO RETIRADO (auditoría 2026-08-09, hallazgo A3 de `meta/diagnosticos/AUDITORIA.md`), salvo
> `series_organizer`.** Las transformaciones de etiquetas y de nombres fueron **absorbidas** por
> `scripts_for_calibre/script_sincronizar_zotero` (su README, §«Herramientas relacionadas»): ejecutarlas
> hoy reintroduce divergencia y el sync nocturno (`ecosistema-metadatos.timer`, 04:30) la revierte o la
> amplifica. En particular **NO ejecutar `invertir_nombres/invertir_nombres.js`**: intercambio ciego de
> nombre y apellido que rompe la comparación semántica de autores del sync y dispara escrituras masivas de
> conflicto. `capitalizar_tags` y `traducir_tags_español` chocan con la política de vocabulario «Calibre
> manda». El incrustador de PDF (`script_inscrustar_metadatos_pdf`) se consolidó en
> `scripts_for_calibre/script_metadatos_calibre` (hallazgo A7, `meta/diagnosticos/PLAN_MIGRACION.md`).

## Qué es

Cinco carpetas con scripts que se pegan en la consola de Zotero (Herramientas → Desarrollador →
Ejecutar JavaScript) para limpiar y organizar la biblioteca de referencias, y un incrustador Bash de
metadatos en PDF. Nacieron en 2024–2025, antes de que existiera la sincronización Calibre ⇄ Zotero;
desde el 2026-08-09 solo `series_organizer/` sigue en uso, como organizador de subcolecciones **después**
de cada sync. El resto se conserva como historia, con su `suite.yml` en `estado: retirado` y el
sustituto declarado en cada carpeta.

**No es** parte del flujo del ecosistema: nada aquí corre por timer ni lo invoca otra suite. La verdad
de los metadatos vive en Calibre (`biblioteca/`) y llega a Zotero por
`scripts_for_calibre/script_sincronizar_zotero`; el contrato global está en `meta/MODELO_METADATOS.md`
y `meta/SINCRONIZACION.md`. Depende solo de `core/` para el contrato de suites (`meta/workspace.yml`).

## Uso

Solo `series_organizer`; los demás scripts no se ejecutan (ver el aviso de arriba).

```bash
cat series_organizer/series_organizer.js | xclip -selection clipboard   # copiar el script al portapapeles
```

1. En Zotero: **Herramientas → Desarrollador → Ejecutar JavaScript**, pegar el script.
2. Revisar el bloque `CONFIG` al inicio: `nombreColeccionPrincipal` (por defecto `"Calibre"`),
   `modoSimulacion` (**ponerlo en `true` la primera vez**: solo muestra qué haría), `limitePrueba`
   (por ejemplo `10` para un ensayo real acotado), `mantenerEnColeccionPrincipal`.
3. **Run**. El detalle de las cuatro fases sale en la consola; el resumen final, en la ventana.
4. Copia de seguridad antes de una pasada real (Archivo → Exportar biblioteca → Zotero RDF con archivos).

## Estructura

| carpeta | qué es | estado / sustituto |
|---|---|---|
| `series_organizer/` | `series_organizer.js` (v2.0): subcolecciones por el campo *Series* dentro de una colección | activo; el único en uso |
| `capitalizar_tags/` | `capitalizar_tags.js`: etiquetas a Título Capitalizado | retirado → política de vocabulario de `script_sincronizar_zotero` |
| `traducir_tags_español/` | `traducir_tags_español.js`: etiquetas inglés → español por diccionario | retirado → `script_sincronizar_zotero` (Calibre manda) |
| `invertir_nombres/` | `invertir_nombres.js`: intercambio nombre ↔ apellido | retirado y **peligroso**; el sync compara autores por tokens y tolera la inversión |
| `script_inscrustar_metadatos_pdf/` | `zotero_export_metadata.js` + `embed_pdf_metadata.sh` (v8.0) | retirado → `scripts_for_calibre/script_metadatos_calibre` |
| `suite.yml` (uno por carpeta) | manifiesto (`core/suite.schema.yml`); los bloques de README los genera `core/suites.py generar --aplicar` | a mano |

## Documentación

| documento | para qué leerlo |
|---|---|
| `CLAUDE.md` | qué está vivo, qué no se ejecuta y por qué, cómo se verifica |
| `series_organizer/README.md` | opciones de `CONFIG`, fases del script, precauciones |
| `scripts_for_calibre/script_sincronizar_zotero/README.md` | la política que absorbió a estos scripts |
| `meta/diagnosticos/AUDITORIA.md` | hallazgos A3 (repo retirado) y A7 (un solo incrustador) |
| `meta/INDICE_SCRIPTS.md` | las 5 suites entre las del workspace (generado) |

## Límite honesto

- **Sin línea de comandos ni simulación fuera de Zotero**: un script se ejecuta pegándolo en la consola;
  la única «simulación» es `modoSimulacion: true` de `series_organizer`, y solo ahí.
- **Todo escribe en `zotero.sqlite` a través de la API de Zotero**, sin backup automático: la copia de
  seguridad es manual y previa.
- **`series_organizer` mueve ítems, no los copia** (salvo `mantenerEnColeccionPrincipal: true`), una
  transacción por ítem: lento en bibliotecas grandes; reversible solo a mano.
- **Los cuatro scripts retirados no se mantienen ni se prueban** contra versiones nuevas de Zotero; se
  conservan por historia y para leer qué lógica aplicaban.
- Licencia MIT declarada en el remoto público; no hay archivo `LICENSE` en el repo.
