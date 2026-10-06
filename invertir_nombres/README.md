---
tipo: readme
estado: retirado
---
# invertir_nombres/ — intercambio nombre ↔ apellido de los creadores en Zotero (script «Run JavaScript», retirado y peligroso)

<!-- suite:inicio -->
**Suite `invertir_nombres`** · objetivo *biblioteca* · estado *retirado* · - · interfaz cli

Intercambiaba nombre y apellido de todos los creadores de los ítems seleccionados de Zotero (script «Run JavaScript»); retirado y peligroso, no ejecutar.

- Escribe en: zotero · simula por defecto: no
- Depende de: zotero
- Nota: retirado el 2026-08-09 (auditoría, hallazgo A3): intercambio ciego de autores que rompe la comparación semántica de scripts-biblioteca/script_sincronizar_zotero (que tolera la inversión y convierte al cruzar) y dispara escrituras masivas de conflicto en el siguiente sync; se conserva como historia

Comandos:

```bash
cat invertir_nombres.js   # solo lectura: retirado y peligroso, no pegar en Zotero
```

<sub>Bloque generado desde `suite.yml` por `core/suites.py generar` (2026-10-06); no se edita a mano.</sub>
<!-- suite:fin -->

**Retirado y peligroso; no se ejecuta, ni en pruebas.** Intercambiaba a ciegas nombre y apellido de
los creadores de los ítems seleccionados. `scripts-biblioteca/script_sincronizar_zotero` compara
autores por tokens y convierte el formato al cruzar; este script rompe esa comparación y dispara
escrituras masivas de conflicto en el siguiente sync. El manual que lo acompañaba se conserva en
`../docs/historial/invertir-nombres.md`.
