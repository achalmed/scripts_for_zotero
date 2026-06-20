////////////////////////////////////////////////////////////////////////////////
// SCRIPT DE ZOTERO: TRADUCIR TAGS (ETIQUETAS) DE INGLÉS A ESPAÑOL
////////////////////////////////////////////////////////////////////////////////
//
// DESCRIPCIÓN:
//   Recorre los ítems seleccionados en Zotero y traduce sus tags en inglés
//   al español usando un diccionario interno (ampliable). Si el ítem ya
//   tiene el tag equivalente en español, simplemente elimina el tag en
//   inglés para evitar duplicados.
//
// AUTOR: Edison Achalma
//
// USO:
//   1. Selecciona uno o más ítems en tu biblioteca de Zotero.
//   2. Ve a Herramientas → Desarrollador → Ejecutar JavaScript.
//   3. Pega este código completo en el editor.
//   4. Haz clic en "Run" (Ejecutar).
//   5. Revisa el mensaje de resultado: indica cuántos ítems se actualizaron
//      y, si los hay, dónde se guardó la lista de tags que no se pudieron
//      traducir (no estaban en el diccionario).
//
// CÓMO AMPLIAR EL DICCIONARIO:
//   Agrega nuevas líneas dentro de DICCIONARIO_TRADUCCION con el formato:
//       "termino en ingles": "término en español",
//   Las claves del diccionario distinguen mayúsculas/minúsculas tal como
//   están escritas, pero la comparación con los tags reales se hace en
//   minúsculas, así que no es necesario duplicar variantes de capitalización.
//
// PRECAUCIONES:
//   - Este script modifica tus ítems de forma permanente.
//   - Se recomienda hacer una copia de seguridad antes de ejecutarlo sobre
//     toda la biblioteca.
//   - Los tags que no estén en el diccionario se dejan tal cual (no se
//     borran ni se modifican) y se reportan en un archivo de texto.
//
////////////////////////////////////////////////////////////////////////////////

/**
 * Traduce los tags en inglés de los ítems seleccionados a su equivalente
 * en español, usando el diccionario definido más abajo.
 * @returns {Promise<string>} Mensaje con la cantidad de ítems actualizados
 *                            y la ruta del archivo de tags no traducidos
 *                            (si los hubo).
 */
async function traducirTagsAlEspanol() {

    // ------------------------------------------------------------------------
    // DICCIONARIO DE TRADUCCIÓN INGLÉS → ESPAÑOL (AMPLIABLE)
    // ------------------------------------------------------------------------
    const DICCIONARIO_TRADUCCION = {
        "science": "ciencia",
        "research": "investigación",
        "technology": "tecnología",
        "education": "educación",
        "biology": "biología",
        "physics": "física",
        "chemistry": "química",
        "mathematics": "matemáticas",
        "engineering": "ingeniería",
        "medicine": "medicina",
        "history": "historia",
        "literature": "literatura",
        "philosophy": "filosofía",
        "psychology": "psicología",
        "economics": "economía",
        "sociology": "sociología",
        "politics": "política",
        "environment": "medio ambiente",
        "data": "datos",
        "analysis": "análisis",
        "statistics": "estadísticas",
        "art": "arte",
        "music": "música",
        "culture": "cultura",
        "language": "idioma",
        "communication": "comunicación",
        "society": "sociedad",
        "community": "comunidad",
        "innovation": "innovación",
        "development": "desarrollo",
        "design": "diseño",
        "management": "gestión",
        "marketing": "mercadotecnia",
        "business": "negocios",
        "finance": "finanzas",
        "law": "derecho",
        "policy": "política",
        "ethics": "ética",
        "sustainability": "sostenibilidad",
        "safety": "seguridad",
        "health": "salud",
        "wellness": "bienestar",
        "nutrition": "nutrición",
        "exercise": "ejercicio",
        "macroeconomics": "macroeconomía",
        "microeconomics": "microeconomía",
        "supply chain": "cadena de suministro",
        "logistics": "logística",
        "project management": "gestión de proyectos",
        "human resources": "recursos humanos",
        "customer service": "servicio al cliente",
        "sales": "ventas",
        "leadership": "liderazgo",
        "teamwork": "trabajo en equipo",
        "creativity": "creatividad",
        "computer science": "ciencias de la computación",
        "social sciences": "ciencias sociales",
        "econometrics": "econometría",
        "probability": "probabilidad",
        "political science": "ciencia política",
        "political": "política",
        "government": "gobierno",
        // Añade más términos según tus necesidades.
        // Recuerda: las claves se comparan en minúsculas internamente.
    };

    // ------------------------------------------------------------------------
    // PASO 1: OBTENER LOS ÍTEMS SELECCIONADOS EN EL PANEL DE ZOTERO
    // ------------------------------------------------------------------------
    var paneZotero = Zotero.getActiveZoteroPane();
    var itemsSeleccionados = paneZotero.getSelectedItems();

    if (!itemsSeleccionados.length) {
        return "No hay ítems seleccionados.";
    }

    // ------------------------------------------------------------------------
    // PASO 2: FILTRAR SOLO LOS ÍTEMS QUE TIENEN AL MENOS UN TAG
    // ------------------------------------------------------------------------
    var itemsConTags = itemsSeleccionados.filter(item => item.getTags().length > 0);

    if (!itemsConTags.length) {
        return "Ninguno de los ítems seleccionados tiene tags.";
    }

    var totalActualizados = 0;
    var tagsSinTraducir = new Set(); // Registro de tags que no están en el diccionario
    const TAMANIO_LOTE = 100; // Procesar en lotes de 100 ítems

    // ------------------------------------------------------------------------
    // PASO 3: PROCESAR LOS ÍTEMS EN LOTES
    // ------------------------------------------------------------------------
    for (let i = 0; i < itemsConTags.length; i += TAMANIO_LOTE) {
        let lote = itemsConTags.slice(i, i + TAMANIO_LOTE);

        await Zotero.DB.executeTransaction(async function () {
            for (let item of lote) {
                let tags = item.getTags();
                let huboCambios = false;
                let tagsEnEspanol = new Set(); // Para evitar duplicados al traducir

                // 3.1: Registrar los tags que YA están en español
                //      (para no duplicarlos si traducimos otro tag al mismo término)
                for (let tag of tags) {
                    let tagMinuscula = tag.tag.toLowerCase();
                    if (Object.values(DICCIONARIO_TRADUCCION).includes(tagMinuscula)) {
                        tagsEnEspanol.add(tagMinuscula);
                    }
                }

                // 3.2: Procesar cada tag para traducirlo o reportarlo
                for (let tag of tags) {
                    let tagMinuscula = tag.tag.toLowerCase();
                    let tagTraducido = null;

                    // ¿El tag está en el diccionario (en inglés)?
                    if (DICCIONARIO_TRADUCCION[tagMinuscula]) {
                        tagTraducido = DICCIONARIO_TRADUCCION[tagMinuscula];
                    } else if (!Object.values(DICCIONARIO_TRADUCCION).includes(tagMinuscula)) {
                        // No está en el diccionario ni es ya una traducción válida:
                        // probablemente está en inglés (u otro idioma) sin mapear.
                        tagsSinTraducir.add(tag.tag);
                    }

                    if (tagTraducido && !tagsEnEspanol.has(tagTraducido)) {
                        // Reemplazar el tag en inglés por su equivalente en español
                        item.removeTag(tag.tag);
                        item.addTag(tagTraducido, tag.type); // Conservar el tipo de tag
                        tagsEnEspanol.add(tagTraducido);
                        huboCambios = true;
                    } else if (tagTraducido && tagsEnEspanol.has(tagTraducido)) {
                        // Ya existe el tag en español: solo eliminar el duplicado en inglés
                        item.removeTag(tag.tag);
                        huboCambios = true;
                    }
                }

                // 3.3: Guardar el ítem solo si hubo cambios
                if (huboCambios) {
                    await item.save({
                        skipDateModifiedUpdate: true
                    });
                    totalActualizados++;
                }
            }
        });
    }

    // ------------------------------------------------------------------------
    // PASO 4: GUARDAR LOS TAGS NO TRADUCIDOS EN UN ARCHIVO DE TEXTO
    // ------------------------------------------------------------------------
    if (tagsSinTraducir.size > 0) {
        let listaSinTraducir = Array.from(tagsSinTraducir);
        let rutaArchivo = Zotero.File.pathToFile(
            Zotero.getProfileDirectory().path + '/untranslated_tags.txt'
        );
        await Zotero.File.putContentsAsync(rutaArchivo, listaSinTraducir.join('\n'));
        return `${totalActualizados} ítem(s) actualizado(s). ` +
            `Los tags no traducidos se guardaron en: ${rutaArchivo.path}`;
    }

    return totalActualizados + " ítem(s) actualizado(s).";
}

// Ejecutar la función principal
return traducirTagsAlEspanol();