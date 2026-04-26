#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# init-doc: Initialize a new document from the document-example template
# Usage: init-doc <document-name>
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: init-doc <document-name>"
  exit 1
fi

DOCUMENT_NAME="$1"
DEST="$(pwd)/${DOCUMENT_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
EXAMPLE_DIR="${PROJECT_ROOT}/document-example"

if [[ -d "${DEST}" ]]; then
  echo "Error: Directory '${DEST}' already exists."
  exit 1
fi

# ── helpers ─────────────────────────────────────────────────────────────────

ask_yn() {
  local prompt="$1" default="${2:-y}" ans
  while true; do
    if [[ "${default}" == "y" ]]; then
      read -r -p "${prompt} [Y/n]: " ans
    else
      read -r -p "${prompt} [y/N]: " ans
    fi
    ans="${ans:-${default}}"
    case "${ans,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *) echo "  Please enter y or n." ;;
    esac
  done
}

ask_value() {
  local prompt="$1" val=""
  read -r -p "${prompt}: " val || true
  echo "${val}"
}

attr_or_comment() {
  local key="$1" val="$2"
  if [[ -n "${val}" ]]; then
    echo "${key}: ${val}"
  else
    echo "// ${key}:"
  fi
}

# ── copy template ────────────────────────────────────────────────────────────

echo ""
echo "Initializing document '${DOCUMENT_NAME}'..."
mkdir -p "${DEST}"
rsync -a \
  --exclude='.DS_Store' \
  --exclude='output/' \
  --exclude='generated-images/' \
  "${EXAMPLE_DIR}/" "${DEST}/"
mkdir -p "${DEST}/output" "${DEST}/generated-images"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Document Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── doctype ──────────────────────────────────────────────────────────────────

echo "Select document type:"
echo "  1) book    — formal document with chapter numbering [default]"
echo "  2) article — simple letter or notes"
echo ""
DOCTYPE="book"
while true; do
  read -r -p "Choose [1/2]: " dt_choice
  dt_choice="${dt_choice:-1}"
  case "${dt_choice}" in
    1) DOCTYPE="book";    break ;;
    2) DOCTYPE="article"; break ;;
    *) echo "  Please enter 1 or 2." ;;
  esac
done

# ── title page ───────────────────────────────────────────────────────────────

TITLE_PAGE_ATTR=""
echo ""
if [[ "${DOCTYPE}" == "book" ]]; then
  if ! ask_yn "Include title page (cover)?" "y"; then
    TITLE_PAGE_ATTR=":notitle:"
  fi
else
  if ask_yn "Include title page (cover)?" "n"; then
    TITLE_PAGE_ATTR=":title-page:"
  fi
fi

# ── metadata ─────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Metadata  (press Enter to leave blank)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

META_PRODUCT_NAME=$(ask_value    "Product name         (document subtitle)")
META_DOCUMENT_TITLE=$(ask_value  "Document title")
META_DOCUMENT_NUMBER=$(ask_value "Document number      (e.g. AVK-XXX-XXXXXXX-0001)")
META_MODULE_NAME=$(ask_value     "Module name          (- if none)")
META_DOCUMENT_TYPE=$(ask_value   "Document type        (e.g. Design Document)")
META_PROJECT_MANAGER=$(ask_value "Project manager")
META_FINAL_EDITOR=$(ask_value    "Final editor / main author")
META_AUTHORS=$(ask_value         "Other authors        (comma-separated, or blank)")
META_VERSION=$(ask_value         "Document version     (e.g. 1.0.0, blank = omit)")
META_DATE=$(ask_value            "Release date         (YYYY-MM-DD, blank = omit)")

# ── optional sections ────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Optional Sections"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ask_yn "Include inner cover (document information page)?" "y" \
  && INCLUDE_DOC_INFO=true  || INCLUDE_DOC_INFO=false
ask_yn "Include revision history?" "y" \
  && INCLUDE_REVISION=true  || INCLUDE_REVISION=false
ask_yn "Include table of contents?" "y" \
  && INCLUDE_TOC=true       || INCLUDE_TOC=false
ask_yn "Include figure list?" "y" \
  && INCLUDE_FIGURE_LIST=true  || INCLUDE_FIGURE_LIST=false
ask_yn "Include table list?" "y" \
  && INCLUDE_TABLE_LIST=true   || INCLUDE_TABLE_LIST=false

# ── write metadata.adoc ──────────────────────────────────────────────────────

cat > "${DEST}/metadata.adoc" << EOF
// 제품 이름 (문서 소제목으로 들어감.)
$(attr_or_comment ":product-name:" "${META_PRODUCT_NAME}")

// 문서 이름 (문서 제목으로 들어감.)
$(attr_or_comment ":document-title:" "${META_DOCUMENT_TITLE}")

// 문서 번호
$(attr_or_comment ":document-number:" "${META_DOCUMENT_NUMBER}")

// 모듈 이름. 없으면 - (hyphen)
$(attr_or_comment ":module-name:" "${META_MODULE_NAME}")

// 문서 타입: Concept document, Test report, Design document 등
$(attr_or_comment ":document-type:" "${META_DOCUMENT_TYPE}")

// 프로젝트 관리자
$(attr_or_comment ":project-manager:" "${META_PROJECT_MANAGER}")

// 문서 주 편집자 혹은 주 저자
$(attr_or_comment ":final-editor:" "${META_FINAL_EDITOR}")

// 문서 저자. final editor 제외하고 작성. 별도로 없어도 주석 처리하지 말 것.
:authors: ${META_AUTHORS}

// 문서 버전. 따로 버전이 없는 경우, 모두 주석 처리 할 것.
EOF

if [[ -n "${META_VERSION}" ]]; then
  cat >> "${DEST}/metadata.adoc" << EOF
:document-version: ${META_VERSION}
:revnumber: {document-version}
EOF
else
  cat >> "${DEST}/metadata.adoc" << 'EOF'
// :document-version:
// :revnumber: {document-version}
EOF
fi

cat >> "${DEST}/metadata.adoc" << 'EOF'

// 문서 일자. 따로 문서 일자가 없는 경우, 모두 주석 처리 할 것.
EOF

if [[ -n "${META_DATE}" ]]; then
  cat >> "${DEST}/metadata.adoc" << EOF
:release-date: ${META_DATE}
:revdate: {release-date}
EOF
else
  cat >> "${DEST}/metadata.adoc" << 'EOF'
// :release-date:
// :revdate: {release-date}
EOF
fi

# ── write book.adoc ──────────────────────────────────────────────────────────

{
  echo "include::metadata.adoc[]"
  echo "include::_document_settings.adoc[]"
  echo ""
  echo ""
  echo ":doctype: ${DOCTYPE}"
  if [[ -n "${TITLE_PAGE_ATTR}" ]]; then
    echo "${TITLE_PAGE_ATTR}"
  fi
  echo ""
  echo "= {document-title}: {product-name}"
  echo ""
  echo ""

  if "${INCLUDE_DOC_INFO}"; then
    echo "// Document information (속표지)"
    echo "include::../template/pages/document_information.adoc[]"
  else
    echo "// Document information (속표지)"
    echo "// include::../template/pages/document_information.adoc[]"
  fi
  echo ""

  if "${INCLUDE_REVISION}"; then
    echo "// Revision history"
    echo "include::revision_history.adoc[]"
  else
    echo "// Revision history"
    echo "// include::revision_history.adoc[]"
  fi
  echo ""

  if "${INCLUDE_TOC}"; then
    echo "// Table of contents"
    echo "toc::[]"
  else
    echo "// Table of contents"
    echo "// toc::[]"
  fi
  echo ""

  if "${INCLUDE_FIGURE_LIST}"; then
    echo "// Figure list"
    echo "include::../template/pages/figure_list.adoc[]"
  else
    echo "// Figure list"
    echo "// include::../template/pages/figure_list.adoc[]"
  fi
  echo ""

  if "${INCLUDE_TABLE_LIST}"; then
    echo "// Table list"
    echo "include::../template/pages/table_list.adoc[]"
  else
    echo "// Table list"
    echo "// include::../template/pages/table_list.adoc[]"
  fi

  echo ""
  echo ""
  echo ""
  echo "== Chapter 1"
  echo ""
} > "${DEST}/book.adoc"

# ── cleanup ──────────────────────────────────────────────────────────────────

if ! "${INCLUDE_REVISION}"; then
  rm -f "${DEST}/revision_history.adoc"
fi

# ── done ─────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done! Document initialized."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Location : ${DEST}"
echo "  Build PDF: build-pdf ${DOCUMENT_NAME}"
echo ""
