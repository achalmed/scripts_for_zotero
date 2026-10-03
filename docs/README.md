---
tipo: readme
estado: activo
---
# docs/ — documentación de `scripts_for_zotero`: un repo retirado salvo `series_organizer`

El uso del único script vivo está en `../series_organizer/README.md`; aquí vive el porqué del
retiro y lo que queda de lo retirado. `historial/` se lee para saber qué hacía un script, nunca
para ejecutarlo.

## Por dónde empezar

| si eres… | empieza por |
|---|---|
| **quien organiza su biblioteca** (usa `series_organizer`) | [`../README.md`](../README.md) → [`../series_organizer/README.md`](../series_organizer/README.md) |
| **quien busca un script viejo** | [decisiones.md](decisiones.md) (qué lo sustituye) → [historial/](historial/README.md) |
| **quien mantiene** (el repo o el sync que lo sustituye) | [`../CLAUDE.md`](../CLAUDE.md) → [decisiones.md](decisiones.md) → `scripts_for_calibre/script_sincronizar_zotero/README.md` |

## Cómo se mantiene

- Lo nuevo va al documento de su concepto; nunca un `.md` por cambio, fecha o sesión.
- La decisión y su porqué, a [decisiones.md](decisiones.md) (sus números no se renumeran); lo
  pendiente, a su §Pendientes.
- La tabla de abajo la escribe `python3 core/docs.py indice scripts_for_zotero --aplicar` (desde
  `~/Documents`).

## Índice

<!-- docs:inicio -->
| documento | tipo | estado | qué es |
|---|---|---|---|
| [decisiones.md](decisiones.md) | `decision` | `activo` | Decisiones del repo retirado y lo pendiente |
| [historial/README.md](historial/README.md) | `readme` | `activo` | docs/historial/ — los manuales de los scripts retirados de `scripts_for_zotero` |
| [historial/capitalizar-tags.md](historial/capitalizar-tags.md) | `doc` | `retirado` | Etiquetas de Zotero a Título Capitalizado: el manual del script retirado |
| [historial/incrustador-metadatos-pdf.md](historial/incrustador-metadatos-pdf.md) | `doc` | `retirado` | Incrustador de metadatos Zotero → PDF (v8.0): el manual del script retirado |
| [historial/invertir-nombres.md](historial/invertir-nombres.md) | `doc` | `retirado` | Intercambio nombre ↔ apellido de los creadores en Zotero: el manual del script retirado |
| [historial/traducir-tags-espanol.md](historial/traducir-tags-espanol.md) | `doc` | `retirado` | Etiquetas de Zotero del inglés al español por diccionario: el manual del script retirado |

<sub>Bloque generado por `core/docs.py indice` desde el frontmatter de docs/ (2026-10-03); no se edita a mano.</sub>
<!-- docs:fin -->
