////////////////////////////////////////////////////////////////////////////////
// SCRIPT DE ZOTERO: CAPITALIZAR TAGS (ETIQUETAS) DE LOS ÍTEMS SELECCIONADOS
////////////////////////////////////////////////////////////////////////////////
//
// DESCRIPCIÓN:
//   Recorre los ítems seleccionados en Zotero y pone en mayúscula la primera
//   letra de cada palabra de sus tags (etiquetas), dejando el resto en
//   minúscula. Por ejemplo: "ciencia de datos" -> "Ciencia De Datos".
//
// AUTOR: Edison Achalma
//
// USO:
//   1. Selecciona uno o más ítems en tu biblioteca de Zotero.
//   2. Ve a Herramientas → Desarrollador → Ejecutar JavaScript.
//   3. Pega este código completo en el editor.
//   4. Haz clic en "Run" (Ejecutar).
//   5. El resultado (cuántos ítems se actualizaron) aparece en el diálogo.
//
// PRECAUCIONES:
//   - Este script modifica tus ítems de forma permanente.
//   - Se recomienda hacer una copia de seguridad antes de ejecutarlo sobre
//     toda la biblioteca.
//   - Pruébalo primero con 1-2 ítems para confirmar que el resultado es el
//     esperado.
//
////////////////////////////////////////////////////////////////////////////////

/**
 * Capitaliza (Primera Letra En Mayúscula) los tags de los ítems seleccionados.
 * @returns {Promise<string>} Mensaje con la cantidad de ítems actualizados.
 */
async function capitalizarTagsSeleccionados() {

    // ----------------------------------------------------------------------
    // PASO 1: OBTENER LOS ÍTEMS SELECCIONADOS EN EL PANEL DE ZOTERO
    // ----------------------------------------------------------------------
    var paneZotero = Zotero.getActiveZoteroPane();
    var itemsSeleccionados = paneZotero.getSelectedItems();

    if (!itemsSeleccionados.length) {
        return "No hay ítems seleccionados.";
    }

    // ----------------------------------------------------------------------
    // PASO 2: FILTRAR SOLO LOS ÍTEMS QUE TIENEN AL MENOS UN TAG
    // ----------------------------------------------------------------------
    var itemsConTags = itemsSeleccionados.filter(item => item.getTags().length > 0);

    if (!itemsConTags.length) {
        return "Ninguno de los ítems seleccionados tiene tags.";
    }

    var totalActualizados = 0;
    const TAMANIO_LOTE = 100; // Procesar en lotes de 100 ítems para no saturar la transacción

    // ----------------------------------------------------------------------
    // PASO 3: PROCESAR LOS ÍTEMS EN LOTES
    // ----------------------------------------------------------------------
    for (let i = 0; i < itemsConTags.length; i += TAMANIO_LOTE) {
        let lote = itemsConTags.slice(i, i + TAMANIO_LOTE);

        await Zotero.DB.executeTransaction(async function () {
            for (let item of lote) {
                let tags = item.getTags();
                let huboCambios = false;

                // Procesar cada tag del ítem
                for (let tag of tags) {
                    let tagOriginal = tag.tag;

                    // Capitalizar la primera letra de cada palabra del tag
                    // Ej: "datos abiertos" -> "Datos Abiertos"
                    let tagCapitalizado = tagOriginal
                        .split(' ')
                        .map(palabra => palabra.charAt(0).toUpperCase() +
                            palabra.slice(1).toLowerCase())
                        .join(' ');

                    // Solo reemplazar si realmente cambió el texto
                    if (tagOriginal !== tagCapitalizado) {
                        item.removeTag(tagOriginal);
                        item.addTag(tagCapitalizado, tag.type); // Conservar el tipo de tag (manual/automático)
                        huboCambios = true;
                    }
                }

                // Guardar el ítem solo si se modificó algún tag
                if (huboCambios) {
                    await item.save({
                        skipDateModifiedUpdate: true // No alterar la fecha de "Modificado" del ítem
                    });
                    totalActualizados++;
                }
            }
        });
    }

    return totalActualizados + " ítem(s) actualizado(s).";
}

// Ejecutar la función principal
return capitalizarTagsSeleccionados();