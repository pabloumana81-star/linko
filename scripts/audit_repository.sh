#!/bin/sh

set -eu

root_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root_dir"

tracked_forbidden=$(git ls-files | awk '
  /(^|\/)\.env($|\.)/ && $0 != ".env.example" { print }
  /(^|\/)(build|\.dart_tool|\.gradle|Pods|DerivedData)(\/|$)/ { print }
  /^supabase\/\.temp\// { print }
')

if [ -n "$tracked_forbidden" ]; then
  printf '%s\n' 'Hay secretos o artefactos generados rastreados:' >&2
  printf '%s\n' "$tracked_forbidden" >&2
  exit 1
fi

if git grep -Il -E 'sb_secret_|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY' -- \
  ':!.env.example' ':!docs/**' ':!test/**' ':!integration_test/**' \
  ':!scripts/audit_repository.sh' >/dev/null; then
  printf '%s\n' 'Se detectó un patrón de credencial privada en archivos rastreados.' >&2
  exit 1
fi

if git grep -Il -E 'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.' -- \
  'lib/**' 'admin/lib/**' 'web/**' 'admin/web/**' >/dev/null; then
  printf '%s\n' 'Se detectó un token JWT incrustado en código cliente.' >&2
  exit 1
fi

printf '%s\n' 'Auditoría de secretos y artefactos rastreados aprobada.'
