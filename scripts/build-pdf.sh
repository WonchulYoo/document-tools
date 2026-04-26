#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: build-pdf <document-name> [version]"
  exit 1
fi

DOCUMENT_NAME="$1"
VERSION="${2:-}"

# Resolve absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCUMENT_DIR="$(cd "$(pwd)/${DOCUMENT_NAME}" && pwd)"
TEMPLATE_DIR="${PROJECT_ROOT}/template"

# Set output filename
if [[ -n "${VERSION}" ]]; then
  OUTPUT_FILE="${DOCUMENT_NAME}_${VERSION}"
else
  OUTPUT_FILE="${DOCUMENT_NAME}"
fi

# Ensure output directory exists
mkdir -p "${DOCUMENT_DIR}/output"

DOCUMENT_DIR="${DOCUMENT_DIR}" \
TEMPLATE_DIR="${TEMPLATE_DIR}" \
OUTPUT_FILE="${OUTPUT_FILE}" \
docker compose -f "${PROJECT_ROOT}/docker-compose.yml" run --rm document-pdf
