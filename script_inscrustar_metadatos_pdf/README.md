---
tipo: readme
estado: retirado
---
# script_inscrustar_metadatos_pdf/ — incrustador de metadatos Zotero → PDF, retirado (Zotero PDF Metadata Embedder v8.0)

<!-- suite:inicio -->
**Suite `inscrustar_metadatos_pdf`** · objetivo *biblioteca* · estado *retirado* · - · interfaz cli

Exporta metadatos de Zotero (JS) y los incrusta en los PDF; sustituido por metadatos_calibre (incrustador único con XMP).

- Escribe en: archivos · simula por defecto: no
- Nota: retirado: lo sustituye scripts-biblioteca/script_metadatos_calibre, el incrustador único con XMP; se conserva como historia

Comandos:

```bash
cat embed_pdf_metadata.sh   # retirado: se lee, no se ejecuta (reescribe los PDF)
```

<sub>Bloque generado desde `suite.yml` por `core/suites.py generar` (2026-10-06); no se edita a mano.</sub>
<!-- suite:fin -->

**Retirado; no se ejecuta.** Exportaba los metadatos de Zotero a un `zotero_metadata.json` junto a
cada PDF y los incrustaba con exiftool. Lo sustituye `scripts-biblioteca/script_metadatos_calibre`
(incrustador único desde el OPF de Calibre, con XMP), cuya operación `limpiar-json` retira los JSON
que este sembraba. El manual que lo acompañaba se conserva en
`../docs/historial/incrustador-metadatos-pdf.md`.
