#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/.build"
ZIP_DIR="${SCRIPT_DIR}/zip"
ZIP_PATH="${ZIP_DIR}/crawl_lambda.zip"

rm -rf "${BUILD_DIR}" "${ZIP_PATH}"
mkdir -p "${BUILD_DIR}" "${ZIP_DIR}"

if [[ -s "${SCRIPT_DIR}/requirements.txt" ]]; then
  if python3 -m pip --version >/dev/null 2>&1; then
    python3 -m pip install \
      --requirement "${SCRIPT_DIR}/requirements.txt" \
      --target "${BUILD_DIR}" \
      --upgrade || echo "pip install failed; continuing with project files only"
  elif command -v uv >/dev/null 2>&1; then
    uv pip install \
      --requirement "${SCRIPT_DIR}/requirements.txt" \
      --target "${BUILD_DIR}" || echo "uv install failed; continuing with project files only"
  else
    echo "pip/uv not found; skipping dependency install"
  fi
fi

cp "${SCRIPT_DIR}"/*.py "${BUILD_DIR}/"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  cp "${SCRIPT_DIR}/.env" "${BUILD_DIR}/"
fi

if command -v zip >/dev/null 2>&1; then
  (
    cd "${BUILD_DIR}"
    zip -r "${ZIP_PATH}" . \
      -x "__pycache__/*" \
      -x "*.pyc" \
      -x "*.pyo"
  )
else
  python3 - "${BUILD_DIR}" "${ZIP_PATH}" <<'PY'
import sys
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

build_dir = Path(sys.argv[1])
zip_path = Path(sys.argv[2])

with ZipFile(zip_path, "w", ZIP_DEFLATED) as archive:
    for path in build_dir.rglob("*"):
        if not path.is_file():
            continue
        if "__pycache__" in path.parts or path.suffix in {".pyc", ".pyo"}:
            continue
        archive.write(path, path.relative_to(build_dir))
PY
fi

echo "Created ${ZIP_PATH}"
echo "Lambda handler: main.handler"
