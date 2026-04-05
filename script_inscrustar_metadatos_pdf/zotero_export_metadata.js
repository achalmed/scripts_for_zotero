/**
 * =============================================================================
 * ZOTERO: Exportar Metadatos a JSON — v5.0
 * =============================================================================
 *
 * DESCRIPCIÓN:
 *   Exporta los metadatos de cada ítem seleccionado en Zotero a un archivo
 *   "zotero_metadata.json" que se guarda EN LA MISMA CARPETA que el PDF.
 *
 *   Estructura de biblioteca compatible:
 *     /biblioteca/Autor, Nombre/Titulo del libro (ID)/
 *       ├── Titulo del libro - Autor, Nombre.pdf   ← PDF
 *       ├── zotero_metadata.json                   ← Generado aquí
 *       ├── cover.jpg
 *       └── metadata.opf
 *
 * FLUJO DE TRABAJO (2 pasos):
 *
 *   PASO 1 — En Zotero:
 *     Selecciona ítems → Herramientas → Ejecutar JavaScript → pega y Ejecutar.
 *     Se genera "zotero_metadata.json" junto a cada PDF.
 *
 *   PASO 2 — En el terminal (Arch Linux):
 *     bash ~/embed_pdf_metadata.sh [RUTA_CARPETA]
 *     Ejemplos:
 *       bash ~/embed_pdf_metadata.sh                            # toda la biblioteca
 *       bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca     # carpeta específica
 *       bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca/Yulino,\ Anastacio\ Clemente
 *
 * CÓMO EJECUTAR EN ZOTERO:
 *   1. Selecciona todos los ítems (Ctrl+A) o los que desees procesar.
 *   2. Herramientas → Ejecutar JavaScript.
 *   3. Pega este script completo → clic en "Ejecutar".
 *   4. Espera el mensaje de confirmación.
 * =============================================================================
 */
(async () => {

  // ── Utilidades ──────────────────────────────────────────────────────────────

  function mapItemType(t) {
    const m = {
      journalArticle:   "Journal Article",
      book:             "Book",
      bookSection:      "Book Section",
      thesis:           "Thesis",
      report:           "Report",
      conferencePaper:  "Conference Paper",
      preprint:         "Preprint",
      document:         "Document",
      manuscript:       "Manuscript",
      magazineArticle:  "Magazine Article",
      newspaperArticle: "Newspaper Article",
      presentation:     "Presentation",
      computerProgram:  "Software",
      webpage:          "Web Page",
      patent:           "Patent",
    };
    return m[t] || "Text";
  }

  function safeField(item, ...fields) {
    for (const f of fields) {
      try {
        const v = item.getField(f);
        if (v && v.trim()) return v.trim();
      } catch (e) {}
    }
    return "";
  }

  function extractMetadata(item) {
    const creators    = item.getCreators();
    const authorType  = Zotero.CreatorTypes.getID("author");
    const editorType  = Zotero.CreatorTypes.getID("editor");

    let authors = creators
      .filter(c => c.creatorTypeID === authorType)
      .map(c => [c.firstName, c.lastName].filter(Boolean).join(" "));

    let editors = creators
      .filter(c => c.creatorTypeID === editorType)
      .map(c => [c.firstName, c.lastName].filter(Boolean).join(" "));

    // Si no hay autores explícitos, usa todos los creadores
    if (authors.length === 0)
      authors = creators
        .map(c => [c.firstName, c.lastName].filter(Boolean).join(" "))
        .filter(Boolean);

    const doi = safeField(item, "DOI");
    const url = safeField(item, "url");
    const isbn = safeField(item, "ISBN");
    const issn = safeField(item, "ISSN");

    // Identificador preferido: DOI > ISBN > ISSN > URL
    let identifier = "";
    if (doi)  identifier = `doi:${doi}`;
    else if (isbn) identifier = `isbn:${isbn}`;
    else if (issn) identifier = `issn:${issn}`;
    else if (url)  identifier = url;

    const rawType = Zotero.ItemTypes.getName(item.itemTypeID);

    return {
      title:       safeField(item, "title"),
      authors,
      editors,
      abstract:    safeField(item, "abstractNote"),
      tags:        item.getTags().map(t => t.tag).filter(Boolean),
      publisher:   safeField(item, "publisher", "institution", "university"),
      date:        safeField(item, "date"),
      year:        safeField(item, "date").replace(/.*(\d{4}).*/, "$1").slice(0, 4) || "",
      doi,
      url,
      isbn,
      issn,
      identifier,
      itemType:    mapItemType(rawType),
      rawItemType: rawType,
      source:      safeField(item,
                     "publicationTitle", "bookTitle",
                     "seriesTitle", "conferenceName",
                     "encyclopediaTitle", "dictionaryTitle"),
      volume:      safeField(item, "volume"),
      issue:       safeField(item, "issue"),
      pages:       safeField(item, "pages"),
      language:    safeField(item, "language"),
      rights:      safeField(item, "rights"),
      series:      safeField(item, "series"),
      place:       safeField(item, "place"),
      edition:     safeField(item, "edition"),
      numPages:    safeField(item, "numPages"),
      callNumber:  safeField(item, "callNumber"),
      zoteroKey:   item.key || "",
      zoteroId:    item.id ? String(item.id) : "",
      exportedAt:  new Date().toISOString(),
    };
  }

  // ── Recoger ítems seleccionados ─────────────────────────────────────────────
  const selectedItems = Zotero.getActiveZoteroPane().getSelectedItems();
  if (!selectedItems || selectedItems.length === 0) {
    Zotero.alert(null, "Sin selección",
      "Selecciona al menos un ítem con PDF adjunto.\n\n" +
      "Tip: Ctrl+A para seleccionar toda la biblioteca.");
    return;
  }

  let processed = 0;
  let skipped   = 0;
  let errors    = 0;
  const errorList = [];

  for (const item of selectedItems) {
    // Saltar notas y adjuntos directos
    if (item.isNote() || item.isAttachment()) { skipped++; continue; }

    // Obtener todos los PDFs adjuntos al ítem
    const attachmentIds = item.getAttachments();
    const pdfAttachments = [];

    for (const id of attachmentIds) {
      try {
        const att = await Zotero.Items.getAsync(id);
        if (att?.isAttachment() && att.attachmentContentType === "application/pdf") {
          const fp = await att.getFilePathAsync();
          if (fp) pdfAttachments.push({ path: fp, att });
        }
      } catch (e) {
        // ignorar adjunto fallido
      }
    }

    if (pdfAttachments.length === 0) { skipped++; continue; }

    // Extraer metadatos una vez por ítem
    let meta;
    try {
      meta = extractMetadata(item);
    } catch (e) {
      errors++;
      errorList.push(`[extractMetadata] ${item.getField?.("title") || "?"}: ${e.message}`);
      continue;
    }

    // Para cada PDF: guardar zotero_metadata.json en la misma carpeta
    for (const { path: pdfPath } of pdfAttachments) {
      try {
        // Directorio del PDF
        const pdfDir  = PathUtils.parent(pdfPath);
        const jsonOut = PathUtils.join(pdfDir, "zotero_metadata.json");

        // Payload: metadatos + ruta relativa del PDF
        const pdfFilename = PathUtils.filename(pdfPath);
        const payload = {
          ...meta,
          pdf_filename: pdfFilename,
          pdf_path:     pdfPath,
        };

        await IOUtils.writeUTF8(jsonOut, JSON.stringify(payload, null, 2));
        Zotero.log(`✅ Metadatos guardados: ${jsonOut}`);
        processed++;
      } catch (e) {
        errors++;
        errorList.push(`[writeJSON] ${pdfPath}: ${e.message}`);
        Zotero.log(`❌ Error escribiendo JSON para: ${pdfPath}\n${e.message}`);
      }
    }
  }

  // ── Resumen final ───────────────────────────────────────────────────────────
  let msg =
    `📊 RESULTADO DE LA EXPORTACIÓN\n` +
    `${"─".repeat(40)}\n` +
    `✅ Archivos JSON generados : ${processed}\n` +
    `⏭  Ítems sin PDF / saltados: ${skipped}\n` +
    `❌ Errores                 : ${errors}\n\n` +
    `Cada "zotero_metadata.json" se guardó\n` +
    `en la misma carpeta que su PDF.\n\n`;

  if (errors > 0) {
    msg += `⚠️  Errores encontrados:\n`;
    errorList.slice(0, 5).forEach(e => { msg += `  • ${e}\n`; });
    if (errorList.length > 5) msg += `  ... y ${errorList.length - 5} más (ver Zotero log)\n`;
    msg += "\n";
  }

  msg +=
    `SIGUIENTE PASO:\n` +
    `Abre tu terminal y ejecuta:\n\n` +
    `  bash ~/embed_pdf_metadata.sh\n\n` +
    `O para una carpeta específica:\n` +
    `  bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca/Autor`;

  Zotero.alert(null, "✅ Exportación completada", msg);
  Zotero.log(`=== Exportación finalizada: ${processed} OK, ${skipped} saltados, ${errors} errores ===`);

})();
