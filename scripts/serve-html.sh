#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: serve-html <document-name>"
  exit 1
fi

DOCUMENT_NAME="$1"
DOCUMENT_DIR="$(cd "$(pwd)/${DOCUMENT_NAME}" && pwd)"
HTML_DIR="${DOCUMENT_DIR}/output/html"

if [[ ! -d "${HTML_DIR}" ]]; then
  echo "Error: HTML output not found at ${HTML_DIR}"
  echo "Run 'build-html ${DOCUMENT_NAME}' first."
  exit 1
fi

echo "Serving HTML from ${HTML_DIR} at http://localhost:8000"
cd "${HTML_DIR}"
python3 -m http.server 8000
