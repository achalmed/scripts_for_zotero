async function translateTagsToSpanish() {
    // Diccionario de traducción inglés-español (ampliable)
    const translationDict = {
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
        "Computer Science": "ciencias de la computación",
        "Social Sciences": "ciencias sociales",
        "econometrics": "econometría",
        "Probability": "probabilidad",
        "Political Science": "ciencia política",
        "Political": "política",
        "Government": "gobierno",
        // Añade más términos según tus necesidades
    };
    
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
    var untranslatedTags = new Set(); // Registrar tags no traducidos
    const batchSize = 100; // Procesar en lotes de 100 ítems
    
    // Procesar en lotes
    for (let i = 0; i < itemsWithTags.length; i += batchSize) {
        let batch = itemsWithTags.slice(i, i + batchSize);
        
        await Zotero.DB.executeTransaction(async function () {
            for (let item of batch) {
                let tags = item.getTags();
                let tagsChanged = false;
                let spanishTags = new Set(); // Evitar duplicados en español
                
                // Obtener tags en español existentes
                for (let tag of tags) {
                    let tagLower = tag.tag.toLowerCase();
                    if (Object.values(translationDict).includes(tagLower)) {
                        spanishTags.add(tagLower);
                    }
                }
                
                // Procesar tags
                for (let tag of tags) {
                    let tagLower = tag.tag.toLowerCase();
                    let newTag = null;
                    
                    // Verificar si el tag está en el diccionario (inglés)
                    if (translationDict[tagLower]) {
                        newTag = translationDict[tagLower];
                    } else if (!Object.values(translationDict).includes(tagLower)) {
                        // Registrar tags no traducidos (posiblemente en inglés u otro idioma)
                        untranslatedTags.add(tag.tag);
                    }
                    
                    if (newTag && !spanishTags.has(newTag)) {
                        // Reemplazar tag en inglés por español
                        item.removeTag(tag.tag);
                        item.addTag(newTag, tag.type); // Mantener tipo de tag
                        spanishTags.add(newTag);
                        tagsChanged = true;
                    } else if (newTag && spanishTags.has(newTag)) {
                        // Eliminar tag en inglés si ya existe en español
                        item.removeTag(tag.tag);
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
    
    // Guardar tags no traducidos en un archivo
    if (untranslatedTags.size > 0) {
        let untranslatedArray = Array.from(untranslatedTags);
        let outputPath = Zotero.File.pathToFile(Zotero.getProfileDirectory().path + '/untranslated_tags.txt');
        await Zotero.File.putContentsAsync(outputPath, untranslatedArray.join('\n'));
        return `${updatedCount} item(s) updated. Untranslated tags saved to ${outputPath.path}`;
    }
    
    return updatedCount + " item(s) updated";
}

// Ejecutar la función
return translateTagsToSpanish();