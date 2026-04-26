#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# avikus-document-template installer
# Usage:
#   sudo ./install.sh            # install
#   sudo ./install.sh uninstall  # uninstall
# ---------------------------------------------------------------------------

PREFIX="${PREFIX:-/usr/local}"
SHARE_DIR="${PREFIX}/share/document-tools"
BIN_DIR="${PREFIX}/bin"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ─────────────────────────────────────────────────────────────────
info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
error()   { echo "[ERROR] $*" >&2; exit 1; }

check_deps() {
  local missing=()
  command -v docker   &>/dev/null || missing+=("docker")
  command -v python3  &>/dev/null || missing+=("python3")
  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing dependencies: ${missing[*]}"
  fi
  if ! docker compose version &>/dev/null; then
    error "docker compose plugin is required (docker compose v2)"
  fi
}

# ── uninstall ────────────────────────────────────────────────────────────────
uninstall() {
  info "Uninstalling avikus-document-template..."
  rm -f  "${BIN_DIR}/avk-docs"
  rm -rf "${SHARE_DIR}"
  success "Uninstalled."
}

# ── install ──────────────────────────────────────────────────────────────────
do_install() {
  [[ "$(id -u)" -eq 0 ]] || error "Run with sudo: sudo ./install.sh"

  info "Checking dependencies..."
  check_deps

  info "Installing files to ${SHARE_DIR}..."
  install -d "${SHARE_DIR}/scripts"
  install -d "${SHARE_DIR}/template"

  # Core files needed by docker compose
  install -m 644 "${SOURCE_DIR}/docker-compose.yml" "${SHARE_DIR}/docker-compose.yml"
  install -m 644 "${SOURCE_DIR}/Dockerfile"         "${SHARE_DIR}/Dockerfile"

  # Scripts
  install -m 755 "${SOURCE_DIR}/scripts/avk-docs.sh"   "${SHARE_DIR}/scripts/avk-docs.sh"
  install -m 755 "${SOURCE_DIR}/scripts/build-pdf.sh"  "${SHARE_DIR}/scripts/build-pdf.sh"
  install -m 755 "${SOURCE_DIR}/scripts/build-html.sh" "${SHARE_DIR}/scripts/build-html.sh"
  install -m 755 "${SOURCE_DIR}/scripts/serve-html.sh" "${SHARE_DIR}/scripts/serve-html.sh"
  install -m 755 "${SOURCE_DIR}/scripts/init-doc.sh"   "${SHARE_DIR}/scripts/init-doc.sh"

  # Template (fonts, theme, pages) and document-example
  cp -r "${SOURCE_DIR}/template/."          "${SHARE_DIR}/template/"
  cp -r "${SOURCE_DIR}/document-example/." "${SHARE_DIR}/document-example/"

  # Symlink: single avk-docs entry point
  info "Creating symlink in ${BIN_DIR}..."
  ln -sf "${SHARE_DIR}/scripts/avk-docs.sh" "${BIN_DIR}/avk-docs"

  # Build Docker image
  info "Building Docker image (hinas-asciidoctor)..."
  docker build -t hinas-asciidoctor "${SHARE_DIR}"

  echo ""
  success "Installation complete."
  echo ""
  echo "  Commands available:"
  echo "    avk-docs init  <document-name>"
  echo "    avk-docs build pdf  <document-name> [version]"
  echo "    avk-docs build html <document-name>"
  echo "    avk-docs serve html <document-name>"
  echo ""
  echo "  Run 'avk-docs --help' for full usage."
  echo ""
  echo "  To uninstall: sudo ./install.sh uninstall"
}

# ── entry point ──────────────────────────────────────────────────────────────
case "${1:-install}" in
  uninstall) uninstall   ;;
  install)   do_install  ;;
  *) error "Unknown command: $1. Use 'install' or 'uninstall'." ;;
esac
