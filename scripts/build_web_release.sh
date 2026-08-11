#!/bin/sh

set -eu

root_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
env_file=${1:-"$root_dir/.env"}

fail() {
  printf '%s\n' "Error de configuración de release: $1" >&2
  exit 1
}

read_value() {
  key=$1
  awk -F= -v key="$key" '
    $0 !~ /^[[:space:]]*#/ && $1 == key {
      sub(/^[^=]*=/, "")
      value = $0
    }
    END { print value }
  ' "$env_file"
}

[ -f "$env_file" ] || fail "falta el archivo indicado. Créalo desde .env.example."

backend_mode=$(read_value BACKEND_MODE)
supabase_url=$(read_value SUPABASE_URL)
supabase_anon_key=$(read_value SUPABASE_ANON_KEY)
auth_redirect_url=$(read_value AUTH_REDIRECT_URL)

[ "$backend_mode" = "supabase" ] || fail "BACKEND_MODE debe ser supabase."
case "$supabase_url" in
  https://*) ;;
  *) fail "SUPABASE_URL debe ser una URL HTTPS." ;;
esac
[ "$supabase_url" != "https://your-project.supabase.co" ] || fail "SUPABASE_URL conserva el placeholder."
[ -n "$supabase_anon_key" ] || fail "SUPABASE_ANON_KEY es obligatoria."
[ "$supabase_anon_key" != "your-public-anon-key" ] || fail "SUPABASE_ANON_KEY conserva el placeholder."
[ "$auth_redirect_url" = "io.supabase.linko://login-callback/" ] ||
  fail "AUTH_REDIRECT_URL debe conservar el callback nativo exacto."

cd "$root_dir"
printf '%s\n' 'Configuración pública de producción validada sin mostrar valores.'
flutter analyze
flutter test --dart-define=BACKEND_MODE=mock
flutter build web --release --dart-define-from-file="$env_file"
printf '%s\n' 'Build web de producción creado en build/web.'
