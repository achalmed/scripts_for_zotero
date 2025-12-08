var items = ZoteroPane.getSelectedItems(); // Obtiene los ítems seleccionados en Zotero
for (let item of items) {
    var creators = item.getCreators(); // Obtiene los autores de cada ítem
    var modified = false;
    for (let creator of creators) {
        // Verifica si ambos campos (firstName y lastName) existen
        if (creator.firstName && creator.lastName) {
            // Intercambia el contenido de Nombre y Apellido
            let temp = creator.firstName; // Guarda el "Nombre" (que en tu caso es el apellido)
            creator.firstName = creator.lastName; // Pone el "Apellido" (que es el nombre) en el campo Nombre
            creator.lastName = temp; // Pone el "Nombre" original (apellido) en el campo Apellido
            modified = true;
        }
    }
    if (modified) {
        item.setCreators(creators); // Actualiza los autores en el ítem
        await item.saveTx(); // Guarda los cambios en la base de datos
    }
}
return "Nombres y apellidos invertidos exitosamente en los ítems seleccionados.";