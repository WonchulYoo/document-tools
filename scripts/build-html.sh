#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: build-html <document-name>"
  exit 1
fi

DOCUMENT_NAME="$1"

# Resolve absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCUMENT_DIR="$(cd "$(pwd)/${DOCUMENT_NAME}" && pwd)"

# Ensure output directory exists
mkdir -p "${DOCUMENT_DIR}/output/html"

DOCUMENT_DIR="${DOCUMENT_DIR}" \
docker compose -f "${PROJECT_ROOT}/docker-compose.yml" run --rm document-html
