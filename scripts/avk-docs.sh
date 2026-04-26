#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# avk-docs — Avikus Document CLI
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── help texts ───────────────────────────────────────────────────────────────

help_root() {
  cat << 'EOF'
avk-docs — Avikus Document CLI

USAGE
  avk-docs <command> [subcommand] [options]

COMMANDS
  init  <document-name>         Initialize a new document interactively
  build pdf <document-name> [version]
                                Build PDF from an AsciiDoc document
  build html <document-name>    Build HTML from an AsciiDoc document
  serve html <document-name>    Serve built HTML locally at http://localhost:8000

OPTIONS
  -h, --help                    Show this help message

Run 'avk-docs <command> --help' for more information on a command.
EOF
}

help_init() {
  cat << 'EOF'
avk-docs init — Initialize a new document

USAGE
  avk-docs init <document-name>

ARGUMENTS
  document-name     Name of the new document directory to create (in current directory)

DESCRIPTION
  Copies the document template into a new <document-name>/ directory and
  interactively prompts for:
    - Document type (book / article)
    - Title page inclusion
    - Metadata (title, authors, version, date, etc.)
    - Optional sections (inner cover, revision history, TOC, figure/table lists)

EXAMPLE
  cd ~/my-project
  avk-docs init my-document
EOF
}

help_build() {
  cat << 'EOF'
avk-docs build — Build a document

USAGE
  avk-docs build <format> [options]

FORMATS
  pdf   <document-name> [version]    Build PDF
  html  <document-name>              Build HTML

Run 'avk-docs build pdf --help' or 'avk-docs build html --help' for details.
EOF
}

help_build_pdf() {
  cat << 'EOF'
avk-docs build pdf — Build PDF

USAGE
  avk-docs build pdf <document-name> [version]

ARGUMENTS
  document-name     Name of the document directory (relative to current directory)
  version           (optional) Version string to append to output filename

OUTPUT
  <document-name>/output/<document-name>.pdf
  <document-name>/output/<document-name>_<version>.pdf  (when version is given)

EXAMPLES
  avk-docs build pdf my-document
  avk-docs build pdf my-document 1.0.0
EOF
}

help_build_html() {
  cat << 'EOF'
avk-docs build html — Build HTML

USAGE
  avk-docs build html <document-name>

ARGUMENTS
  document-name     Name of the document directory (relative to current directory)

OUTPUT
  <document-name>/output/html/index.html

EXAMPLE
  avk-docs build html my-document
EOF
}

help_serve() {
  cat << 'EOF'
avk-docs serve — Serve a built document

USAGE
  avk-docs serve <format> [options]

FORMATS
  html  <document-name>    Serve HTML locally at http://localhost:8000

Run 'avk-docs serve html --help' for details.
EOF
}

help_serve_html() {
  cat << 'EOF'
avk-docs serve html — Serve HTML locally

USAGE
  avk-docs serve html <document-name>

ARGUMENTS
  document-name     Name of the document directory (relative to current directory)

DESCRIPTION
  Starts a local HTTP server at http://localhost:8000 serving the built HTML.
  Run 'avk-docs build html <document-name>' first if output does not exist.

EXAMPLE
  avk-docs serve html my-document
EOF
}

# ── command implementations ──────────────────────────────────────────────────

cmd_init() {
  case "${1:-}" in
    -h|--help) help_init; exit 0 ;;
  esac
  bash "${SCRIPT_DIR}/init-doc.sh" "$@"
}

cmd_build_pdf() {
  case "${1:-}" in
    -h|--help) help_build_pdf; exit 0 ;;
  esac
  bash "${SCRIPT_DIR}/build-pdf.sh" "$@"
}

cmd_build_html() {
  case "${1:-}" in
    -h|--help) help_build_html; exit 0 ;;
  esac
  bash "${SCRIPT_DIR}/build-html.sh" "$@"
}

cmd_build() {
  local sub="${1:-}"
  case "${sub}" in
    -h|--help|"") help_build; exit 0 ;;
    pdf)  shift; cmd_build_pdf  "$@" ;;
    html) shift; cmd_build_html "$@" ;;
    *) echo "Error: unknown format '${sub}'. Use 'pdf' or 'html'." >&2; exit 1 ;;
  esac
}

cmd_serve_html() {
  case "${1:-}" in
    -h|--help) help_serve_html; exit 0 ;;
  esac
  bash "${SCRIPT_DIR}/serve-html.sh" "$@"
}

cmd_serve() {
  local sub="${1:-}"
  case "${sub}" in
    -h|--help|"") help_serve; exit 0 ;;
    html) shift; cmd_serve_html "$@" ;;
    *) echo "Error: unknown format '${sub}'. Use 'html'." >&2; exit 1 ;;
  esac
}

# ── entry point ──────────────────────────────────────────────────────────────

CMD="${1:-}"
case "${CMD}" in
  -h|--help|"") help_root; exit 0 ;;
  init)  shift; cmd_init  "$@" ;;
  build) shift; cmd_build "$@" ;;
  serve) shift; cmd_serve "$@" ;;
  *)
    echo "Error: unknown command '${CMD}'." >&2
    echo "Run 'avk-docs --help' for usage." >&2
    exit 1
    ;;
esac
