#!/bin/sh

set -eu
set +x

root_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
env_file="$root_dir/.env"
project_ref_file="$root_dir/supabase/.temp/project-ref"

if [ ! -f "$env_file" ]; then
  echo 'Error: falta .env en la raíz del proyecto.' >&2
  exit 1
fi

set -a
. "$env_file"
set +a

if [ "${BACKEND_MODE:-}" != 'supabase' ]; then
  echo 'Error: BACKEND_MODE debe ser supabase para esta certificación.' >&2
  exit 1
fi
if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo 'Error: faltan SUPABASE_URL o SUPABASE_ANON_KEY.' >&2
  exit 1
fi
if [ ! -f "$project_ref_file" ]; then
  echo 'Error: el proyecto Supabase no está enlazado.' >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo 'Error: jq es necesario para leer la credencial temporal de QA.' >&2
  exit 1
fi

linked_project_ref=$(tr -d '[:space:]' < "$project_ref_file")
configured_project_ref=$(printf '%s' "$SUPABASE_URL" | sed -E 's#^https://([^.]+)\.supabase\.co/?$#\1#')
if [ "$linked_project_ref" != "$configured_project_ref" ]; then
  echo 'Error: el proyecto enlazado no coincide con SUPABASE_URL.' >&2
  exit 1
fi

service_key=$(
  supabase projects api-keys --workdir "$root_dir" --output json |
    jq -r '.[] | select(.name == "service_role") | .api_key'
)
if [ -z "$service_key" ] || [ "$service_key" = 'null' ]; then
  echo 'Error: no se encontró la credencial service_role para QA.' >&2
  exit 1
fi
trap 'unset service_key SUPABASE_ANON_KEY' EXIT INT TERM

echo 'Ejecutando certificación E2E contra el proyecto Supabase enlazado...'
cd "$root_dir/admin"
flutter test ../integration_test/real_supabase_e2e_test.dart \
  --dart-define=RUN_SUPABASE_E2E=true \
  --dart-define-from-file=../.env \
  --dart-define=SUPABASE_LINKED_PROJECT_REF="$linked_project_ref" \
  --dart-define=SUPABASE_TEST_SERVICE_ROLE_KEY="$service_key"

echo 'Certificación E2E Supabase aprobada.'
