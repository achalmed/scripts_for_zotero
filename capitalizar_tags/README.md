---
tipo: readme
estado: retirado
---
# capitalizar_tags/ — etiquetas de Zotero a Título Capitalizado (script «Run JavaScript», retirado)

<!-- suite:inicio -->
**Suite `capitalizar_tags`** · objetivo *biblioteca* · estado *retirado* · - · interfaz cli

Ponía las etiquetas de los ítems seleccionados de Zotero en Título Capitalizado (script «Run JavaScript»); retirado, absorbido por sincronizar_zotero.

- Escribe en: zotero · simula por defecto: no
- Depende de: zotero
- Nota: retirado el 2026-08-09 (auditoría, hallazgo A3): choca con la política de vocabulario «Calibre manda» de scripts-biblioteca/script_sincronizar_zotero, que la sustituye; se conserva como historia

Comandos:

```bash
cat capitalizar_tags.js   # solo lectura: retirado, no pegar en Zotero
```

<sub>Bloque generado desde `suite.yml` por `core/suites.py generar` (2026-10-06); no se edita a mano.</sub>
<!-- suite:fin -->

**Retirado; no se pega en Zotero.** Ponía en Título Capitalizado las etiquetas de los ítems
seleccionados. Lo sustituye la política de vocabulario «Calibre manda» de
`scripts-biblioteca/script_sincronizar_zotero`; ejecutarlo reintroduce divergencia que el sync
nocturno revierte. El manual que lo acompañaba se conserva en
`../docs/historial/capitalizar-tags.md`.
