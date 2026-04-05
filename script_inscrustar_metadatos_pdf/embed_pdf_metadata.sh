#!/usr/bin/env bash
# =============================================================================
# embed_pdf_metadata.sh — v8.0
# Incrusta metadatos Zotero en PDFs recursivamente usando exiftool
# =============================================================================
#
# DESCRIPCIÓN:
#   Lee cada "zotero_metadata.json" generado por zotero_export_metadata.js
#   e incrusta los metadatos en el PDF de la misma carpeta.
#   Solo modifica la sección de metadatos — el contenido nunca cambia.
#
#   PDFs MALFORMADOS ("Root object not found", "file is damaged", etc.):
#   Muchos PDFs escaneados o generados por apps móviles tienen estructura
#   interna incorrecta. El script los detecta y repara automáticamente
#   antes de incrustar, usando esta cadena de estrategias (orden seguro):
#
#     1. qpdf --replace-input           (reconstrucción simple, más segura)
#     2. qpdf --linearize --replace-input (si la simple falla)
#     3. mutool clean                   (si mupdf-tools está instalado)
#     4. ghostscript -sDEVICE=pdfwrite  (regeneración agresiva)
#     5. exiftool -F                    (último recurso, no repara, solo fuerza)
#
# USO:
#   bash ~/embed_pdf_metadata.sh [OPCIONES] [CARPETA1] [CARPETA2] ...
#
# EJEMPLOS:
#   bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca
#   bash ~/embed_pdf_metadata.sh "/ruta/con espacios/Autor, Nombre"
#   bash ~/embed_pdf_metadata.sh --dry-run ~/Documents/biblioteca
#   bash ~/embed_pdf_metadata.sh --repair-only ~/Documents/biblioteca
#   bash ~/embed_pdf_metadata.sh --log ~/embed.log ~/Documents/biblioteca
#   bash ~/embed_pdf_metadata.sh --verbose \
#       "/home/achalmaedison/Documents/biblioteca/Giovanna, Aguilar Andia"
#
# OPCIONES:
#   -h, --help         Muestra esta ayuda y sale
#   -d, --dry-run      Simula sin modificar ningún PDF (modo prueba)
#   -v, --verbose      Muestra los campos a incrustar en cada PDF
#   -q, --quiet        Solo muestra el resumen final
#   -l, --log FILE     Guarda log sin colores ANSI en FILE
#   --backup           Deja <archivo>.pdf_original como copia de seguridad
#   --no-repair        No intenta reparar PDFs malformados (falla rápido)
#   --force            Usa exiftool -F en malformados (sin reparar, último recurso)
#   --repair-only      Solo repara PDFs malformados, sin tocar metadatos
#
# REQUISITOS (Arch Linux):
#   sudo pacman -S perl-image-exiftool jq qpdf
#
# OPCIONALES (para reparación de PDFs muy dañados):
#   sudo pacman -S ghostscript mupdf-tools
#
# PERMISOS:
#   Si un PDF tiene permisos -rw-r--r--, el script lo hace temporalmente
#   escribible, incrusta los metadatos y restaura los permisos originales.
#
# LOCALE PERL:
#   Si ves "perl: warning: Setting locale failed", este script lo suprime
#   automáticamente. Para solución permanente:
#     sudo locale-gen es_PE.UTF-8
#     echo 'export LC_ALL=en_US.UTF-8' >> ~/.bashrc
#
# =============================================================================

# ── Fix de locale para perl/exiftool ─────────────────────────────────────────
# Suprime: "perl: warning: Setting locale failed"
export PERL_BADLANG=0
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ── Modo estricto bash ────────────────────────────────────────────────────────
# -e  : salir al primer error no capturado explícitamente
# -u  : error si se referencia variable no definida
# -o pipefail : el código de salida de un pipe es el del último comando fallido
set -euo pipefail

# ── Colores ANSI (solo si stdout es una terminal interactiva) ─────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; NC=''
fi

# ── Constantes ────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="8.0"
readonly SCRIPT_NAME="$(basename "$0")"

# ── Variables de configuración (modificadas por flags CLI) ───────────────────
DRY_RUN=false      # --dry-run    : no modifica ningún PDF
VERBOSE=false      # --verbose    : muestra campos antes de incrustar
QUIET=false        # --quiet      : solo resumen final
LOG_FILE=""        # --log FILE   : ruta del archivo de log
BACKUP=false       # --backup     : deja .pdf_original
NO_REPAIR=false    # --no-repair  : no intenta reparar malformados
FORCE=false        # --force      : usa exiftool -F como último recurso
REPAIR_ONLY=false  # --repair-only: solo repara, no toca metadatos

# ── Contadores (en proceso principal, NO en subshells — por eso funcionan) ───
COUNT_OK=0         # PDFs procesados con éxito
COUNT_REPAIRED=0   # PDFs malformados que fueron reparados
COUNT_ERR=0        # PDFs con error irrecuperable
COUNT_SKIP=0       # JSONs omitidos (sin PDF, sin campos, etc.)
COUNT_TOTAL=0      # Total de JSONs encontrados
declare -a ERROR_MSGS=()    # Mensajes de error para el resumen final
declare -a REPAIRED_PDFS=() # Nombres de PDFs reparados para el resumen

# ── Herramientas de reparación disponibles (detectadas en check_dependencies) ─
QPDF_AVAILABLE=false
MUTOOL_AVAILABLE=false
GS_AVAILABLE=false

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

# ── Mostrar ayuda ─────────────────────────────────────────────────────────────
show_help() {
  awk '/^# USO:/,/^# REQUISITOS/' "$0" \
    | grep '^#' | sed 's/^# \{0,1\}//'
  exit 0
}

# ── Escribir en log (sin colores ANSI) ────────────────────────────────────────
log_write() {
  [[ -z "$LOG_FILE" ]] && return 0
  local clean
  clean=$(printf '%s' "$*" | sed 's/\x1b\[[0-9;]*m//g')
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$clean" >> "$LOG_FILE"
}

# ── Imprimir mensaje (respeta --quiet) ────────────────────────────────────────
# Uso: msg "texto con ${COLOR}colores${NC}" [force=1]
# force=1 → imprime incluso en modo --quiet (para resumen final y errores)
msg() {
  local text="$1"
  local force="${2:-0}"
  if [[ "$QUIET" == false || "$force" == "1" ]]; then
    echo -e "$text"
  fi
  log_write "$text"
}

# ── Verificar dependencias ────────────────────────────────────────────────────
check_dependencies() {
  local missing=0
  msg "${BOLD}Verificando dependencias:${NC}"

  # ---- Requeridas: exiftool y jq ------------------------------------------
  for cmd in exiftool jq; do
    if command -v "$cmd" &>/dev/null; then
      local ver=""
      [[ "$cmd" == "exiftool" ]] && ver=$(exiftool -ver 2>/dev/null | tr -d '\n')
      [[ "$cmd" == "jq"       ]] && ver=$(jq --version 2>/dev/null | tr -d '\n')
      msg "  ${GREEN}✓${NC} ${cmd} ${ver}"
    else
      msg "  ${RED}✗${NC} '${cmd}' no instalado (REQUERIDO)"
      [[ "$cmd" == "exiftool" ]] && msg "    → sudo pacman -S perl-image-exiftool"
      [[ "$cmd" == "jq"       ]] && msg "    → sudo pacman -S jq"
      ((missing++)) || true
    fi
  done

  # ---- Opcionales: herramientas de reparación de PDFs ----------------------
  msg "  ${BOLD}Herramientas de reparación (opcionales):${NC}"

  if command -v qpdf &>/dev/null; then
    QPDF_AVAILABLE=true
    local qver; qver=$(qpdf --version 2>/dev/null | head -1 | tr -d '\n')
    msg "  ${GREEN}✓${NC} qpdf  ${qver}  ${GREEN}← reparación principal${NC}"
  else
    msg "  ${YELLOW}✗${NC} qpdf  no instalado  ${YELLOW}← RECOMENDADO para reparar PDFs dañados${NC}"
    msg "    → sudo pacman -S qpdf"
  fi

  if command -v mutool &>/dev/null; then
    MUTOOL_AVAILABLE=true
    local mver; mver=$(mutool -v 2>&1 | head -1 | tr -d '\n' || echo "")
    msg "  ${GREEN}✓${NC} mutool  ${mver}"
  else
    msg "  ${YELLOW}✗${NC} mutool  no instalado  (opcional, fallback ligero)"
    msg "    → sudo pacman -S mupdf-tools"
  fi

  if command -v gs &>/dev/null; then
    GS_AVAILABLE=true
    local gsver; gsver=$(gs --version 2>/dev/null | tr -d '\n')
    msg "  ${GREEN}✓${NC} ghostscript  ${gsver}"
  else
    msg "  ${YELLOW}✗${NC} ghostscript  no instalado  (opcional, fallback agresivo)"
    msg "    → sudo pacman -S ghostscript"
  fi

  msg ""

  if [[ $missing -gt 0 ]]; then
    msg "${RED}Faltan ${missing} dependencia(s) requeridas.${NC}" "1"
    msg "Instálalas y vuelve a ejecutar el script." "1"
    exit 1
  fi
}

# =============================================================================
# FUNCIONES DE REPARACIÓN DE PDFs
# =============================================================================

# ── Detectar si un PDF está malformado ────────────────────────────────────────
#
# Método combinado (dos fuentes de diagnóstico):
#   1. exiftool: busca líneas "Warning:" sobre Root object, offsets, etc.
#   2. qpdf --check: más específico para daños de estructura interna.
#
# Retorna:
#   0  → PDF malformado (tiene warnings de estructura)
#   1  → PDF parece válido (sin warnings graves)
#   El nombre de la herramienta que detectó el daño se guarda en MALFORM_SOURCE
MALFORM_SOURCE=""
MALFORM_DETAIL=""

pdf_is_malformed() {
  local pdf="$1"
  MALFORM_SOURCE=""
  MALFORM_DETAIL=""

  # ---- Fuente 1: exiftool en modo lectura -----------------------------------
  # Busca las advertencias típicas de estructura inválida
  local exif_warn
  exif_warn=$(
    PERL_BADLANG=0 LC_ALL=en_US.UTF-8 \
    exiftool "$pdf" 2>&1 \
    | grep -i 'Warning' \
    | grep -iE 'root object|not found at offset|bad offset|corrupt|damaged' \
    || true
  )
  if [[ -n "$exif_warn" ]]; then
    MALFORM_SOURCE="exiftool"
    MALFORM_DETAIL="$(echo "$exif_warn" | head -1)"
    return 0
  fi

  # ---- Fuente 2: qpdf --check (si está disponible) -------------------------
  # qpdf es más específico y detecta más tipos de daño que exiftool:
  # - "file is damaged"
  # - "expected N 0 obj" (objetos en offset incorrecto)
  # - "stream keyword followed by carriage return only" (fin de línea inválido)
  # - "reported number of objects is not one plus highest object number"
  if [[ "$QPDF_AVAILABLE" == true ]]; then
    local qpdf_warn
    qpdf_warn=$(
      qpdf --check "$pdf" 2>&1 \
      | grep -iE 'damage|WARNING.*object|WARNING.*xref|WARNING.*offset|stream keyword' \
      || true
    )
    if echo "$qpdf_warn" | grep -qi 'damaged\|file is damaged'; then
      MALFORM_SOURCE="qpdf"
      MALFORM_DETAIL="$(echo "$qpdf_warn" | grep -i 'damaged' | head -1)"
      return 0
    fi
    # Advertencias de xref/objetos también indican daño, aunque qpdf diga "succeeded with warnings"
    if [[ -n "$qpdf_warn" ]]; then
      MALFORM_SOURCE="qpdf-warn"
      MALFORM_DETAIL="$(echo "$qpdf_warn" | head -1)"
      return 0
    fi
  fi

  return 1  # Sin señales de daño
}

# ── Verificar integridad de un PDF después de reparar ────────────────────────
# Retorna 0 si qpdf --check no reporta daño residual
# Retorna 1 si aún hay problemas (o qpdf no disponible)
pdf_check_integrity() {
  local pdf="$1"
  [[ "$QPDF_AVAILABLE" == false ]] && return 0  # Sin qpdf, asumir OK

  local check_out check_rc=0
  check_out=$(qpdf --check "$pdf" 2>&1) || check_rc=$?

  # qpdf --check sale con 0 si OK, 2 si warnings, 3+ si errores graves
  if [[ $check_rc -ge 3 ]]; then
    log_write "  POST-REPAIR CHECK FAILED (rc=${check_rc}): ${pdf}"
    log_write "  → ${check_out}"
    return 1
  fi

  # Warnings residuales: loguear pero no fallar (pueden ser inofensivos)
  if [[ $check_rc -eq 2 ]] || echo "$check_out" | grep -qi 'WARNING'; then
    log_write "  POST-REPAIR WARNINGS (posiblemente inofensivos): ${pdf}"
    log_write "  → $(echo "$check_out" | grep -i WARNING | head -3)"
  fi
  return 0
}

# ── Reparar un PDF malformado ─────────────────────────────────────────────────
#
# Cadena de estrategias en orden de menor a mayor agresividad:
#
#   Estrategia 1 — qpdf --replace-input (reconstrucción simple)
#     Reescribe el PDF sin linearizar. qpdf repara automáticamente al releer
#     y reescribir: reconstruye la tabla xref, corrige offsets, etc.
#     Es la opción más segura porque NO cambia la estructura de páginas.
#
#   Estrategia 2 — qpdf --linearize --replace-input (linearización)
#     Solo si la simple falla. Reorganiza el PDF en formato "web-optimized".
#     Más agresivo: cambia la disposición de objetos. Muy efectivo para xref
#     dañados pero hay reportes (PDFs viejos/raros) donde puede introducir
#     nuevos problemas. Se usa como fallback de qpdf.
#
#   Estrategia 3 — mutool clean (limpieza ligera de MuPDF)
#     mutool clean reescribe el PDF usando el motor de MuPDF.
#     Más ligero que ghostscript pero efectivo para PDFs moderadamente dañados.
#
#   Estrategia 4 — ghostscript -sDEVICE=pdfwrite (regeneración completa)
#     Ghostscript re-renderiza TODO el PDF y lo reescribe desde cero.
#     Muy efectivo para daños graves pero más lento y puede perder
#     metadatos embebidos, capas, formularios interactivos, etc.
#
#   Estrategia 5 — exiftool -F (force, no repara realmente)
#     Permite escribir metadatos en PDFs malformados ignorando los errores
#     de estructura. El PDF seguirá siendo técnicamente inválido, pero tendrá
#     los metadatos. Se usa SOLO si no hay otra opción.
#
# Códigos de retorno:
#   0 → PDF reparado exitosamente (ya se puede usar exiftool normal)
#   2 → Usar exiftool -F como último recurso (código especial)
#   1 → Reparación fallida, no se puede procesar
repair_pdf() {
  local pdf="$1"
  local pdf_base; pdf_base=$(basename "$pdf")
  local pdf_dir;  pdf_dir=$(dirname "$pdf")

  msg "    ${YELLOW}⚠ PDF malformado: ${MALFORM_SOURCE} detectó daño${NC}"
  [[ -n "$MALFORM_DETAIL" ]] \
    && msg "    ${YELLOW}  Detalle: $(echo "$MALFORM_DETAIL" | sed 's/.*WARNING: [^:]*: //' | head -c 100)${NC}"
  log_write "  MALFORMED (via ${MALFORM_SOURCE}): ${pdf}"
  [[ -n "$MALFORM_DETAIL" ]] && log_write "  DETAIL: ${MALFORM_DETAIL}"

  # ------------------------------------------------------------------
  # Estrategia 1: qpdf --replace-input (más segura, sin linearizar)
  # ------------------------------------------------------------------
  if [[ "$QPDF_AVAILABLE" == true ]]; then
    msg "    ${CYAN}⟳ Estrategia 1: qpdf reconstrucción simple...${NC}"
    local q1_out q1_rc=0
    q1_out=$(qpdf --replace-input "$pdf" 2>&1) || q1_rc=$?

    if [[ $q1_rc -eq 0 ]]; then
      # Verificar integridad post-reparación
      if pdf_check_integrity "$pdf"; then
        msg "    ${GREEN}✓ Reparado con qpdf (reconstrucción simple)${NC}"
        log_write "  REPAIRED (qpdf simple): ${pdf}"
        return 0
      else
        msg "    ${YELLOW}⚠ qpdf simple: reparó pero quedaron warnings, intentando siguiente...${NC}"
        log_write "  REPAIR PARTIAL (qpdf simple, integrity warnings remain): ${pdf}"
        # Continuar al siguiente método
      fi
    elif [[ $q1_rc -eq 2 ]]; then
      # Código 2 = éxito con warnings (xref reconstruida, típico en estos PDFs)
      msg "    ${GREEN}✓ Reparado con qpdf simple (con advertencias menores)${NC}"
      log_write "  REPAIRED (qpdf simple, warnings): ${pdf}"
      return 0
    else
      msg "    ${YELLOW}⚠ qpdf simple falló (rc=${q1_rc}): ${q1_out}${NC}"
      log_write "  REPAIR FAILED (qpdf simple rc=${q1_rc}): ${q1_out}"
    fi

    # ------------------------------------------------------------------
    # Estrategia 2: qpdf --linearize --replace-input (fallback de qpdf)
    # Linearizar reorganiza el PDF y reconstruye toda la estructura.
    # Más agresivo que la reconstrucción simple pero muy efectivo para
    # xref dañados, offsets incorrectos y problemas de carriage return.
    # ------------------------------------------------------------------
    msg "    ${CYAN}⟳ Estrategia 2: qpdf linearización...${NC}"
    local q2_out q2_rc=0
    q2_out=$(qpdf --linearize --replace-input "$pdf" 2>&1) || q2_rc=$?

    if [[ $q2_rc -eq 0 || $q2_rc -eq 2 ]]; then
      if pdf_check_integrity "$pdf"; then
        msg "    ${GREEN}✓ Reparado con qpdf (linearización)${NC}"
        log_write "  REPAIRED (qpdf linearize): ${pdf}"
        return 0
      else
        msg "    ${YELLOW}⚠ qpdf linearize: reparó pero con warnings residuales${NC}"
        log_write "  REPAIR PARTIAL (qpdf linearize, integrity warnings): ${pdf}"
        # Puede ser suficiente para exiftool, continuar de todas formas
        return 0
      fi
    else
      msg "    ${YELLOW}⚠ qpdf linearize falló (rc=${q2_rc}): ${q2_out}${NC}"
      log_write "  REPAIR FAILED (qpdf linearize rc=${q2_rc}): ${q2_out}"
    fi
  fi

  # ------------------------------------------------------------------
  # Estrategia 3: mutool clean (MuPDF, ligero y efectivo)
  # Reescribe el PDF usando el parser de MuPDF, que tolera más errores.
  # ------------------------------------------------------------------
  if [[ "$MUTOOL_AVAILABLE" == true ]]; then
    msg "    ${CYAN}⟳ Estrategia 3: mutool clean...${NC}"
    local tmp_mut; tmp_mut="${pdf_dir}/.mutool_tmp_${pdf_base}"
    local mu_out mu_rc=0
    mu_out=$(mutool clean "$pdf" "$tmp_mut" 2>&1) || mu_rc=$?

    if [[ $mu_rc -eq 0 && -f "$tmp_mut" ]]; then
      mv "$tmp_mut" "$pdf"
      msg "    ${GREEN}✓ Reparado con mutool clean${NC}"
      log_write "  REPAIRED (mutool): ${pdf}"
      return 0
    else
      rm -f "$tmp_mut"
      msg "    ${YELLOW}⚠ mutool falló (rc=${mu_rc}): ${mu_out}${NC}"
      log_write "  REPAIR FAILED (mutool rc=${mu_rc}): ${mu_out}"
    fi
  fi

  # ------------------------------------------------------------------
  # Estrategia 4: ghostscript -sDEVICE=pdfwrite (regeneración completa)
  # gs re-renderiza el PDF completo desde cero. Muy efectivo para daños
  # graves pero más lento. Usa CompatibilityLevel=1.7 para PDFs modernos.
  # ------------------------------------------------------------------
  if [[ "$GS_AVAILABLE" == true ]]; then
    msg "    ${CYAN}⟳ Estrategia 4: ghostscript regeneración completa...${NC}"
    local tmp_gs; tmp_gs="${pdf_dir}/.gs_tmp_${pdf_base}"
    local gs_out gs_rc=0
    gs_out=$(
      gs -dBATCH -dNOPAUSE -dQUIET \
         -sDEVICE=pdfwrite \
         -dCompatibilityLevel=1.7 \
         -dPDFSETTINGS=/prepress \
         -sOutputFile="$tmp_gs" \
         "$pdf" 2>&1
    ) || gs_rc=$?

    if [[ $gs_rc -eq 0 && -f "$tmp_gs" ]]; then
      mv "$tmp_gs" "$pdf"
      msg "    ${GREEN}✓ Reparado con ghostscript${NC}"
      log_write "  REPAIRED (ghostscript): ${pdf}"
      return 0
    else
      rm -f "$tmp_gs"
      msg "    ${YELLOW}⚠ ghostscript falló (rc=${gs_rc})${NC}"
      log_write "  REPAIR FAILED (ghostscript rc=${gs_rc}): ${gs_out}"
    fi
  fi

  # ------------------------------------------------------------------
  # Estrategia 5: exiftool -F (force) — ÚLTIMO RECURSO
  # No repara el PDF. Solo permite escribir metadatos ignorando errores
  # de estructura. El PDF queda técnicamente malformado pero los lectores
  # normalmente lo abren igual. Se activa si se pasó --force al script
  # o si no hay ninguna herramienta de reparación disponible.
  # ------------------------------------------------------------------
  if [[ "$FORCE" == true ]]; then
    msg "    ${YELLOW}⟳ Estrategia 5: exiftool -F (forzado, sin reparar)${NC}"
    msg "    ${YELLOW}  El PDF quedará malformado pero tendrá los metadatos${NC}"
    log_write "  FALLBACK: exiftool -F (no repaired): ${pdf}"
    return 2  # Código especial: indicar al llamador que use -F
  fi

  # Sin herramientas de reparación disponibles y sin --force
  msg "    ${RED}✗ No se pudo reparar (ninguna herramienta disponible)${NC}"
  if [[ "$QPDF_AVAILABLE" == false ]]; then
    msg "    ${YELLOW}  Instala qpdf: sudo pacman -S qpdf${NC}"
    msg "    ${YELLOW}  O usa --force para escribir de todas formas${NC}"
  fi
  log_write "  REPAIR FAILED (no tools): ${pdf}"
  return 1
}

# =============================================================================
# FUNCIÓN PRINCIPAL DE PROCESAMIENTO
# =============================================================================

# ── Procesar un zotero_metadata.json y su PDF correspondiente ─────────────────
# Flujo: leer JSON → localizar PDF → verificar permisos → (reparar si necesario)
#        → construir args exiftool → incrustar metadatos → restaurar permisos
process_one_json() {
  local json_file="$1"
  local pdf_dir; pdf_dir=$(dirname "$json_file")

  # ── Leer todos los campos del JSON ─────────────────────────────────────────
  # jq -r: salida "raw" (sin comillas JSON)
  # // ""  : valor por defecto vacío si el campo es null o no existe en el JSON
  local title abstract publisher identifier source itemtype
  local date year volume issue pages language rights series
  local place edition pdf_filename authors_str keywords_str

  title=$(        jq -r '.title        // ""' "$json_file")
  abstract=$(     jq -r '.abstract     // ""' "$json_file")
  publisher=$(    jq -r '.publisher    // ""' "$json_file")
  identifier=$(   jq -r '.identifier  // ""' "$json_file")
  source=$(       jq -r '.source       // ""' "$json_file")
  itemtype=$(     jq -r '.itemType     // ""' "$json_file")
  date=$(         jq -r '.date         // ""' "$json_file")
  year=$(         jq -r '.year         // ""' "$json_file")
  volume=$(       jq -r '.volume       // ""' "$json_file")
  issue=$(        jq -r '.issue        // ""' "$json_file")
  pages=$(        jq -r '.pages        // ""' "$json_file")
  language=$(     jq -r '.language     // ""' "$json_file")
  rights=$(       jq -r '.rights       // ""' "$json_file")
  series=$(       jq -r '.series       // ""' "$json_file")
  place=$(        jq -r '.place        // ""' "$json_file")
  edition=$(      jq -r '.edition      // ""' "$json_file")
  pdf_filename=$( jq -r '.pdf_filename // ""' "$json_file")

  # Arrays → string separado por "; "
  authors_str=$(  jq -r '(.authors // []) | join("; ")' "$json_file")
  keywords_str=$( jq -r '(.tags    // []) | join("; ")' "$json_file")

  # ── Localizar el PDF ───────────────────────────────────────────────────────
  local pdf=""

  # Intento 1: nombre exacto guardado en el JSON
  if [[ -n "$pdf_filename" && -f "${pdf_dir}/${pdf_filename}" ]]; then
    pdf="${pdf_dir}/${pdf_filename}"
  else
    # Intento 2: cualquier PDF en la misma carpeta (fallback por si fue renombrado)
    local found
    found=$(find "$pdf_dir" -maxdepth 1 -name "*.pdf" -type f 2>/dev/null \
            | sort | head -1)
    if [[ -n "$found" ]]; then
      pdf="$found"
      msg "    ${YELLOW}⚠ PDF encontrado por fallback: $(basename "$pdf")${NC}"
      log_write "  FALLBACK PDF: ${pdf}"
    fi
  fi

  # Sin PDF → omitir
  if [[ -z "$pdf" ]]; then
    msg "  ${YELLOW}⏭  Sin PDF — omitiendo: $(basename "$pdf_dir")${NC}"
    log_write "SKIP (no PDF): ${pdf_dir}"
    ((COUNT_SKIP++)) || true
    return 0
  fi

  # ── Verificar permisos ─────────────────────────────────────────────────────
  if [[ ! -r "$pdf" ]]; then
    local em="Sin permiso de lectura: $(basename "$pdf")"
    msg "  ${RED}❌ ${em}${NC}"
    log_write "ERROR (no-read): ${pdf}"
    ERROR_MSGS+=("$em")
    ((COUNT_ERR++)) || true
    return 0
  fi

  # Si el PDF es de solo lectura, hacerlo temporalmente escribible
  local original_perms=""
  local made_writable=false
  if [[ ! -w "$pdf" ]]; then
    original_perms=$(stat -c '%a' "$pdf" 2>/dev/null || echo "")
    if chmod u+w "$pdf" 2>/dev/null; then
      made_writable=true
      msg "    ${YELLOW}⚠ Permisos ampliados temporalmente (original: ${original_perms})${NC}"
    else
      local em="Sin permiso de escritura: $(basename "$pdf")"
      msg "  ${RED}❌ ${em}${NC}"
      log_write "ERROR (no-write): ${pdf}"
      ERROR_MSGS+=("$em")
      ((COUNT_ERR++)) || true
      return 0
    fi
  fi

  # ── Título para pantalla ───────────────────────────────────────────────────
  local disp="${title:0:65}"
  [[ ${#title} -gt 65 ]] && disp="${disp}…"
  [[ -z "$disp" ]]       && disp="(sin título)"
  msg "  ${BLUE}▶${NC} ${disp}"
  msg "    ${CYAN}$(basename "$pdf")${NC}"

  # ── Modo verbose: mostrar campos antes de incrustar ────────────────────────
  if [[ "$VERBOSE" == true ]]; then
    msg "    ${BOLD}Campos a incrustar:${NC}"
    [[ -n "$title"        ]] && msg "      title      : ${title}"
    [[ -n "$authors_str"  ]] && msg "      authors    : ${authors_str}"
    [[ -n "$keywords_str" ]] && msg "      keywords   : ${keywords_str}"
    [[ -n "$publisher"    ]] && msg "      publisher  : ${publisher}"
    [[ -n "$date"         ]] && msg "      date       : ${date}"
    [[ -n "$language"     ]] && msg "      language   : ${language}"
    [[ -n "$series"       ]] && msg "      series     : ${series}"
    [[ -n "$itemtype"     ]] && msg "      type       : ${itemtype}"
    [[ -n "$identifier"   ]] && msg "      identifier : ${identifier}"
  fi

  # ── Modo dry-run ───────────────────────────────────────────────────────────
  if [[ "$DRY_RUN" == true ]]; then
    msg "    ${YELLOW}[DRY-RUN] No se modifica el PDF${NC}"
    log_write "DRY-RUN: ${pdf}"
    [[ "$made_writable" == true && -n "$original_perms" ]] \
      && chmod "$original_perms" "$pdf" 2>/dev/null || true
    ((COUNT_OK++)) || true
    return 0
  fi

  # ── Detección de malformados y reparación ──────────────────────────────────
  # Se realiza ANTES de construir los args de exiftool para no hacer trabajo
  # innecesario si el PDF no se puede reparar.
  local use_force_flag=false

  if [[ "$NO_REPAIR" == false ]] && pdf_is_malformed "$pdf"; then
    local repair_rc=0
    repair_pdf "$pdf" || repair_rc=$?

    case $repair_rc in
      0)
        # Reparación exitosa: el PDF ya es válido, exiftool normal
        REPAIRED_PDFS+=("$(basename "$pdf")")
        ((COUNT_REPAIRED++)) || true
        ;;
      2)
        # Último recurso: usar exiftool -F
        use_force_flag=true
        ;;
      1)
        # Irrecuperable
        local em="PDF malformado irrecuperable: $(basename "$pdf")"
        msg "    ${RED}❌ ${em}${NC}"
        log_write "ERROR (unrepaired): ${pdf}"
        ERROR_MSGS+=("${em} — sudo pacman -S qpdf")
        [[ "$made_writable" == true && -n "$original_perms" ]] \
          && chmod "$original_perms" "$pdf" 2>/dev/null || true
        ((COUNT_ERR++)) || true
        return 0
        ;;
    esac
  fi

  # ── Modo --repair-only: no incrustar metadatos ─────────────────────────────
  if [[ "$REPAIR_ONLY" == true ]]; then
    msg "    ${CYAN}[REPAIR-ONLY] Reparación completada, sin incrustar metadatos${NC}"
    [[ "$made_writable" == true && -n "$original_perms" ]] \
      && chmod "$original_perms" "$pdf" 2>/dev/null || true
    ((COUNT_OK++)) || true
    return 0
  fi

  # ── Construir argumentos para exiftool ────────────────────────────────────
  # Array bash: cada elemento = un argumento. Maneja espacios, comas,
  # acentos y caracteres especiales en los valores de metadatos.
  local -a args=()

  # --- Grupo A: PDF InfoDict (básico, universal en todos los lectores) ------
  [[ -n "$title"        ]] && args+=("-Title=${title}")
  [[ -n "$authors_str"  ]] && args+=("-Author=${authors_str}")
  [[ -n "$keywords_str" ]] && args+=("-Keywords=${keywords_str}")
  [[ -n "$publisher"    ]] && args+=("-Publisher=${publisher}")
  [[ -n "$identifier"   ]] && args+=("-Identifier=${identifier}")
  [[ -n "$itemtype"     ]] && args+=("-Type=${itemtype}")
  [[ -n "$language"     ]] && args+=("-Language=${language}")
  [[ -n "$rights"       ]] && args+=("-Rights=${rights}")
  [[ -n "$source"       ]] && args+=("-Source=${source}")
  if [[ -n "$abstract" ]]; then
    args+=("-Description=${abstract}")
    args+=("-Subject=${abstract}")
  fi

  # Fecha: normalizar a formato exiftool YYYY:MM:DD HH:MM:SS
  if [[ -n "$date" ]]; then
    local exif_date="$date"
    if [[ "$date" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2}) ]]; then
      exif_date="${BASH_REMATCH[1]}:${BASH_REMATCH[2]}:${BASH_REMATCH[3]} 00:00:00"
    elif [[ "$date" =~ ^[0-9]{4}$ ]]; then
      exif_date="${date}:01:01 00:00:00"
    fi
    args+=("-CreateDate=${exif_date}")
    args+=("-ModifyDate=${exif_date}")
  fi

  # --- Grupo B: XMP Dublin Core (XMP-dc) — estándar moderno, Calibre-compatible
  [[ -n "$title"        ]] && args+=("-XMP-dc:Title=${title}")
  [[ -n "$authors_str"  ]] && args+=("-XMP-dc:Creator=${authors_str}")
  [[ -n "$abstract"     ]] && args+=("-XMP-dc:Description=${abstract}")
  [[ -n "$keywords_str" ]] && args+=("-XMP-dc:Subject=${keywords_str}")
  [[ -n "$publisher"    ]] && args+=("-XMP-dc:Publisher=${publisher}")
  [[ -n "$itemtype"     ]] && args+=("-XMP-dc:Type=${itemtype}")
  [[ -n "$language"     ]] && args+=("-XMP-dc:Language=${language}")
  [[ -n "$rights"       ]] && args+=("-XMP-dc:Rights=${rights}")
  [[ -n "$identifier"   ]] && args+=("-XMP-dc:Identifier=${identifier}")
  [[ -n "$source"       ]] && args+=("-XMP-dc:Source=${source}")
  [[ -n "$year"         ]] && args+=("-XMP-dc:Date=${year}")

  # --- Grupo C: XMP PRISM (revistas y publicaciones académicas) --------------
  [[ -n "$volume"  ]] && args+=("-XMP-prism:Volume=${volume}")
  [[ -n "$issue"   ]] && args+=("-XMP-prism:Number=${issue}")
  [[ -n "$pages"   ]] && args+=("-XMP-prism:StartingPage=${pages}")
  [[ -n "$series"  ]] && args+=("-XMP-prism:IsPartOf=${series}")
  [[ -n "$edition" ]] && args+=("-XMP-prism:Edition=${edition}")

  # Sin campos → omitir
  if [[ ${#args[@]} -eq 0 ]]; then
    msg "    ${YELLOW}⏭  Sin campos válidos en el JSON${NC}"
    log_write "SKIP (empty fields): ${json_file}"
    [[ "$made_writable" == true && -n "$original_perms" ]] \
      && chmod "$original_perms" "$pdf" 2>/dev/null || true
    ((COUNT_SKIP++)) || true
    return 0
  fi

  # ── Ejecutar exiftool ──────────────────────────────────────────────────────
  # -overwrite_original: reemplaza el PDF in-place (sin .pdf_original backup)
  #   exiftool crea internamente un archivo temporal y lo renombra atómicamente.
  #   El PDF nunca queda en estado inconsistente durante la operación.
  # -F (--fix_base): fuerza escritura ignorando errores de estructura interna.
  #   Solo se usa si repair_pdf() retornó código 2 (último recurso).
  local overwrite_flag="-overwrite_original"
  [[ "$BACKUP" == true ]] && overwrite_flag=""

  local force_flag=""
  [[ "$use_force_flag" == true ]] && force_flag="-F"

  local exif_out exif_rc=0
  exif_out=$(
    PERL_BADLANG=0 LC_ALL=en_US.UTF-8 \
    exiftool \
      $force_flag \
      "${args[@]}" \
      $overwrite_flag \
      "$pdf" \
      2>&1
  ) || exif_rc=$?

  # ── Evaluar resultado ──────────────────────────────────────────────────────
  if [[ $exif_rc -eq 0 ]]; then
    if [[ "$use_force_flag" == true ]]; then
      msg "    ${GREEN}✅ OK${NC} ${YELLOW}(forzado -F, PDF conserva estructura malformada)${NC}"
      log_write "OK (forced -F): ${pdf}"
    else
      msg "    ${GREEN}✅ OK${NC}"
      log_write "OK: ${pdf}"
    fi
    ((COUNT_OK++)) || true
  else
    local em="rc=${exif_rc} | $(basename "$pdf") | ${exif_out}"
    msg "    ${RED}❌ Error: ${exif_out}${NC}"
    log_write "ERROR (exiftool rc=${exif_rc}): ${pdf}"
    log_write "  → ${exif_out}"
    ERROR_MSGS+=("$em")
    ((COUNT_ERR++)) || true
  fi

  # ── Restaurar permisos originales ──────────────────────────────────────────
  [[ "$made_writable" == true && -n "$original_perms" ]] \
    && chmod "$original_perms" "$pdf" 2>/dev/null || true

  return 0
}

# =============================================================================
# PARSEO DE ARGUMENTOS Y MAIN
# =============================================================================

parse_args() {
  declare -ga SEARCH_DIRS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)        show_help ;;
      -d|--dry-run)     DRY_RUN=true;     shift ;;
      -v|--verbose)     VERBOSE=true;     shift ;;
      -q|--quiet)       QUIET=true;       shift ;;
      --backup)         BACKUP=true;      shift ;;
      --no-repair)      NO_REPAIR=true;   shift ;;
      --force)          FORCE=true;       shift ;;
      --repair-only)    REPAIR_ONLY=true; shift ;;
      -l|--log)
        [[ -z "${2:-}" ]] && { echo "Error: --log requiere nombre de archivo"; exit 1; }
        LOG_FILE="$2"; shift 2 ;;
      -*)
        echo "Opción desconocida: $1  (usa --help)"; exit 1 ;;
      *)
        if [[ -d "$1" ]]; then
          SEARCH_DIRS+=("$1")
        else
          echo -e "${YELLOW}⚠ Carpeta no existe, se omite: $1${NC}"
        fi
        shift ;;
    esac
  done
  # Sin carpetas → usar directorio actual
  if [[ ${#SEARCH_DIRS[@]} -eq 0 ]]; then
    SEARCH_DIRS=("$(pwd)")
    msg "${YELLOW}⚠  Sin carpeta especificada → usando directorio actual:${NC}"
    msg "   ${CYAN}$(pwd)${NC}\n"
  fi
}

main() {
  parse_args "$@"

  # Inicializar log
  if [[ -n "$LOG_FILE" ]]; then
    printf '=== %s v%s — %s ===\n' "$SCRIPT_NAME" "$SCRIPT_VERSION" "$(date)" \
      > "$LOG_FILE"
    printf 'Carpetas: %s\n\n' "${SEARCH_DIRS[*]}" >> "$LOG_FILE"
  fi

  # ── Encabezado ─────────────────────────────────────────────────────────────
  msg ""
  msg "${BOLD}${CYAN}=================================================${NC}"
  msg "${BOLD}${CYAN}  Zotero → Incrustar Metadatos en PDFs v${SCRIPT_VERSION}${NC}"
  msg "${BOLD}${CYAN}=================================================${NC}"
  msg ""
  [[ "$DRY_RUN"     == true ]] && msg "${YELLOW}  MODO DRY-RUN: no se modifica ningún PDF${NC}\n"
  [[ "$REPAIR_ONLY" == true ]] && msg "${CYAN}  MODO REPAIR-ONLY: solo repara, sin metadatos${NC}\n"
  [[ "$BACKUP"      == true ]] && msg "${YELLOW}  MODO BACKUP: deja .pdf_original${NC}\n"
  [[ "$NO_REPAIR"   == true ]] && msg "${YELLOW}  MODO NO-REPAIR: no repara malformados${NC}\n"
  [[ "$FORCE"       == true ]] && msg "${YELLOW}  MODO FORCE: exiftool -F en malformados${NC}\n"
  [[ -n "$LOG_FILE"         ]] && msg "${CYAN}  Log: ${LOG_FILE}${NC}\n"

  check_dependencies

  msg "${BOLD}Carpetas a procesar:${NC}"
  for d in "${SEARCH_DIRS[@]}"; do msg "  📁 ${CYAN}${d}${NC}"; done
  msg ""

  # ── Recolectar JSONs (manejo seguro de nombres con espacios/comas) ─────────
  # find -print0 + read -d $'\0': el único método que maneja correctamente
  # cualquier carácter en nombres de archivo, incluyendo espacios, comas,
  # paréntesis, acentos y caracteres especiales del español.
  local -a json_files=()
  for dir in "${SEARCH_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
      msg "${RED}❌ No existe: ${dir}${NC}"; continue
    fi
    while IFS= read -r -d $'\0' f; do
      json_files+=("$f")
    done < <(find "$dir" -name "zotero_metadata.json" -type f -print0 2>/dev/null \
             | sort -z)
  done

  COUNT_TOTAL=${#json_files[@]}

  if [[ $COUNT_TOTAL -eq 0 ]]; then
    msg "${YELLOW}⚠  No se encontró ningún 'zotero_metadata.json'.${NC}" "1"
    msg "" "1"
    msg "  Pasos para generarlos:" "1"
    msg "    1. Abre Zotero" "1"
    msg "    2. Selecciona los ítems (Ctrl+A)" "1"
    msg "    3. Herramientas → Ejecutar JavaScript" "1"
    msg "    4. Pega y ejecuta: zotero_export_metadata.js" "1"
    msg "    5. Vuelve a ejecutar este script" "1"
    msg "" "1"
    msg "  Diagnóstico:" "1"
    msg "    find '${SEARCH_DIRS[0]}' -name 'zotero_metadata.json' | head -5" "1"
    exit 0
  fi

  msg "${BOLD}JSON encontrados: ${COUNT_TOTAL}${NC}"
  msg ""

  # ── Bucle principal ────────────────────────────────────────────────────────
  # process_one_json se llama en el proceso actual (no en subshell):
  # los contadores COUNT_OK/ERR/SKIP/REPAIRED se actualizan correctamente.
  local idx=0
  for json_file in "${json_files[@]}"; do
    ((idx++)) || true

    # Progreso: siempre si ≤30 archivos, o cada 25, o en el último
    if (( COUNT_TOTAL <= 30 )) \
       || (( idx % 25 == 1 )) \
       || (( idx == COUNT_TOTAL )); then
      local pdir
      pdir=$(dirname "$json_file" | xargs basename 2>/dev/null || echo "?")
      msg "${BOLD}[${idx}/${COUNT_TOTAL}]${NC} ${pdir}"
    fi

    process_one_json "$json_file"
  done

  # ── Resumen final ──────────────────────────────────────────────────────────
  msg ""
  msg "${BOLD}${CYAN}=================================================${NC}" "1"
  msg "${BOLD}  RESULTADO FINAL${NC}" "1"
  msg "${BOLD}${CYAN}=================================================${NC}" "1"
  msg "  JSONs encontrados        : ${COUNT_TOTAL}" "1"
  msg "  ${GREEN}✅ PDFs OK               : ${COUNT_OK}${NC}" "1"
  if [[ $COUNT_REPAIRED -gt 0 ]]; then
    msg "  ${CYAN}⟳  PDFs reparados        : ${COUNT_REPAIRED}${NC}" "1"
  fi
  msg "  ${YELLOW}⏭  Omitidos              : ${COUNT_SKIP}${NC}" "1"
  msg "  ${RED}❌ Errores               : ${COUNT_ERR}${NC}" "1"
  msg "${BOLD}${CYAN}=================================================${NC}" "1"
  msg ""

  # PDFs reparados: listar
  if [[ ${#REPAIRED_PDFS[@]} -gt 0 && "$QUIET" == false ]]; then
    msg "${CYAN}PDFs reparados automáticamente:${NC}"
    for rp in "${REPAIRED_PDFS[@]}"; do msg "  ⟳ ${rp}"; done
    msg ""
  fi

  # Errores: listar con detalle
  if [[ ${#ERROR_MSGS[@]} -gt 0 ]]; then
    msg "${RED}Detalle de errores:${NC}" "1"
    for e in "${ERROR_MSGS[@]}"; do msg "  • ${e}" "1"; done
    msg ""
    msg "${BOLD}Soluciones:${NC}" "1"
    msg "  'Root object not found'  → sudo pacman -S qpdf" "1"
    msg "  'file is damaged'        → sudo pacman -S qpdf" "1"
    msg "  Sin qpdf disponible      → bash $SCRIPT_NAME --force ..." "1"
    msg "  'File is encrypted'      → PDF con contraseña, no modificable" "1"
    msg "  'Permission denied'      → chmod u+w <archivo.pdf>" "1"
    msg ""
  fi

  # Comandos de verificación
  if [[ $COUNT_OK -gt 0 && "$QUIET" == false ]]; then
    msg "${BOLD}Verificar metadatos incrustados:${NC}"
    msg "  exiftool -Title -Author -Keywords -XMP-dc:Creator <archivo.pdf>"
    msg "  exiftool -XMP:all <archivo.pdf>    # todos los campos XMP"
    msg "  exiftool -PDF:all <archivo.pdf>    # diccionario InfoDict"
    msg "  qpdf --check <archivo.pdf>         # verificar integridad del PDF"
    msg ""
  fi

  [[ -n "$LOG_FILE" ]] && msg "📋 Log: ${LOG_FILE}" "1"
  msg ""
}

main "$@"