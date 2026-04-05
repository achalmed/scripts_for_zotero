#!/usr/bin/env bash
# =============================================================================
# embed_pdf_metadata.sh — v6.0
# Incrusta metadatos Zotero en PDFs de forma recursiva usando exiftool
# =============================================================================
#
# DESCRIPCIÓN:
#   Lee cada archivo "zotero_metadata.json" generado por el script de Zotero
#   (zotero_export_metadata.js) y usa exiftool para incrustar los metadatos
#   directamente en el PDF que está en la misma carpeta.
#   Solo toca los metadatos del PDF — el contenido (páginas, texto, imágenes)
#   nunca se modifica.
#
# USO:
#   bash ~/embed_pdf_metadata.sh                          # carpeta actual
#   bash ~/embed_pdf_metadata.sh /ruta/a/biblioteca       # toda la biblioteca
#   bash ~/embed_pdf_metadata.sh /ruta/autor1 /ruta/autor2  # varias carpetas
#
# EJEMPLOS REALES:
#   bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca
#   bash ~/embed_pdf_metadata.sh \
#     "/home/achalmaedison/Documents/biblioteca/Yulino, Anastacio Clemente"
#   bash ~/embed_pdf_metadata.sh \
#     "/home/achalmaedison/Documents/biblioteca/Zenon, Quispe Misaico" \
#     "/home/achalmaedison/Documents/biblioteca/Zaida, Quiroz Cornejo"
#
# REQUISITOS (Arch Linux):
#   sudo pacman -S perl-image-exiftool jq
#
# OPCIONES:
#   -h, --help      Muestra esta ayuda
#   -d, --dry-run   Simula sin modificar PDFs (muestra qué haría)
#   -v, --verbose   Muestra todos los campos que se van a incrustar
#   -q, --quiet     Solo muestra el resumen final
#   -l, --log FILE  Guarda log detallado en el archivo indicado
#   --backup        Deja archivos .pdf_original como respaldo
#
# SEGURIDAD:
#   Por defecto usa -overwrite_original: exiftool reemplaza el archivo
#   atómicamente (crea un temp, lo renombra). El contenido del PDF nunca
#   se toca, solo la sección de metadatos XMP/InfoDict.
#   Con --backup: deja <archivo>.pdf_original como copia de seguridad.
#
# LOCALE:
#   Si ves "perl: warning: Setting locale failed", este script lo corrige
#   automáticamente seteando PERL_BADLANG=0 y LANG=en_US.UTF-8.
#
# =============================================================================

# ── Fix de locale para perl/exiftool ─────────────────────────────────────────
# Evita: "perl: warning: Setting locale failed"
export PERL_BADLANG=0
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ── Modo estricto ─────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colores ANSI ──────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m';  BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; NC=''
fi

# ── Variables globales ────────────────────────────────────────────────────────
SCRIPT_VERSION="6.0"
DRY_RUN=false
VERBOSE=false
QUIET=false
LOG_FILE=""
BACKUP=false

# Contadores en el proceso principal (NO en subshells — por eso funciona)
COUNT_OK=0
COUNT_ERR=0
COUNT_SKIP=0
COUNT_TOTAL=0
declare -a ERROR_MSGS=()

# ── Ayuda ─────────────────────────────────────────────────────────────────────
show_help() {
  grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,1\}//'
  exit 0
}

# ── Log ───────────────────────────────────────────────────────────────────────
log_write() {
  [[ -z "$LOG_FILE" ]] && return
  local clean
  clean=$(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$clean" >> "$LOG_FILE"
}

# ── msg: imprimir + log ───────────────────────────────────────────────────────
# Uso: msg "texto" [force=1]
# force=1 imprime incluso en modo --quiet
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
  for cmd in exiftool jq; do
    if command -v "$cmd" &>/dev/null; then
      local ver=""
      [[ "$cmd" == "exiftool" ]] && ver=$(exiftool -ver 2>/dev/null | tr -d '\n')
      [[ "$cmd" == "jq" ]]       && ver=$(jq --version 2>/dev/null | tr -d '\n')
      msg "  ${GREEN}✓${NC} ${cmd} ${ver}"
    else
      msg "  ${RED}✗ '${cmd}' no instalado${NC}"
      [[ "$cmd" == "exiftool" ]] && msg "    → sudo pacman -S perl-image-exiftool"
      [[ "$cmd" == "jq"       ]] && msg "    → sudo pacman -S jq"
      ((missing++)) || true
    fi
  done
  if [[ $missing -gt 0 ]]; then
    msg "\n${RED}Faltan ${missing} dependencia(s). Instálalas y vuelve a ejecutar.${NC}" "1"
    exit 1
  fi
  msg ""
}

# ── Procesar un JSON ──────────────────────────────────────────────────────────
# Esta función se ejecuta en el proceso principal (no subshell),
# por eso los contadores COUNT_OK/ERR/SKIP funcionan correctamente.
process_one_json() {
  local json_file="$1"
  local pdf_dir
  pdf_dir=$(dirname "$json_file")

  # ── Leer campos del JSON ──────────────────────────────────────────────────
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
  authors_str=$(  jq -r '(.authors // []) | join("; ")' "$json_file")
  keywords_str=$( jq -r '(.tags    // []) | join("; ")' "$json_file")

  # ── Localizar el PDF ──────────────────────────────────────────────────────
  local pdf=""

  # Intento 1: nombre exacto guardado en el JSON
  if [[ -n "$pdf_filename" && -f "${pdf_dir}/${pdf_filename}" ]]; then
    pdf="${pdf_dir}/${pdf_filename}"

  # Intento 2: cualquier .pdf en la carpeta (fallback)
  else
    local found
    found=$(find "$pdf_dir" -maxdepth 1 -name "*.pdf" -type f 2>/dev/null | sort | head -1)
    if [[ -n "$found" ]]; then
      pdf="$found"
      msg "    ${YELLOW}⚠ PDF encontrado por fallback: $(basename "$pdf")${NC}"
    fi
  fi

  # Sin PDF → omitir
  if [[ -z "$pdf" ]]; then
    msg "  ${YELLOW}⏭  Sin PDF en: $(basename "$pdf_dir")${NC}"
    log_write "SKIP (no PDF): ${pdf_dir}"
    ((COUNT_SKIP++)) || true
    return 0
  fi

  # Verificar permisos
  if [[ ! -r "$pdf" || ! -w "$pdf" ]]; then
    local perm_err="Sin permisos r/w: ${pdf}"
    msg "  ${RED}❌ ${perm_err}${NC}"
    log_write "ERROR (permisos): ${pdf}"
    ERROR_MSGS+=("$perm_err")
    ((COUNT_ERR++)) || true
    return 0
  fi

  # ── Título para pantalla ──────────────────────────────────────────────────
  local disp="${title:0:65}"
  [[ ${#title} -gt 65 ]] && disp="${disp}…"
  [[ -z "$disp" ]] && disp="(sin título)"
  msg "  ${BLUE}▶${NC} ${disp}"
  msg "    ${CYAN}$(basename "$pdf")${NC}"

  # ── Verbose: mostrar campos ───────────────────────────────────────────────
  if [[ "$VERBOSE" == true ]]; then
    [[ -n "$title"        ]] && msg "    title      : ${title}"
    [[ -n "$authors_str"  ]] && msg "    authors    : ${authors_str}"
    [[ -n "$keywords_str" ]] && msg "    keywords   : ${keywords_str}"
    [[ -n "$publisher"    ]] && msg "    publisher  : ${publisher}"
    [[ -n "$date"         ]] && msg "    date       : ${date}"
    [[ -n "$language"     ]] && msg "    language   : ${language}"
    [[ -n "$series"       ]] && msg "    series     : ${series}"
    [[ -n "$identifier"   ]] && msg "    identifier : ${identifier}"
  fi

  # ── Dry-run ───────────────────────────────────────────────────────────────
  if [[ "$DRY_RUN" == true ]]; then
    msg "    ${YELLOW}[DRY-RUN] No se modifica${NC}"
    ((COUNT_OK++)) || true
    return 0
  fi

  # ── Construir argumentos para exiftool ───────────────────────────────────
  # Cada elemento del array es un argumento independiente para manejar
  # correctamente espacios, comas, caracteres especiales en los valores.
  local -a args=()

  # --- Grupo 1: PDF Info Dictionary (básico, universal) ----------------------
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

  # Fecha: convertir ISO 8601 → formato exiftool YYYY:MM:DD HH:MM:SS
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

  # --- Grupo 2: XMP Dublin Core (estándar moderno, compatible Calibre) -------
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

  # --- Grupo 3: XMP PRISM (revistas y publicaciones académicas) --------------
  [[ -n "$volume"  ]] && args+=("-XMP-prism:Volume=${volume}")
  [[ -n "$issue"   ]] && args+=("-XMP-prism:Number=${issue}")
  [[ -n "$pages"   ]] && args+=("-XMP-prism:StartingPage=${pages}")
  [[ -n "$series"  ]] && args+=("-XMP-prism:IsPartOf=${series}")
  [[ -n "$edition" ]] && args+=("-XMP-prism:Edition=${edition}")

  # Sin campos → omitir
  if [[ ${#args[@]} -eq 0 ]]; then
    msg "    ${YELLOW}⏭  JSON vacío, sin campos para incrustar${NC}"
    log_write "SKIP (empty fields): ${json_file}"
    ((COUNT_SKIP++)) || true
    return 0
  fi

  # ── Ejecutar exiftool ─────────────────────────────────────────────────────
  # -overwrite_original : sin backup (reemplazo atómico en disco)
  # Sin -q              : capturamos el output para mostrar errores
  local overwrite="-overwrite_original"
  [[ "$BACKUP" == true ]] && overwrite=""

  local out=""
  local rc=0
  out=$(exiftool "${args[@]}" $overwrite "$pdf" 2>&1) || rc=$?

  if [[ $rc -eq 0 ]]; then
    msg "    ${GREEN}✅ OK${NC}"
    log_write "OK: ${pdf}"
    ((COUNT_OK++)) || true
  else
    local errmsg="rc=${rc} | $(basename "$pdf") | ${out}"
    msg "    ${RED}❌ Error: ${out}${NC}"
    log_write "ERROR: ${pdf}"
    log_write "  → ${out}"
    ERROR_MSGS+=("$errmsg")
    ((COUNT_ERR++)) || true
  fi

  return 0
}

# ── Parsear argumentos ────────────────────────────────────────────────────────
parse_args() {
  declare -ga SEARCH_DIRS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)     show_help ;;
      -d|--dry-run)  DRY_RUN=true;  shift ;;
      -v|--verbose)  VERBOSE=true;  shift ;;
      -q|--quiet)    QUIET=true;    shift ;;
      --backup)      BACKUP=true;   shift ;;
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
  if [[ ${#SEARCH_DIRS[@]} -eq 0 ]]; then
    SEARCH_DIRS=("$(pwd)")
    msg "${YELLOW}⚠  Sin carpeta especificada → usando directorio actual:${NC}"
    msg "   ${CYAN}$(pwd)${NC}\n"
  fi
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
  parse_args "$@"

  # Inicializar log
  if [[ -n "$LOG_FILE" ]]; then
    printf '=== embed_pdf_metadata.sh v%s — %s ===\n' "$SCRIPT_VERSION" "$(date)" > "$LOG_FILE"
    printf 'Carpetas: %s\n\n' "${SEARCH_DIRS[*]}" >> "$LOG_FILE"
  fi

  # Encabezado
  msg ""
  msg "${BOLD}${CYAN}=================================================${NC}"
  msg "${BOLD}${CYAN}  Zotero → Incrustar Metadatos en PDFs v${SCRIPT_VERSION}${NC}"
  msg "${BOLD}${CYAN}=================================================${NC}"
  msg ""
  [[ "$DRY_RUN" == true ]] && msg "${YELLOW}  MODO DRY-RUN: no se modifica ningún PDF${NC}\n"
  [[ "$BACKUP"  == true ]] && msg "${YELLOW}  MODO BACKUP: deja .pdf_original${NC}\n"
  [[ -n "$LOG_FILE"     ]] && msg "${CYAN}  Log: ${LOG_FILE}${NC}\n"

  check_dependencies

  msg "${BOLD}Carpetas:${NC}"
  for d in "${SEARCH_DIRS[@]}"; do msg "  📁 ${CYAN}${d}${NC}"; done
  msg ""

  # ── Recolectar todos los JSON con find seguro (maneja espacios) ─────────
  local -a json_files=()
  for dir in "${SEARCH_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
      msg "${RED}❌ No existe: ${dir}${NC}"; continue
    fi
    # -print0 + read -d $'\0' = manejo correcto de nombres con espacios/comas
    while IFS= read -r -d $'\0' f; do
      json_files+=("$f")
    done < <(find "$dir" -name "zotero_metadata.json" -type f -print0 2>/dev/null | sort -z)
  done

  COUNT_TOTAL=${#json_files[@]}

  if [[ $COUNT_TOTAL -eq 0 ]]; then
    msg "${YELLOW}⚠  No se encontró ningún 'zotero_metadata.json'.${NC}" "1"
    msg "" "1"
    msg "  ¿Ya ejecutaste el script JS en Zotero?" "1"
    msg "  Diagnóstico:" "1"
    msg "    find '${SEARCH_DIRS[0]}' -name 'zotero_metadata.json' | head -10" "1"
    exit 0
  fi

  msg "${BOLD}JSON encontrados: ${COUNT_TOTAL}${NC}"
  msg ""

  # ── Bucle principal ────────────────────────────────────────────────────
  # process_one_json se llama en el proceso actual (no en subshell),
  # así que COUNT_OK/ERR/SKIP se actualizan correctamente.
  local idx=0
  for json_file in "${json_files[@]}"; do
    ((idx++)) || true

    # Mostrar progreso: siempre si <= 30, cada 25 si más
    if (( COUNT_TOTAL <= 30 )) || (( idx % 25 == 1 )) || (( idx == COUNT_TOTAL )); then
      msg "${BOLD}[${idx}/${COUNT_TOTAL}]${NC} $(dirname "$json_file" | xargs basename 2>/dev/null || echo '?')"
    fi

    process_one_json "$json_file"
  done

  # ── Resumen ────────────────────────────────────────────────────────────
  msg ""
  msg "${BOLD}${CYAN}=================================================${NC}" "1"
  msg "${BOLD}  RESULTADO${NC}" "1"
  msg "${BOLD}${CYAN}=================================================${NC}" "1"
  msg "  JSONs procesados : ${COUNT_TOTAL}" "1"
  msg "  ${GREEN}✅ OK             : ${COUNT_OK}${NC}" "1"
  msg "  ${YELLOW}⏭  Omitidos       : ${COUNT_SKIP}${NC}" "1"
  msg "  ${RED}❌ Errores        : ${COUNT_ERR}${NC}" "1"
  msg "${BOLD}${CYAN}=================================================${NC}" "1"
  msg ""

  # Errores detallados
  if [[ ${#ERROR_MSGS[@]} -gt 0 ]]; then
    msg "${RED}Detalle de errores:${NC}" "1"
    for e in "${ERROR_MSGS[@]}"; do msg "  • ${e}" "1"; done
    msg ""
    msg "Causas comunes:" "1"
    msg "  • PDF encriptado/con contraseña" "1"
    msg "  • Sin permiso de escritura → chmod u+w archivo.pdf" "1"
    msg "  • PDF dañado" "1"
    msg ""
  fi

  # Comandos de verificación
  if [[ $COUNT_OK -gt 0 && "$QUIET" == false ]]; then
    msg "${BOLD}Verificar un PDF:${NC}"
    msg "  exiftool -Title -Author -Keywords -Language -XMP-dc:Creator <archivo.pdf>"
    msg ""
    msg "  # Ver todos los XMP:"
    msg "  exiftool -XMP:all <archivo.pdf>"
    msg ""
  fi

  [[ -n "$LOG_FILE" ]] && msg "📋 Log: ${LOG_FILE}" "1"
}

main "$@"