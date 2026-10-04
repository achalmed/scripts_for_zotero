---
tipo: readme
estado: activo
---
# scripts_for_zotero/ — scripts «Run JavaScript» para Zotero, repo retirado salvo `series_organizer`

> **Retirado.** Lo sustituye `scripts_for_calibre/`: `script_sincronizar_zotero` lleva los
> metadatos y las etiquetas de Calibre a Zotero («Calibre manda») y `script_metadatos_calibre` es
> el incrustador único de metadatos en PDF. Aquí solo sigue vivo `series_organizer/`; los demás
> scripts **no se ejecutan** (`meta/diagnosticos/AUDITORIA.md`, hallazgos A3 y A7).

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

## Qué es

Scripts que se pegan en la consola de Zotero (Herramientas → Desarrollador → Ejecutar JavaScript)
para ordenar la biblioteca de referencias, más un incrustador Bash de metadatos en PDF. Nacieron
antes de la sincronización Calibre ⇄ Zotero; cuando esta absorbió sus transformaciones, el repo se
retiró y quedó vivo un solo script: `series_organizer/`, que reparte una colección en
subcolecciones por el campo *Series* y se corre a mano **después** de un sync.

**No es** parte del flujo del ecosistema: nada aquí corre por timer ni lo invoca otra suite. La
verdad de los metadatos vive en Calibre (`biblioteca/`) y llega a Zotero por
`scripts_for_calibre/script_sincronizar_zotero`, que corre cada noche desde el timer
`ecosistema-metadatos` de `scripts_for_calibre/script_ecosistema_lectura`; el contrato global está
en `meta/MODELO_METADATOS.md` y `meta/SINCRONIZACION.md`. No carga nada de `core/`: sus `suite.yml` solo
cumplen el contrato que valida `core/suites.py`.

## Uso

Solo `series_organizer`; el detalle de su `CONFIG` y de sus fases, en `series_organizer/README.md`.

```bash
cat series_organizer/series_organizer.js | xclip -selection clipboard   # al portapapeles
```

1. Copia de seguridad de Zotero (Archivo → Exportar biblioteca → Zotero RDF con archivos).
2. En Zotero: **Herramientas → Desarrollador → Ejecutar JavaScript**, pegar el script.
3. En el bloque `CONFIG` del principio: `nombreColeccionPrincipal` (por defecto `"Calibre"`),
   `modoSimulacion` (**`true` la primera vez**: solo muestra qué haría), `limitePrueba` (por
   ejemplo `10` para un ensayo real acotado) y `mantenerEnColeccionPrincipal`.
4. **Run**. El detalle de las cuatro fases sale en la consola; el resumen final, en la ventana.

## Estructura

| carpeta | qué es | estado |
|---|---|---|
| `series_organizer/` | `series_organizer.js`: subcolecciones por el campo *Series* dentro de una colección | activo; el único en uso |
| `capitalizar_tags/` | etiquetas a Título Capitalizado | retirado → `script_sincronizar_zotero` |
| `traducir_tags_español/` | etiquetas inglés → español por diccionario | retirado → `script_sincronizar_zotero` |
| `invertir_nombres/` | intercambio nombre ↔ apellido de los creadores | retirado y **peligroso** → `script_sincronizar_zotero` |
| `script_inscrustar_metadatos_pdf/` | exportación de Zotero a JSON + incrustación en PDF con exiftool | retirado → `script_metadatos_calibre` |
| `docs/` | decisiones y pendientes; en `historial/`, el manual de cada script retirado | a mano; índice por `core/docs.py indice` |
| `suite.yml` (uno por carpeta) | manifiesto (`core/suite.schema.yml`) | a mano; los bloques de README los escribe `core/suites.py generar --aplicar` |

Cada carpeta retirada conserva su script y un README de una línea que remite a su sustituto.

## Documentación

| documento | para qué leerlo |
|---|---|
| `series_organizer/README.md` | opciones de `CONFIG`, fases del script, problemas frecuentes |
| `docs/README.md` | mapa de `docs/` por lector |
| `docs/decisiones.md` | por qué se retiró cada cosa, qué sigue vivo y qué está pendiente |
| `docs/historial/` | el manual de cada script retirado, para leer qué lógica aplicaba |
| `CLAUDE.md` | reglas para el asistente: qué no se ejecuta y cómo se verifica |
| `scripts_for_calibre/script_sincronizar_zotero/README.md` | la política que absorbió a estos scripts |
| `meta/INDICE_SCRIPTS.md` | las suites de este repo entre las del workspace (generado) |

## Límite honesto

- **Sin línea de comandos ni simulación fuera de Zotero**: un script se ejecuta pegándolo en la
  consola; la única simulación es `modoSimulacion: true` de `series_organizer`, que viene en
  `false` y hay que activarla editando el script.
- **Todo escribe en `zotero.sqlite` a través de la API de Zotero**, sin copia automática: la copia
  de seguridad es manual y previa.
- **`series_organizer` mueve ítems, no los copia** (salvo `mantenerEnColeccionPrincipal: true`), con
  transacciones por ítem: lento en colecciones grandes y reversible solo a mano.
- **`node --check` no sirve para comprobarlo**: el script termina en un `return await` de nivel
  superior, válido en la consola de Zotero y error de sintaxis en Node; la comprobación que vale
  está en `CLAUDE.md`.
- **Los scripts retirados no se mantienen ni se prueban** contra versiones nuevas de Zotero.
- **Licencia MIT** (`LICENSE`), como el resto del código del ecosistema.
