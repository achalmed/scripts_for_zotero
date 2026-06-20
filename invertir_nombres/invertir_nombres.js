////////////////////////////////////////////////////////////////////////////////
// SCRIPT DE ZOTERO: INTERCAMBIO DE NOMBRES Y APELLIDOS DE AUTORES
////////////////////////////////////////////////////////////////////////////////
//
// DESCRIPCIÓN:
//   Este script intercambia los campos de nombre (firstName) y apellido
//   (lastName) de todos los creadores (autores, editores, etc.) en los ítems
//   seleccionados en Zotero. Útil cuando se importan referencias con los
//   campos invertidos.
//
// AUTOR: Edison Achalma
// FECHA: 2024
//
// USO:
//   1. Selecciona uno o más ítems en tu biblioteca de Zotero.
//   2. Ve a Herramientas → Desarrollador → Ejecutar JavaScript.
//   3. Pega este código en el editor.
//   4. Haz clic en "Run" (Ejecutar).
//   5. Verifica los cambios en los ítems.
//
// EJEMPLO:
//   ANTES:   firstName: "García"   | lastName: "Juan"
//   DESPUÉS: firstName: "Juan"     | lastName: "García"
//
// PRECAUCIONES:
//   - Este script modifica permanentemente tus ítems.
//   - Se recomienda hacer una copia de seguridad de tu biblioteca antes.
//   - Prueba primero con 1-2 ítems antes de procesar toda la biblioteca.
//   - Los cambios se guardan automáticamente en la base de datos.
//
// NOTAS:
//   - Solo procesa creadores que tengan ambos campos (nombre Y apellido).
//   - Ignora creadores que solo tienen un campo completo (ej. "nombre de
//     una sola palabra" sin separar, como instituciones).
//   - Funciona con todos los tipos de creadores (autores, editores, etc.).
//   - El proceso es asíncrono y guarda cada ítem de forma transaccional.
//
////////////////////////////////////////////////////////////////////////////////

/**
 * Función principal que ejecuta el intercambio de nombres y apellidos.
 * @returns {Promise<string>} Mensaje de resultado con estadísticas de la operación.
 */
(async function intercambiarNombresDeAutores() {

    ////////////////////////////////////////////////////////////////////////////
    // PASO 1: OBTENER ÍTEMS SELECCIONADOS
    ////////////////////////////////////////////////////////////////////////////

    // Obtiene los ítems seleccionados actualmente en el panel de Zotero
    var items = ZoteroPane.getSelectedItems();

    // Validar que hay ítems seleccionados
    if (!items || items.length === 0) {
        return "❌ ERROR: No hay ítems seleccionados. Por favor, selecciona al menos un ítem en tu biblioteca.";
    }

    // Contadores para estadísticas
    let totalItemsProcesados = 0;     // Ítems revisados en total
    let totalItemsModificados = 0;    // Ítems que sí se modificaron
    let totalCreadoresIntercambiados = 0; // Creadores cuyos nombres se intercambiaron
    let itemsConErrores = 0;          // Ítems que causaron errores

    console.log(`🔄 Iniciando proceso para ${items.length} ítem(s) seleccionado(s)...`);

    ////////////////////////////////////////////////////////////////////////////
    // PASO 2: PROCESAR CADA ÍTEM
    ////////////////////////////////////////////////////////////////////////////

    for (let item of items) {

        try {
            totalItemsProcesados++;

            // Verificar que el ítem es un tipo regular (no nota, adjunto, etc.)
            if (!item.isRegularItem()) {
                console.log(`⊘ Saltando ítem "${item.getField('title')}" (no es un ítem regular)`);
                continue;
            }

            ////////////////////////////////////////////////////////////////////
            // PASO 2.1: OBTENER CREADORES DEL ÍTEM
            ////////////////////////////////////////////////////////////////////

            // Obtiene el array de creadores (autores, editores, etc.) del ítem
            var creadores = item.getCreators();

            // Si no hay creadores, continuar con el siguiente ítem
            if (!creadores || creadores.length === 0) {
                console.log(`⊘ Ítem "${item.getField('title')}" no tiene creadores`);
                continue;
            }

            // Variable para rastrear si este ítem específico fue modificado
            var modificado = false;
            var creadoresModificadosEnItem = 0;

            ////////////////////////////////////////////////////////////////////
            // PASO 2.2: PROCESAR CADA CREADOR
            ////////////////////////////////////////////////////////////////////

            for (let creador of creadores) {

                ////////////////////////////////////////////////////////////////
                // VALIDACIÓN: Verificar que ambos campos existen
                ////////////////////////////////////////////////////////////////

                // Solo procesar si el creador tiene tanto firstName como lastName.
                // Esto evita errores con creadores que solo tienen un campo
                // (por ejemplo, nombres de instituciones registrados como un
                // solo campo "single name" en Zotero).
                if (creador.firstName && creador.lastName) {

                    // Registrar el estado ANTES del intercambio (para depuración)
                    console.log(`  📝 Antes:  "${creador.firstName}" "${creador.lastName}"`);

                    ////////////////////////////////////////////////////////////
                    // INTERCAMBIO: Cambiar firstName ↔ lastName
                    ////////////////////////////////////////////////////////////

                    // Guardar temporalmente el firstName (que contiene el apellido incorrecto)
                    let temporal = creador.firstName;

                    // Mover el lastName (nombre correcto) al campo firstName
                    creador.firstName = creador.lastName;

                    // Mover el valor temporal (apellido correcto) al campo lastName
                    creador.lastName = temporal;

                    // Registrar el estado DESPUÉS del intercambio
                    console.log(`  ✓ Después: "${creador.firstName}" "${creador.lastName}"`);

                    // Marcar que este ítem ha sido modificado
                    modificado = true;
                    creadoresModificadosEnItem++;

                } else {
                    // Log para creadores que no tienen ambos campos
                    let nombre = creador.firstName || creador.lastName || "Sin nombre";
                    console.log(`  ⊘ Saltando creador "${nombre}" (solo tiene un campo)`);
                }
            }

            ////////////////////////////////////////////////////////////////////
            // PASO 2.3: GUARDAR CAMBIOS SI SE MODIFICÓ EL ÍTEM
            ////////////////////////////////////////////////////////////////////

            if (modificado) {

                // Actualizar el array de creadores en el ítem
                item.setCreators(creadores);

                // Guardar los cambios en la base de datos de forma transaccional.
                // saveTx() asegura que los cambios se guarden correctamente.
                await item.saveTx();

                // Actualizar contadores
                totalItemsModificados++;
                totalCreadoresIntercambiados += creadoresModificadosEnItem;

                let titulo = item.getField('title') || 'Sin título';
                console.log(`✅ Ítem modificado: "${titulo}" (${creadoresModificadosEnItem} creador(es) actualizados)`);

            } else {
                let titulo = item.getField('title') || 'Sin título';
                console.log(`⊘ Ítem sin cambios: "${titulo}"`);
            }

        } catch (error) {
            // Capturar y registrar cualquier error durante el procesamiento
            itemsConErrores++;
            console.error(`❌ Error procesando ítem:`, error);
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // PASO 3: GENERAR REPORTE FINAL
    ////////////////////////////////////////////////////////////////////////////

    let mensajeResultado = `
╔════════════════════════════════════════════════════════════════╗
║  INTERCAMBIO DE NOMBRES Y APELLIDOS - RESULTADO                 ║
╚════════════════════════════════════════════════════════════════╝

✓ Proceso completado exitosamente

📊 ESTADÍSTICAS:
  • Ítems procesados:           ${totalItemsProcesados}
  • Ítems modificados:          ${totalItemsModificados}
  • Creadores intercambiados:   ${totalCreadoresIntercambiados}
  • Ítems sin cambios:          ${totalItemsProcesados - totalItemsModificados - itemsConErrores}
  • Errores encontrados:        ${itemsConErrores}

${itemsConErrores > 0 ? '⚠️  ADVERTENCIA: Algunos ítems tuvieron errores. Revisa la consola para más detalles.\n' : ''}
💡 TIP: Verifica los cambios en tus ítems. Si algo no está correcto,
   puedes deshacerlo con Ctrl+Z (Cmd+Z en Mac) o restaurar desde
   una copia de seguridad.
`;

    console.log(mensajeResultado);

    return mensajeResultado.trim();

})(); // Auto-ejecución de la función asíncrona

////////////////////////////////////////////////////////////////////////////////
// VARIANTES Y PERSONALIZACIONES OPCIONALES
////////////////////////////////////////////////////////////////////////////////

/*
 * VARIANTE 1: Solo procesar autores (ignorar editores, traductores, etc.)
 *
 * Reemplazar el loop de creadores con:
 *
 * for (let creador of creadores) {
 *     if (creador.creatorType === 'author' && creador.firstName && creador.lastName) {
 *         // ... código de intercambio
 *     }
 * }
 */

/*
 * VARIANTE 2: Agregar confirmación antes de guardar
 *
 * Después de obtener los ítems, agregar:
 *
 * let confirmar = window.confirm(
 *     `¿Deseas intercambiar nombres y apellidos en ${items.length} ítem(s)?`
 * );
 * if (!confirmar) {
 *     return "❌ Operación cancelada por el usuario";
 * }
 */

/*
 * VARIANTE 3: Solo procesar si el firstName contiene más de una palabra
 * (útil para detectar apellidos compuestos en el campo firstName)
 *
 * Reemplazar la condición con:
 *
 * if (creador.firstName && creador.lastName &&
 *     creador.firstName.split(' ').length > 1) {
 *     // ... código de intercambio
 * }
 */

/*
 * VARIANTE 4: Crear respaldo antes de modificar
 *
 * Al inicio del script, agregar:
 *
 * let respaldo = items.map(item => ({
 *     id: item.id,
 *     creadores: item.getCreators()
 * }));
 * console.log('Respaldo creado:', respaldo);
 */

////////////////////////////////////////////////////////////////////////////////
// SOLUCIÓN DE PROBLEMAS (TROUBLESHOOTING)
////////////////////////////////////////////////////////////////////////////////

/*
 * PROBLEMA: "ZoteroPane is not defined"
 * SOLUCIÓN: Asegúrate de ejecutar el script en Zotero Desktop, no en el navegador.
 *
 * PROBLEMA: "Cannot read property 'length' of null"
 * SOLUCIÓN: Selecciona al menos un ítem antes de ejecutar el script.
 *
 * PROBLEMA: Los cambios no se guardan
 * SOLUCIÓN: Verifica que tienes permisos de escritura en tu biblioteca.
 *
 * PROBLEMA: Script muy lento con muchos ítems
 * SOLUCIÓN: Procesa los ítems en lotes más pequeños (100-500 a la vez),
 * seleccionando menos ítems a la vez en lugar de toda la biblioteca.
 *
 * PROBLEMA: Se intercambiaron nombres que no debían
 * SOLUCIÓN: Usa Ctrl+Z inmediatamente o restaura desde copia de seguridad.
 */

////////////////////////////////////////////////////////////////////////////////
// MEJORAS FUTURAS SUGERIDAS
////////////////////////////////////////////////////////////////////////////////

/*
 * 1. Agregar opción para solo previsualizar sin guardar.
 * 2. Implementar detección inteligente de nombres/apellidos.
 * 3. Agregar soporte para sufijos (Jr., Sr., III, etc.).
 * 4. Crear interfaz gráfica con botones de confirmación.
 * 5. Exportar reporte de cambios a CSV.
 * 6. Agregar opción de deshacer cambios desde el mismo script.
 * 7. Implementar procesamiento por lotes con barra de progreso.
 */