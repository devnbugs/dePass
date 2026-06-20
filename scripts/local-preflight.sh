#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_DIR="${ROOT_DIR}/workspace"
BACKEND_DB="${WORKSPACE_DIR}/depass-preflight.sqlite"

mkdir -p "${WORKSPACE_DIR}"

run_backend() {
  if ! command -v php >/dev/null || ! command -v composer >/dev/null; then
    echo "Skipping Laravel checks: php and composer are required."
    return
  fi

  echo "== Laravel: composer validate =="
  (
    cd "${ROOT_DIR}/backend"
    XDEBUG_MODE=off composer validate --strict
  )

  echo "== Laravel: tests on isolated SQLite =="
  rm -f "${BACKEND_DB}"
  touch "${BACKEND_DB}"
  (
    cd "${ROOT_DIR}/backend"
    XDEBUG_MODE=off DB_CONNECTION=sqlite DB_DATABASE="${BACKEND_DB}" php artisan test
  )

  if command -v npm >/dev/null; then
    echo "== Laravel: Vite production build =="
    (
      cd "${ROOT_DIR}/backend"
      if [ -f package-lock.json ]; then
        npm ci
      else
        npm install
      fi
      npm run build
    )
  else
    echo "Skipping Laravel Vite build: npm is not installed."
  fi
}

run_flutter() {
  if ! command -v flutter >/dev/null; then
    echo "Skipping Flutter checks: flutter is not installed."
    return
  fi

  echo "== Flutter: dependencies =="
  (
    cd "${ROOT_DIR}/mobile"
    flutter pub get
  )

  echo "== Flutter: analyze =="
  (
    cd "${ROOT_DIR}/mobile"
    flutter analyze
  )

  echo "== Flutter: tests =="
  (
    cd "${ROOT_DIR}/mobile"
    if [ -d test ]; then
      flutter test
    else
      echo "No Flutter test directory found; skipping flutter test."
    fi
  )
}

run_backend
run_flutter

echo "Preflight complete. Local artifacts stayed in ${WORKSPACE_DIR}."
