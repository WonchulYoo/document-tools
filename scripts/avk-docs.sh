#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# avk-docs — Avikus Document CLI
# ---------------------------------------------------------------------------

_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "${_SOURCE}" ]]; do
  _DIR="$(cd -P "$(dirname "${_SOURCE}")" && pwd)"
  _SOURCE="$(readlink "${_SOURCE}")"
  [[ "${_SOURCE}" != /* ]] && _SOURCE="${_DIR}/${_SOURCE}"
done
SCRIPT_DIR="$(cd -P "$(dirname "${_SOURCE}")" && pwd)"
unset _SOURCE _DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── help texts ───────────────────────────────────────────────────────────────

help_root() {
  cat << 'EOF'
avk-docs — Avikus Document CLI

USAGE
  avk-docs <command> [subcommand] [options]

COMMANDS
  init  <document-title>        Initialize a new document interactively
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
  avk-docs init [options] <document-title>

ARGUMENTS
  document-title         Default info-document-title value.
                         The new directory is created as:
                           document/test-report: "<document-number> <document-title>"
                           letter:               "<issue-date> <document-title>"

OPTIONS
  -y                     Skip all interactive prompts; use template values and flags
  --template TYPE        Template type: document (default) | letter | test-report
  --type TYPE            Alias for --template
  --set TAG=VALUE        Set any metadata tag from the selected metadata.adoc
                         Omitted template tags are ignored
  --doctype TYPE         Override AsciiDoc doctype: book | article
  --title-page yes|no    Include title page
  --product-name NAME    Sets info-product-name
  --document-no NO       Sets info-document-number
  --module-name NAME     Sets info-module-name
  --document-type TYPE   Sets info-document-type
  --project-manager NAME Sets info-project-manager
  --final-editor NAME    Sets info-final-editor
  --authors AUTHORS      Other authors, comma-separated
  --document-version VER Sets info-document-version
  --release-date DATE    Sets info-issue-date
  --eut-version VER      Sets summary-eut-version
  --test-period PERIOD   Sets summary-test-period
  --place-of-testing PLACE
                         Sets summary-place-of-testing
  --test-specification LIST
                         Sets summary-f-test-specification (; separated)
  --tested-by NAMES      Sets summary-tested-by
  --authorised-by NAMES  Sets summary-authorised-by
  --authorized-by NAMES  Alias for --authorised-by
  --approved VALUE       Sets summary-approved
  --doc-info yes|no      Include inner cover / document information page (default: yes)
  --revision yes|no      Include revision history (default: yes)
  --toc yes|no           Include table of contents (default: yes)
  --figure-list yes|no   Include figure list (default: yes)
  --table-list yes|no    Include table list (default: yes)

DESCRIPTION
  Copies one of the bundled template directories into a new document directory.
  The init wizard reads metadata.adoc from the selected template and asks for
  the metadata tags defined there, using nearby comments as question text.
  Existing metadata values are shown as examples only; blank input writes a
  blank value unless the field is required, has an explicit default, or is a
  test-report summary approval field.
  Any option not supplied via a flag will be collected interactively unless -y
  is given, in which case missing required fields fail and optional fields are
  blank unless they have explicit defaults.

  Template types: document, letter, test-report

EXAMPLES
  # Fully interactive
  avk-docs init "My Document"

  # Choose a template interactively
  avk-docs init --template letter "Project Notice"

  # Partially tagged (skips prompted fields that are supplied)
  avk-docs init --product-name "MyProduct" --final-editor "Jane" "Design Notes"

  # Non-interactive document (-y mode)
  avk-docs init -y \\
    --project-manager "John" --final-editor "Jane" \\
    --document-type "Design Document" --document-no "AVK-001" \\
    --release-date "2026-05-04" "My Document"

  # Non-interactive test report (-y mode)
  avk-docs init -y --template test-report \\
    --product-name "HiNAS" --document-no "AVK-TR-001" \\
    --eut-version "v1.0.0" --test-period "2026-05-01 - 2026-05-03" \\
    --place-of-testing "Lab" "My Report"
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
  # Scan for -h/--help anywhere in the arguments
  for _arg in "$@"; do
    case "${_arg}" in -h|--help) help_init; exit 0 ;; esac
  done
  if [[ $# -eq 0 ]]; then
    echo "Error: missing argument <document-title>." >&2; echo; help_init; exit 1
  fi
  bash "${SCRIPT_DIR}/init-doc.sh" "$@"
}

cmd_build_pdf() {
  case "${1:-}" in
    -h|--help) help_build_pdf; exit 0 ;;
    "") echo "Error: missing argument <document-name>." >&2; echo; help_build_pdf; exit 1 ;;
  esac
  bash "${SCRIPT_DIR}/build-pdf.sh" "$@"
}

cmd_build_html() {
  case "${1:-}" in
    -h|--help) help_build_html; exit 0 ;;
    "") echo "Error: missing argument <document-name>." >&2; echo; help_build_html; exit 1 ;;
  esac
  bash "${SCRIPT_DIR}/build-html.sh" "$@"
}

cmd_build() {
  local sub="${1:-}"
  case "${sub}" in
    -h|--help|"") help_build; exit 0 ;;
    pdf)  shift; cmd_build_pdf  "$@" ;;
    html) shift; cmd_build_html "$@" ;;
    *) echo "Error: unknown format '${sub}'. Use 'pdf' or 'html'." >&2; echo; help_build; exit 1 ;;
  esac
}

cmd_serve_html() {
  case "${1:-}" in
    -h|--help) help_serve_html; exit 0 ;;
    "") echo "Error: missing argument <document-name>." >&2; echo; help_serve_html; exit 1 ;;
  esac
  bash "${SCRIPT_DIR}/serve-html.sh" "$@"
}

cmd_serve() {
  local sub="${1:-}"
  case "${sub}" in
    -h|--help|"") help_serve; exit 0 ;;
    html) shift; cmd_serve_html "$@" ;;
    *) echo "Error: unknown format '${sub}'. Use 'html'." >&2; echo; help_serve; exit 1 ;;
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
    echo
    help_root
    exit 1
    ;;
esac
