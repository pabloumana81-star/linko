#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
APPLY_MIGRATIONS=0

if [ "${1:-}" = "--migrate" ]; then
  APPLY_MIGRATIONS=1
elif [ "$#" -gt 0 ]; then
  echo "Uso: scripts/bootstrap.sh [--migrate]" >&2
  exit 2
fi

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Falta la herramienta requerida: $1" >&2
    return 1
  fi
  "$1" --version >/dev/null
}

READY=1
require_tool flutter || READY=0
require_tool supabase || READY=0

if [ ! -f "$ROOT/.env" ]; then
  echo "Falta $ROOT/.env." >&2
  echo "Créalo con: cp .env.example .env" >&2
  echo "Después reemplaza los valores localmente; nunca confirmes .env en Git." >&2
  READY=0
fi

if [ "$READY" -ne 1 ]; then
  exit 1
fi

echo "Resolviendo dependencias de la aplicación principal..."
(cd "$ROOT" && flutter pub get)
echo "Resolviendo dependencias del backoffice..."
(cd "$ROOT/admin" && flutter pub get)

if [ "$APPLY_MIGRATIONS" -eq 1 ]; then
  echo "Aplicando las migraciones versionadas al proyecto Supabase enlazado..."
  (cd "$ROOT" && supabase db push)
else
  echo "Migraciones no aplicadas. Usa --migrate únicamente tras verificar el proyecto enlazado."
fi

echo "Bootstrap verificado sin mostrar secretos."
