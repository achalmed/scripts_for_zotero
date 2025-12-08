async function capitalizeSelectedTags() {
    // Obtener ítems seleccionados
    var ZoteroPane = Zotero.getActiveZoteroPane();
    var selectedItems = ZoteroPane.getSelectedItems();

    if (!selectedItems.length) {
        return "No items selected";
    }

    // Filtrar ítems con tags
    var itemsWithTags = selectedItems.filter(item => item.getTags().length > 0);

    if (!itemsWithTags.length) {
        return "No selected items with tags found";
    }

    var updatedCount = 0;
    const batchSize = 100; // Procesar en lotes de 100 ítems

    // Procesar en lotes
    for (let i = 0; i < itemsWithTags.length; i += batchSize) {
        let batch = itemsWithTags.slice(i, i + batchSize);

        await Zotero.DB.executeTransaction(async function () {
            for (let item of batch) {
                let tags = item.getTags();
                let tagsChanged = false;

                // Procesar tags
                for (let tag of tags) {
                    let oldTag = tag.tag;
                    // Capitalizar la primera letra de cada palabra
                    let newTag = oldTag
                        .split(' ')
                        .map(word => word.charAt(0).toUpperCase() +
word.slice(1).toLowerCase())
                        .join(' ');

                    if (oldTag !== newTag) {
                        item.removeTag(oldTag);
                        item.addTag(newTag, tag.type); // Mantener tipo de tag
                        tagsChanged = true;
                    }
                }

                // Guardar solo si hubo cambios
                if (tagsChanged) {
                    await item.save({
                        skipDateModifiedUpdate: true
                    });
                    updatedCount++;
                }
            }
        });
    }

    return updatedCount + " item(s) updated";
}

// Ejecutar la función
return capitalizeSelectedTags();
