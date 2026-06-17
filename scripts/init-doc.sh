#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# init-doc: Initialize a new document from one of the bundled templates
# Usage: init-doc [options] <document-title>
#
# Document templates:
#   document | letter | test-report
#
# Metadata prompts are generated from the selected template's metadata.adoc.
# The nearest comments above each attribute are used as the question text.
# ---------------------------------------------------------------------------

YES_MODE=false
TEMPLATE_TYPE=""
FLAG_DOCTYPE=""
FLAG_TITLE_PAGE=""
FLAG_DOC_INFO=""
FLAG_REVISION=""
FLAG_TOC=""
FLAG_FIGURE_LIST=""
FLAG_TABLE_LIST=""
SET_KEYS=()
SET_VALUES=()

usage() {
  cat << 'USAGE'
Usage: init-doc [options] <document-title>

The output directory is created from metadata:
  document, test-report: <document-number> <document-title>
  letter:                <issue-date> <document-title>

Options:
  -y                         Skip all interactive prompts; use template values and flags
  --template TYPE            Template type: document (default) | letter | test-report
  --type TYPE                Alias for --template
  --set TAG=VALUE            Set any metadata tag from metadata.adoc
                             Omitted template tags are ignored

Common metadata aliases:
  --product-name NAME        Sets info-product-name
  --document-no NO           Sets info-document-number
  --module-name NAME         Sets info-module-name
  --document-type TYPE       Sets info-document-type
  --project-manager NAME     Sets info-project-manager
  --final-editor NAME        Sets info-final-editor
  --authors AUTHORS          Sets info-authors
  --document-version VER     Sets info-document-version
  --release-date DATE        Sets info-issue-date
  --eut-version VER          Sets summary-eut-version
  --test-period PERIOD       Sets summary-test-period
  --place-of-testing PLACE   Sets summary-place-of-testing
  --test-specification LIST  Sets summary-f-test-specification (; separated)
  --tested-by NAMES          Sets summary-tested-by
  --authorised-by NAMES      Sets summary-authorised-by
  --authorized-by NAMES      Alias for --authorised-by
  --approved VALUE           Sets summary-approved

Document-template section options:
  --doctype TYPE             Override AsciiDoc doctype: book | article
  --title-page yes|no        Include title page
  --doc-info yes|no          Include inner cover
  --revision yes|no          Include revision history
  --toc yes|no               Include table of contents
  --figure-list yes|no       Include figure list
  --table-list yes|no        Include table list
USAGE
}

set_tag_override() {
  local key="$1" value="$2" i
  for i in "${!SET_KEYS[@]}"; do
    if [[ "${SET_KEYS[$i]}" == "${key}" ]]; then
      SET_VALUES[$i]="${value}"
      return 0
    fi
  done
  SET_KEYS+=("${key}")
  SET_VALUES+=("${value}")
}

get_tag_override() {
  local key="$1" i
  for i in "${!SET_KEYS[@]}"; do
    if [[ "${SET_KEYS[$i]}" == "${key}" ]]; then
      printf '%s' "${SET_VALUES[$i]}"
      return 0
    fi
  done
  return 1
}

has_tag_override() {
  local key="$1" i
  for i in "${!SET_KEYS[@]}"; do
    [[ "${SET_KEYS[$i]}" == "${key}" ]] && return 0
  done
  return 1
}

require_value() {
  local opt="$1" value="${2:-}"
  if [[ -z "${value}" ]]; then
    echo "Error: ${opt} requires a value." >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -y)
      YES_MODE=true
      shift
      ;;
    --template|--type)
      require_value "$1" "${2:-}"
      TEMPLATE_TYPE="$2"
      shift 2
      ;;
    --set)
      require_value "$1" "${2:-}"
      if [[ "$2" != *=* ]]; then
        echo "Error: --set expects TAG=VALUE." >&2
        exit 1
      fi
      set_tag_override "${2%%=*}" "${2#*=}"
      shift 2
      ;;
    --doctype)
      require_value "$1" "${2:-}"
      FLAG_DOCTYPE="$2"
      shift 2
      ;;
    --title-page)
      require_value "$1" "${2:-}"
      FLAG_TITLE_PAGE="$2"
      shift 2
      ;;
    --product-name)
      require_value "$1" "${2:-}"
      set_tag_override "info-product-name" "$2"
      shift 2
      ;;
    --document-no)
      require_value "$1" "${2:-}"
      set_tag_override "info-document-number" "$2"
      shift 2
      ;;
    --module-name)
      require_value "$1" "${2:-}"
      set_tag_override "info-module-name" "$2"
      shift 2
      ;;
    --document-type)
      require_value "$1" "${2:-}"
      set_tag_override "info-document-type" "$2"
      shift 2
      ;;
    --project-manager)
      require_value "$1" "${2:-}"
      set_tag_override "info-project-manager" "$2"
      shift 2
      ;;
    --final-editor)
      require_value "$1" "${2:-}"
      set_tag_override "info-final-editor" "$2"
      shift 2
      ;;
    --authors)
      require_value "$1" "${2:-}"
      set_tag_override "info-authors" "$2"
      shift 2
      ;;
    --document-version)
      require_value "$1" "${2:-}"
      set_tag_override "info-document-version" "$2"
      shift 2
      ;;
    --release-date)
      require_value "$1" "${2:-}"
      set_tag_override "info-issue-date" "$2"
      shift 2
      ;;
    --eut-version)
      require_value "$1" "${2:-}"
      set_tag_override "summary-eut-version" "$2"
      shift 2
      ;;
    --test-period)
      require_value "$1" "${2:-}"
      set_tag_override "summary-test-period" "$2"
      shift 2
      ;;
    --place-of-testing)
      require_value "$1" "${2:-}"
      set_tag_override "summary-place-of-testing" "$2"
      shift 2
      ;;
    --test-specification)
      require_value "$1" "${2:-}"
      set_tag_override "summary-f-test-specification" "$2"
      shift 2
      ;;
    --tested-by)
      require_value "$1" "${2:-}"
      set_tag_override "summary-tested-by" "$2"
      shift 2
      ;;
    --authorised-by|--authorized-by)
      require_value "$1" "${2:-}"
      set_tag_override "summary-authorised-by" "$2"
      shift 2
      ;;
    --approved)
      require_value "$1" "${2:-}"
      set_tag_override "summary-approved" "$2"
      shift 2
      ;;
    --doc-info)
      require_value "$1" "${2:-}"
      FLAG_DOC_INFO="$2"
      shift 2
      ;;
    --revision)
      require_value "$1" "${2:-}"
      FLAG_REVISION="$2"
      shift 2
      ;;
    --toc)
      require_value "$1" "${2:-}"
      FLAG_TOC="$2"
      shift 2
      ;;
    --figure-list)
      require_value "$1" "${2:-}"
      FLAG_FIGURE_LIST="$2"
      shift 2
      ;;
    --table-list)
      require_value "$1" "${2:-}"
      FLAG_TABLE_LIST="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

RAW_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

validate_template_type() {
  case "$1" in
    document|letter|test-report) return 0 ;;
    *) return 1 ;;
  esac
}

template_label() {
  case "$1" in
    document) echo "document    - formal technical document" ;;
    letter) echo "letter      - simple letter or note" ;;
    test-report) echo "test-report - formal test report" ;;
  esac
}

ask_template_type() {
  echo "Select document template:" >&2
  echo "  1) $(template_label document)" >&2
  echo "  2) $(template_label letter)" >&2
  echo "  3) $(template_label test-report)" >&2
  echo "" >&2
  while true; do
    read -r -p "Choose [1/2/3]: " choice
    choice="${choice:-1}"
    case "${choice}" in
      1) echo "document"; return 0 ;;
      2) echo "letter"; return 0 ;;
      3) echo "test-report"; return 0 ;;
      *) echo "  Please enter 1, 2, or 3." >&2 ;;
    esac
  done
}

ask_yn() {
  local prompt="$1" default="${2:-y}" ans
  while true; do
    if [[ "${default}" == "y" ]]; then
      read -r -p "${prompt} [Y/n]: " ans
    else
      read -r -p "${prompt} [y/N]: " ans
    fi
    ans="${ans:-${default}}"
    ans="$(echo "${ans}" | tr '[:upper:]' '[:lower:]')"
    case "${ans}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *) echo "  Please enter y or n." ;;
    esac
  done
}

parse_yn_flag() {
  local val
  val="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "${val}" in
    yes|y|true|1) echo "true" ;;
    no|n|false|0) echo "false" ;;
    *) echo "" ;;
  esac
}

section_flag_value() {
  local flag_name="$1" flag_val="$2" parsed
  parsed="$(parse_yn_flag "${flag_val}")"
  if [[ -z "${parsed}" ]]; then
    echo "Error: ${flag_name} must be 'yes' or 'no'." >&2
    exit 1
  fi
  echo "${parsed}"
}

strip_comment_text() {
  local text="$1"
  text="${text#//}"
  text="${text# }"
  text="${text%% }"
  printf '%s' "${text}"
}

join_comments() {
  local sep="" item result=""
  for item in "$@"; do
    [[ -z "${item}" ]] && continue
    if [[ -z "${result}" ]]; then
      result="${item}"
    else
      result="${result}; ${item}"
    fi
  done
  printf '%s' "${result}"
}

prompt_for_tag() {
  local key="$1" comments="$2"
  if [[ -n "${comments}" ]]; then
    printf '%s - %s' "${key}" "${comments}"
  else
    printf '%s' "${key}"
  fi
}

is_system_tag() {
  case "$1" in
    revnumber|revdate|summary-issue-date) return 0 ;;
    *) return 1 ;;
  esac
}

template_key() {
  printf '%s.%s' "${TEMPLATE_TYPE}" "$1"
}

is_required_metadata_tag() {
  case "$(template_key "$1")" in
    document.info-project-manager|\
    document.info-document-number|\
    document.info-document-type|\
    document.info-final-editor|\
    document.info-issue-date|\
    letter.info-authors|\
    letter.info-issue-date|\
    test-report.info-product-name|\
    test-report.info-document-number|\
    test-report.summary-eut-version|\
    test-report.summary-test-period|\
    test-report.summary-place-of-testing)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

metadata_default_value() {
  case "$(template_key "$1")" in
    document.info-module-name) printf '%s' '-' ;;
    *) printf '%s' '' ;;
  esac
}

should_comment_empty_metadata_tag() {
  case "$(template_key "$1")" in
    test-report.summary-approved) return 0 ;;
    *) return 1 ;;
  esac
}

is_omitted_metadata_tag() {
  case "$(template_key "$1")" in
    letter.info-document-number|\
    letter.info-document-type|\
    test-report.info-document-type)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_fixed_metadata_tag() {
  local key="$1" comment
  shift || true
  case "$(template_key "${key}")" in
    test-report.summary-equipment-under-test) return 0 ;;
  esac
  [[ "${TEMPLATE_TYPE}" == "letter" ]] || return 1
  for comment in "$@"; do
    case "${comment}" in
      *고정*|*fixed*|*Fixed*) return 0 ;;
    esac
  done
  return 1
}

display_tag_name() {
  local key="$1"
  key="${key#info-}"
  key="${key#summary-f-}"
  key="${key#summary-}"
  case "${key}" in
    issue-date) echo "issue-date" ;;
    *) echo "${key}" ;;
  esac
}

metadata_example_label() {
  local value="$1"
  value="${value//$'\n'/; }"
  value="$(echo "${value}" | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//')"
  [[ -n "${value}" ]] && printf ' [example: %s]' "${value}"
  return 0
}

metadata_default_label() {
  local value="$1"
  [[ -n "${value}" ]] && printf ' [default: %s]' "${value}"
  return 0
}

format_metadata_value() {
  local key="$1" value="$2" part result=""
  local -a _parts
  if [[ "${key}" == "summary-f-test-specification" && "${value}" == *";"* ]]; then
    IFS=';' read -r -a _parts <<< "${value}"
    for part in "${_parts[@]}"; do
      part="$(echo "${part}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      [[ -z "${part}" ]] && continue
      if [[ -z "${result}" ]]; then
        result="${part}"
      else
        result="${result} + \\"$'\n'"${part}"
      fi
    done
    printf '%s' "${result}"
  else
    printf '%s' "${value}"
  fi
}

compact_metadata_value() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="$(echo "${value}" | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//')"
  printf '%s' "${value}"
}

capture_metadata_value() {
  local key="$1" value="$2" commented="$3"
  [[ "${commented}" != "true" ]] || return 0
  value="$(compact_metadata_value "${value}")"
  case "${key}" in
    info-document-number) DOCUMENT_NUMBER_VALUE="${value}" ;;
    info-document-title) DOCUMENT_TITLE_VALUE="${value}" ;;
    info-issue-date|release-date) ISSUE_DATE_VALUE="${value}" ;;
  esac
}

document_directory_name() {
  local title number issue_date
  title="$(compact_metadata_value "${DOCUMENT_TITLE_VALUE:-${RAW_NAME}}")"
  number="$(compact_metadata_value "${DOCUMENT_NUMBER_VALUE:-}")"
  issue_date="$(compact_metadata_value "${ISSUE_DATE_VALUE:-}")"

  case "${TEMPLATE_TYPE}" in
    document|test-report)
      if [[ -n "${number}" ]]; then
        printf '%s %s' "${number}" "${title}"
      else
        printf '%s' "${title}"
      fi
      ;;
    letter)
      if [[ -n "${issue_date}" ]]; then
        printf '%s %s' "${issue_date}" "${title}"
      else
        printf '%s' "${title}"
      fi
      ;;
    *)
      printf '%s' "${title}"
      ;;
  esac
}

write_attr_line() {
  local outfile="$1" commented="$2" key="$3" value="$4"
  if [[ "${commented}" == "true" ]]; then
    if [[ -n "${value}" ]]; then
      printf '// :%s: %s\n' "${key}" "${value}" >> "${outfile}"
    else
      printf '// :%s:\n' "${key}" >> "${outfile}"
    fi
  else
    if [[ -n "${value}" ]]; then
      printf ':%s: %s\n' "${key}" "${value}" >> "${outfile}"
    else
      printf ':%s:\n' "${key}" >> "${outfile}"
    fi
  fi
}

read_metadata_lines() {
  local file="$1" line
  METADATA_LINES=()
  while IFS= read -r line || [[ -n "${line}" ]]; do
    METADATA_LINES+=("${line}")
  done < "${file}"
}

process_metadata() {
  local source_file="$1" dest_file="$2"
  local tmp_file line key value original_value prefix attr_tail
  local commented new_commented new_value keep_original override_value
  local comments=() comment_text prompt default_text answer
  local default_value example_text fixed_tag required_tag
  local i=0 j continuation_line

  DOCUMENT_NUMBER_VALUE=""
  DOCUMENT_TITLE_VALUE=""
  ISSUE_DATE_VALUE=""
  read_metadata_lines "${source_file}"
  tmp_file="$(mktemp "${dest_file}.XXXXXX")"
  : > "${tmp_file}"

  while [[ ${i} -lt ${#METADATA_LINES[@]} ]]; do
    line="${METADATA_LINES[$i]}"
    key=""
    value=""
    commented="false"

    if [[ "${line}" =~ ^([[:space:]]*)//[[:space:]]*:([A-Za-z0-9_-]+):(.*)$ ]]; then
      prefix="${BASH_REMATCH[1]}"
      key="${BASH_REMATCH[2]}"
      attr_tail="${BASH_REMATCH[3]}"
      commented="true"
    elif [[ "${line}" =~ ^([[:space:]]*):([A-Za-z0-9_-]+):(.*)$ ]]; then
      prefix="${BASH_REMATCH[1]}"
      key="${BASH_REMATCH[2]}"
      attr_tail="${BASH_REMATCH[3]}"
      commented="false"
    fi

    if [[ -z "${key}" ]]; then
      printf '%s\n' "${line}" >> "${tmp_file}"
      if [[ "${line}" =~ ^[[:space:]]*// ]]; then
        comment_text="$(strip_comment_text "${line}")"
        case "${comment_text}" in
          ""|------*|System\ attributes*|System\ Attributes*) ;;
          *) comments+=("${comment_text}") ;;
        esac
      else
        comments=()
      fi
      i=$((i + 1))
      continue
    fi

    value="${attr_tail# }"
    original_value="${value}"
    j=$((i + 1))
    if [[ "${line}" == *\\ ]]; then
      while [[ ${j} -lt ${#METADATA_LINES[@]} ]]; do
        continuation_line="${METADATA_LINES[$j]}"
        original_value="${original_value}"$'\n'"${continuation_line}"
        [[ "${continuation_line}" == *\\ ]] || break
        j=$((j + 1))
      done
    else
      j="${i}"
    fi

    if is_system_tag "${key}"; then
      printf '%s\n' "${line}" >> "${tmp_file}"
      while [[ ${i} -lt ${j} ]]; do
        i=$((i + 1))
        printf '%s\n' "${METADATA_LINES[$i]}" >> "${tmp_file}"
      done
      comments=()
      i=$((i + 1))
      continue
    fi

    new_value="${original_value}"
    new_commented="${commented}"
    keep_original=true
    default_value="$(metadata_default_value "${key}")"
    fixed_tag=false
    required_tag=false
    if is_omitted_metadata_tag "${key}"; then
      fixed_tag=true
    elif is_fixed_metadata_tag "${key}" "${comments[@]}"; then
      fixed_tag=true
    fi
    if is_required_metadata_tag "${key}"; then
      required_tag=true
    fi

    if [[ "${fixed_tag}" == "true" ]]; then
      if has_tag_override "${key}"; then
        echo "Warning: metadata tag '${key}' is not configurable for ${TEMPLATE_TYPE} template; ignoring override." >&2
      fi
    elif override_value="$(get_tag_override "${key}")"; then
      new_value="$(format_metadata_value "${key}" "${override_value}")"
      keep_original=false
      if [[ "${commented}" == "true" && -n "${new_value}" ]]; then
        new_commented="false"
      fi
    elif [[ "${key}" == "info-document-title" ]]; then
      new_value="${RAW_NAME}"
      keep_original=false
      if [[ "${commented}" == "true" ]]; then
        new_commented="false"
      fi
    else
      new_value="${default_value}"
      keep_original=false
      if ! "${YES_MODE}"; then
        comment_text="$(join_comments "${comments[@]}")"
        prompt="$(prompt_for_tag "$(display_tag_name "${key}")" "${comment_text}")"
        example_text="$(metadata_example_label "${original_value}")"
        default_text="$(metadata_default_label "${default_value}")"
        while true; do
          read -r -p "${prompt}${example_text}${default_text}: " answer || true
          if [[ -n "${answer}" ]]; then
            new_value="$(format_metadata_value "${key}" "${answer}")"
          else
            new_value="${default_value}"
          fi
          if [[ "${required_tag}" != "true" || -n "${new_value}" ]]; then
            break
          fi
          echo "  ${TEMPLATE_TYPE}.$(display_tag_name "${key}") is required."
        done
      fi
      if [[ "${commented}" == "true" && -n "${new_value}" ]]; then
        new_commented="false"
      fi
    fi

    if [[ "${fixed_tag}" != "true" && "${required_tag}" == "true" && -z "${new_value}" ]]; then
      echo "Error: ${TEMPLATE_TYPE}.$(display_tag_name "${key}") is required." >&2
      echo "       Provide it interactively or with --set ${key}=VALUE." >&2
      exit 1
    fi

    if [[ "${fixed_tag}" != "true" && "${key}" == "summary-f-test-specification" ]]; then
      new_value="$(format_metadata_value "${key}" "${new_value}")"
      if [[ "${commented}" == "true" && -n "${new_value}" ]]; then
        new_commented="false"
      fi
    fi

    if [[ "${fixed_tag}" != "true" && "${keep_original}" == "false" && -z "${new_value}" ]]; then
      if [[ "${commented}" == "true" ]] || should_comment_empty_metadata_tag "${key}"; then
        new_commented="true"
      else
        new_commented="false"
      fi
    fi

    [[ "${fixed_tag}" == "true" ]] && keep_original=true

    if [[ "${keep_original}" == "true" ]]; then
      printf '%s\n' "${line}" >> "${tmp_file}"
      while [[ ${i} -lt ${j} ]]; do
        i=$((i + 1))
        printf '%s\n' "${METADATA_LINES[$i]}" >> "${tmp_file}"
      done
    else
      write_attr_line "${tmp_file}" "${new_commented}" "${key}" "${new_value}"
    fi

    capture_metadata_value "${key}" "${new_value}" "${new_commented}"

    comments=()
    i=$((j + 1))
  done

  mv "${tmp_file}" "${dest_file}"
}

remove_omitted_metadata_tags() {
  local file="$1" key
  local tags=()
  case "${TEMPLATE_TYPE}" in
    letter) tags=(info-document-number info-document-type) ;;
    test-report) tags=(info-document-type) ;;
    *) return 0 ;;
  esac

  for key in "${tags[@]}"; do
    perl -0pi -e "s#^//[^\\n]*\\n[[:space:]]*:${key}:[^\\n]*\\n?##mg; s#^[[:space:]]*:${key}:[^\\n]*\\n?##mg" "${file}"
  done
}

set_doctype() {
  local file="$1" doctype="$2"
  case "${doctype}" in
    book|article) ;;
    *) echo "Error: --doctype must be 'book' or 'article'." >&2; exit 1 ;;
  esac
  perl -0pi -e "s/^:doctype: .*\$/:doctype: ${doctype}/m" "${file}"
}

set_title_page() {
  local file="$1" wanted="$2" parsed
  parsed="$(section_flag_value "--title-page" "${wanted}")"
  perl -0pi -e 's/^\s*:notitle:\n//mg; s/^\s*:title-page:\n//mg' "${file}"
  if [[ "${parsed}" == "true" ]]; then
    perl -0pi -e 's/^(:doctype: .*\n)/$1:title-page:\n/m' "${file}"
  else
    perl -0pi -e 's/^(:doctype: .*\n)/$1:notitle:\n/m' "${file}"
  fi
}

set_macro_line() {
  local file="$1" macro="$2" enabled="$3"
  if [[ "${enabled}" == "true" ]]; then
    perl -0pi -e "s#^//[[:space:]]*(${macro})#\$1#m" "${file}"
  else
    perl -0pi -e "s#^(${macro})#// \$1#m" "${file}"
  fi
}

set_include_line() {
  local file="$1" include_line="$2" enabled="$3"
  if [[ "${enabled}" == "true" ]]; then
    perl -0pi -e "s#^//[[:space:]]*(${include_line})#\$1#m" "${file}"
  else
    perl -0pi -e "s#^(${include_line})#// \$1#m" "${file}"
  fi
}

apply_document_section_options() {
  local file="$1" value

  if [[ -n "${FLAG_DOC_INFO}" ]]; then
    value="$(section_flag_value "--doc-info" "${FLAG_DOC_INFO}")"
    set_macro_line "${file}" 'doc-info-page::\[\]' "${value}"
  fi

  if [[ -n "${FLAG_REVISION}" ]]; then
    value="$(section_flag_value "--revision" "${FLAG_REVISION}")"
    set_include_line "${file}" 'include::revision_history\.adoc\[\]' "${value}"
    if [[ "${value}" != "true" ]]; then
      rm -f "${DEST}/revision_history.adoc"
    fi
  fi

  if [[ -n "${FLAG_TOC}" ]]; then
    value="$(section_flag_value "--toc" "${FLAG_TOC}")"
    set_macro_line "${file}" 'toc::\[\]' "${value}"
  fi

  if [[ -n "${FLAG_FIGURE_LIST}" ]]; then
    value="$(section_flag_value "--figure-list" "${FLAG_FIGURE_LIST}")"
    set_macro_line "${file}" 'figure-list::\[\]' "${value}"
  fi

  if [[ -n "${FLAG_TABLE_LIST}" ]]; then
    value="$(section_flag_value "--table-list" "${FLAG_TABLE_LIST}")"
    set_macro_line "${file}" 'table-list::\[\]' "${value}"
  fi
}

if ! "${YES_MODE}"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Document Setup"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

if [[ -n "${TEMPLATE_TYPE}" ]]; then
  if ! validate_template_type "${TEMPLATE_TYPE}"; then
    echo "Error: --template must be one of: document, letter, test-report." >&2
    exit 1
  fi
elif "${YES_MODE}"; then
  TEMPLATE_TYPE="document"
else
  TEMPLATE_TYPE="$(ask_template_type)"
fi

SOURCE_DIR="${PROJECT_ROOT}/${TEMPLATE_TYPE}"
if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Error: template directory not found: ${SOURCE_DIR}" >&2
  exit 1
fi
if [[ ! -f "${SOURCE_DIR}/metadata.adoc" ]]; then
  echo "Error: metadata file not found: ${SOURCE_DIR}/metadata.adoc" >&2
  exit 1
fi

if ! "${YES_MODE}"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Metadata (${TEMPLATE_TYPE})"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

PREVIEW_METADATA="$(mktemp "/tmp/avk-docs-metadata.XXXXXX")"
process_metadata "${SOURCE_DIR}/metadata.adoc" "${PREVIEW_METADATA}"
remove_omitted_metadata_tags "${PREVIEW_METADATA}"

DOCUMENT_NAME="$(document_directory_name)"
DEST="$(pwd)/${DOCUMENT_NAME}"

if [[ -d "${DEST}" ]]; then
  echo "Error: Directory '${DEST}' already exists." >&2
  rm -f "${PREVIEW_METADATA}"
  exit 1
fi

echo ""
echo "Initializing ${TEMPLATE_TYPE} '${DOCUMENT_NAME}'..."
mkdir -p "${DEST}"
rsync -a \
  --exclude='.DS_Store' \
  --exclude='output/' \
  --exclude='generated-images/' \
  "${SOURCE_DIR}/" "${DEST}/"
mkdir -p "${DEST}/output" "${DEST}/generated-images"
mv "${PREVIEW_METADATA}" "${DEST}/metadata.adoc"

if [[ -n "${FLAG_DOCTYPE}" ]]; then
  set_doctype "${DEST}/document.adoc" "${FLAG_DOCTYPE}"
  if [[ "${FLAG_DOCTYPE}" == "article" ]]; then
    perl -0pi -e 's/^:body-page-start-[^\n]*\n//mg' "${DEST}/_document_settings.adoc"
  fi
fi

if [[ -n "${FLAG_TITLE_PAGE}" ]]; then
  set_title_page "${DEST}/document.adoc" "${FLAG_TITLE_PAGE}"
fi

if [[ "${TEMPLATE_TYPE}" == "document" ]]; then
  if ! "${YES_MODE}"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Optional Sections"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [[ -z "${FLAG_DOC_INFO}" ]]; then
      ask_yn "Include inner cover (document information page)?" "y" \
        && FLAG_DOC_INFO="yes" || FLAG_DOC_INFO="no"
    fi
    if [[ -z "${FLAG_REVISION}" ]]; then
      ask_yn "Include revision history?" "y" \
        && FLAG_REVISION="yes" || FLAG_REVISION="no"
    fi
    if [[ -z "${FLAG_TOC}" ]]; then
      ask_yn "Include table of contents?" "y" \
        && FLAG_TOC="yes" || FLAG_TOC="no"
    fi
    if [[ -z "${FLAG_FIGURE_LIST}" && -z "${FLAG_TABLE_LIST}" ]]; then
      if ask_yn "Include figure and table lists?" "y"; then
        FLAG_FIGURE_LIST="yes"
        FLAG_TABLE_LIST="yes"
      else
        FLAG_FIGURE_LIST="no"
        FLAG_TABLE_LIST="no"
      fi
    elif [[ -z "${FLAG_FIGURE_LIST}" ]]; then
      ask_yn "Include figure list?" "y" \
        && FLAG_FIGURE_LIST="yes" || FLAG_FIGURE_LIST="no"
    elif [[ -z "${FLAG_TABLE_LIST}" ]]; then
      ask_yn "Include table list?" "y" \
        && FLAG_TABLE_LIST="yes" || FLAG_TABLE_LIST="no"
    fi
  fi
  apply_document_section_options "${DEST}/document.adoc"
else
  if [[ -n "${FLAG_DOC_INFO}${FLAG_REVISION}${FLAG_TOC}${FLAG_FIGURE_LIST}${FLAG_TABLE_LIST}" ]]; then
    echo "Warning: section options are only applied to the document template." >&2
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done! Document initialized."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Template : ${TEMPLATE_TYPE}"
echo "  Location : ${DEST}"
echo "  Build PDF: avk-docs build pdf \"${DOCUMENT_NAME}\""
echo ""
