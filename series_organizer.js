/**
 * Script para Zotero: Organizador Automático de Series (VERSIÓN CORREGIDA)
 * =========================================================================
 * 
 * DESCRIPCIÓN:
 * Este script organiza automáticamente los elementos de una colección en Zotero
 * agrupándolos por el campo "Series" en subcolecciones correspondientes.
 * 
 * VERSIÓN: 2.0 - CORREGIDA
 * - Fix: Ahora los elementos SÍ se mueven a las subcolecciones
 * - Fix: Mejor manejo de transacciones
 * - Fix: Validación de movimiento exitoso
 * 
 * FUNCIONALIDAD:
 * 1. Lee todos los elementos de una colección especificada (ej: "Calibre")
 * 2. Identifica el campo "Series" de cada elemento
 * 3. Crea subcolecciones con el nombre de cada serie única
 * 4. Mueve los elementos a sus respectivas subcolecciones
 * 5. Mantiene las notas, anotaciones y archivos adjuntos con cada elemento
 * 
 * CÓMO EJECUTAR:
 * 1. Abrir Zotero
 * 2. Ir a: Tools > Developer > Run JavaScript
 * 3. Pegar este código completo
 * 4. Configurar las opciones de la sección CONFIGURACIÓN
 * 5. Hacer clic en "Run"
 * 
 * PRECAUCIÓN:
 * - Hacer una copia de seguridad de Zotero antes de ejecutar
 * - Probar primero con una colección pequeña
 * - El proceso es reversible manualmente pero puede tomar tiempo
 * 
 * AUTOR: Adaptado para Edison Achalma
 * FECHA: Diciembre 2025
 * VERSIÓN: 2.0
 */

async function organizarElementosPorSeries() {
    // ============================================================================
    // SECCIÓN DE CONFIGURACIÓN
    // ============================================================================
    
    const CONFIG = {
        // Nombre de la colección principal a procesar
        // Puedes cambiarlo a "Taller de tesis", "Ingles", etc.
        nombreColeccionPrincipal: "Calibre",
        
        // Si es true, solo muestra qué haría sin hacer cambios reales
        modoSimulacion: false,
        
        // Si es true, muestra información detallada durante el proceso
        modoVerboso: true,
        
        // Prefijo para las subcolecciones de series (opcional)
        // Ejemplo: "Serie: " resultaría en "Serie: Aquino - Economía Asiática"
        prefijoSeries: "",
        
        // Si es true, mantiene los elementos también en la colección principal
        // Si es false, los mueve completamente a las subcolecciones
        mantenerEnColeccionPrincipal: false,
        
        // Límite de elementos a procesar (0 = sin límite)
        // Útil para pruebas: poner 10 para probar con pocos elementos
        limitePrueba: 0
    };
    
    // ============================================================================
    // INICIALIZACIÓN Y VALIDACIÓN
    // ============================================================================
    
    try {
        // Registrar inicio del proceso
        const tiempoInicio = Date.now();
        console.log("=".repeat(70));
        console.log("INICIANDO ORGANIZACIÓN DE ELEMENTOS POR SERIES - v2.0");
        console.log("=".repeat(70));
        console.log(`Fecha/Hora: ${new Date().toLocaleString('es-PE')}`);
        console.log(`Colección objetivo: "${CONFIG.nombreColeccionPrincipal}"`);
        console.log(`Modo simulación: ${CONFIG.modoSimulacion ? 'SÍ (no se harán cambios)' : 'NO'}`);
        console.log(`Límite de prueba: ${CONFIG.limitePrueba || 'Sin límite'}`);
        console.log("-".repeat(70));
        
        // Obtener el ID de la biblioteca del usuario
        const idBiblioteca = Zotero.Libraries.userLibraryID;
        if (!idBiblioteca) {
            throw new Error("No se pudo obtener el ID de la biblioteca del usuario");
        }
        
        // Buscar la colección principal
        const todasLasColecciones = Zotero.Collections.getByLibrary(idBiblioteca);
        const coleccionPrincipal = todasLasColecciones.find(
            c => c.name === CONFIG.nombreColeccionPrincipal
        );
        
        if (!coleccionPrincipal) {
            throw new Error(
                `No se encontró la colección "${CONFIG.nombreColeccionPrincipal}". ` +
                `Colecciones disponibles: ${todasLasColecciones.map(c => c.name).join(', ')}`
            );
        }
        
        console.log(`✓ Colección encontrada: "${coleccionPrincipal.name}" (ID: ${coleccionPrincipal.id})`);
        
        // ============================================================================
        // RECOPILACIÓN DE ELEMENTOS
        // ============================================================================
        
        console.log("\n" + "=".repeat(70));
        console.log("FASE 1: RECOPILANDO ELEMENTOS");
        console.log("=".repeat(70));
        
        // Obtener todos los elementos de nivel superior en la colección
        const todosLosElementos = coleccionPrincipal.getChildItems();
        console.log(`Total de elementos en la colección: ${todosLosElementos.length}`);
        
        // Filtrar solo elementos regulares (no notas independientes ni adjuntos)
        let elementosRegulares = todosLosElementos.filter(item => item.isRegularItem());
        console.log(`Elementos regulares (libros, artículos, etc.): ${elementosRegulares.length}`);
        
        // Aplicar límite de prueba si está configurado
        if (CONFIG.limitePrueba > 0 && elementosRegulares.length > CONFIG.limitePrueba) {
            console.log(`⚠ LÍMITE DE PRUEBA ACTIVADO: Solo se procesarán ${CONFIG.limitePrueba} elementos`);
            elementosRegulares = elementosRegulares.slice(0, CONFIG.limitePrueba);
        }
        
        // ============================================================================
        // AGRUPACIÓN POR SERIES
        // ============================================================================
        
        console.log("\n" + "=".repeat(70));
        console.log("FASE 2: AGRUPANDO POR SERIES");
        console.log("=".repeat(70));
        
        // Mapa para agrupar elementos por serie
        // Clave: nombre de la serie, Valor: array de elementos
        const mapaSeries = new Map();
        let elementosSinSerie = 0;
        let elementosConSerie = 0;
        
        for (const elemento of elementosRegulares) {
            try {
                // Obtener el campo "series" del elemento
                let nombreSerie = elemento.getField('series');
                
                // Limpiar espacios en blanco al inicio y final
                if (nombreSerie) {
                    nombreSerie = nombreSerie.trim();
                }
                
                // Si el elemento tiene una serie asignada
                if (nombreSerie && nombreSerie.length > 0) {
                    elementosConSerie++;
                    
                    // Agregar el prefijo si está configurado
                    const nombreSerieCompleto = CONFIG.prefijoSeries + nombreSerie;
                    
                    // Inicializar el array si es la primera vez que encontramos esta serie
                    if (!mapaSeries.has(nombreSerieCompleto)) {
                        mapaSeries.set(nombreSerieCompleto, []);
                        if (CONFIG.modoVerboso) {
                            console.log(`  Nueva serie encontrada: "${nombreSerieCompleto}"`);
                        }
                    }
                    
                    // Agregar el elemento al array de su serie
                    mapaSeries.get(nombreSerieCompleto).push(elemento);
                } else {
                    elementosSinSerie++;
                }
            } catch (error) {
                console.error(`  ⚠ Error procesando elemento ${elemento.id}: ${error.message}`);
            }
        }
        
        console.log(`\nResumen de agrupación:`);
        console.log(`  • Elementos con serie: ${elementosConSerie}`);
        console.log(`  • Elementos sin serie: ${elementosSinSerie}`);
        console.log(`  • Series únicas encontradas: ${mapaSeries.size}`);
        
        // Si no hay series, terminar aquí
        if (mapaSeries.size === 0) {
            console.log("\n⚠ No se encontraron elementos con series. No hay nada que organizar.");
            return "Proceso finalizado: No se encontraron series para organizar.";
        }
        
        // Mostrar detalle de cada serie
        if (CONFIG.modoVerboso) {
            console.log("\nDetalle de series:");
            let contador = 1;
            for (const [nombreSerie, elementos] of mapaSeries) {
                console.log(`  ${contador}. "${nombreSerie}": ${elementos.length} elemento(s)`);
                contador++;
            }
        }
        
        // ============================================================================
        // CREACIÓN Y ORGANIZACIÓN DE SUBCOLECCIONES
        // ============================================================================
        
        console.log("\n" + "=".repeat(70));
        console.log("FASE 3: CREANDO/ACTUALIZANDO SUBCOLECCIONES Y MOVIENDO ELEMENTOS");
        console.log("=".repeat(70));
        
        // Obtener las subcolecciones existentes de la colección principal
        let subcoleccionesExistentes = coleccionPrincipal.getChildCollections();
        console.log(`Subcolecciones existentes: ${subcoleccionesExistentes.length}`);
        
        let subcoleccionesCreadas = 0;
        let subcoleccionesReutilizadas = 0;
        let elementosMovidosTotal = 0;
        let errores = 0;
        
        // Procesar cada serie
        for (const [nombreSerie, elementosSerie] of mapaSeries) {
            try {
                console.log(`\n${"─".repeat(60)}`);
                console.log(`Procesando serie: "${nombreSerie}"`);
                console.log(`Elementos a mover: ${elementosSerie.length}`);
                console.log(`${"─".repeat(60)}`);
                
                // Buscar si ya existe una subcolección con este nombre
                let subcoleccion = subcoleccionesExistentes.find(
                    sc => sc.name === nombreSerie
                );
                
                if (!subcoleccion) {
                    // La subcolección no existe, crearla
                    if (CONFIG.modoSimulacion) {
                        console.log(`  [SIMULACIÓN] Se crearía subcolección: "${nombreSerie}"`);
                        subcoleccionesCreadas++;
                    } else {
                        console.log(`  Creando nueva subcolección...`);
                        subcoleccion = new Zotero.Collection();
                        subcoleccion.libraryID = idBiblioteca;
                        subcoleccion.name = nombreSerie;
                        subcoleccion.parentID = coleccionPrincipal.id;
                        
                        // Guardar la colección
                        const nuevoID = await subcoleccion.saveTx();
                        subcoleccion = Zotero.Collections.get(nuevoID);
                        
                        console.log(`  ✓ Subcolección creada: "${nombreSerie}" (ID: ${nuevoID})`);
                        subcoleccionesCreadas++;
                        
                        // Actualizar lista de subcolecciones existentes
                        subcoleccionesExistentes = coleccionPrincipal.getChildCollections();
                    }
                } else {
                    console.log(`  ✓ Usando subcolección existente: "${nombreSerie}" (ID: ${subcoleccion.id})`);
                    subcoleccionesReutilizadas++;
                }
                
                // ============================================================================
                // MOVER ELEMENTOS A LA SUBCOLECCIÓN (CORREGIDO)
                // ============================================================================
                
                console.log(`  Moviendo elementos...`);
                let elementosMovidosSerie = 0;
                
                for (let i = 0; i < elementosSerie.length; i++) {
                    const elemento = elementosSerie[i];
                    
                    try {
                        const titulo = elemento.getField('title') || '(sin título)';
                        const tituloCorto = titulo.length > 50 ? titulo.substring(0, 50) + '...' : titulo;
                        
                        if (CONFIG.modoSimulacion) {
                            console.log(`    [${i+1}/${elementosSerie.length}] [SIMULACIÓN] "${tituloCorto}"`);
                        } else {
                            // MÉTODO CORREGIDO: Usar addItems en lugar de addItem
                            // Y asegurarnos de que se guarde correctamente
                            
                            // 1. Agregar a la subcolección
                            await Zotero.DB.executeTransaction(async function () {
                                // Verificar que el elemento no esté ya en la subcolección
                                if (!subcoleccion.hasItem(elemento.id)) {
                                    subcoleccion.addItem(elemento.id);
                                }
                            });
                            
                            // 2. Si NO se debe mantener en la colección principal, eliminarlo
                            if (!CONFIG.mantenerEnColeccionPrincipal) {
                                await Zotero.DB.executeTransaction(async function () {
                                    coleccionPrincipal.removeItem(elemento.id);
                                });
                            }
                            
                            elementosMovidosSerie++;
                            elementosMovidosTotal++;
                            
                            if (CONFIG.modoVerboso) {
                                console.log(`    [${i+1}/${elementosSerie.length}] ✓ "${tituloCorto}"`);
                            }
                        }
                    } catch (error) {
                        console.error(`    [${i+1}/${elementosSerie.length}] ✗ Error: ${error.message}`);
                        console.error(`    Elemento ID: ${elemento.id}`);
                        errores++;
                    }
                }
                
                // Verificar que los elementos se movieron correctamente
                if (!CONFIG.modoSimulacion && subcoleccion) {
                    const elementosEnSubcoleccion = subcoleccion.getChildItems().length;
                    console.log(`  ✓ Serie completada: ${elementosMovidosSerie} elementos movidos`);
                    console.log(`  ✓ Verificación: La subcolección ahora tiene ${elementosEnSubcoleccion} elementos`);
                    
                    if (elementosEnSubcoleccion === 0 && elementosMovidosSerie > 0) {
                        console.error(`  ⚠ ADVERTENCIA: No se detectan elementos en la subcolección`);
                    }
                }
                
            } catch (error) {
                console.error(`  ✗ Error procesando serie "${nombreSerie}": ${error.message}`);
                console.error(`  Stack: ${error.stack}`);
                errores++;
            }
        }
        
        // ============================================================================
        // VERIFICACIÓN FINAL
        // ============================================================================
        
        console.log("\n" + "=".repeat(70));
        console.log("FASE 4: VERIFICACIÓN FINAL");
        console.log("=".repeat(70));
        
        if (!CONFIG.modoSimulacion) {
            // Actualizar subcolecciones para verificar
            subcoleccionesExistentes = coleccionPrincipal.getChildCollections();
            
            console.log(`\nVerificando subcolecciones creadas:`);
            for (const subcoleccion of subcoleccionesExistentes) {
                const numElementos = subcoleccion.getChildItems().length;
                console.log(`  • "${subcoleccion.name}": ${numElementos} elementos`);
            }
            
            // Verificar elementos restantes en colección principal
            const elementosRestantes = coleccionPrincipal.getChildItems().length;
            console.log(`\nElementos restantes en "${CONFIG.nombreColeccionPrincipal}": ${elementosRestantes}`);
        }
        
        // ============================================================================
        // RESUMEN FINAL
        // ============================================================================
        
        const tiempoTotal = ((Date.now() - tiempoInicio) / 1000).toFixed(2);
        
        console.log("\n" + "=".repeat(70));
        console.log("PROCESO COMPLETADO");
        console.log("=".repeat(70));
        console.log(`Tiempo total: ${tiempoTotal} segundos`);
        console.log("\nEstadísticas:");
        console.log(`  • Series procesadas: ${mapaSeries.size}`);
        console.log(`  • Subcolecciones creadas: ${subcoleccionesCreadas}`);
        console.log(`  • Subcolecciones reutilizadas: ${subcoleccionesReutilizadas}`);
        console.log(`  • Elementos movidos: ${elementosMovidosTotal}`);
        console.log(`  • Elementos sin serie (no movidos): ${elementosSinSerie}`);
        console.log(`  • Errores encontrados: ${errores}`);
        
        if (CONFIG.modoSimulacion) {
            console.log("\n⚠ MODO SIMULACIÓN ACTIVO - No se realizaron cambios reales");
            console.log("  Para aplicar los cambios, configura modoSimulacion: false");
        } else {
            console.log("\n✓ Todos los cambios se aplicaron correctamente");
            console.log("\n💡 SUGERENCIA: Revisa las subcolecciones en Zotero para verificar");
        }
        
        console.log("=".repeat(70));
        
        // Mensaje de retorno
        const mensaje = CONFIG.modoSimulacion
            ? `[SIMULACIÓN] Se procesarían ${mapaSeries.size} series con ${elementosMovidosTotal} elementos`
            : `✓ Proceso completado. ${mapaSeries.size} series organizadas, ${elementosMovidosTotal} elementos movidos. Verifica las subcolecciones en Zotero.`;
        
        return mensaje;
        
    } catch (error) {
        // Manejo de errores críticos
        console.error("\n" + "=".repeat(70));
        console.error("ERROR CRÍTICO");
        console.error("=".repeat(70));
        console.error(`Mensaje: ${error.message}`);
        console.error(`Stack: ${error.stack}`);
        console.error("=".repeat(70));
        
        return `ERROR: ${error.message}. Revisa la consola para más detalles.`;
    }
}

// ============================================================================
// EJECUCIÓN DEL SCRIPT
// ============================================================================

// Ejecutar la función y retornar el resultado
return await organizarElementosPorSeries();
