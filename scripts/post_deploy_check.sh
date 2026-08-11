#!/bin/sh

set -eu

[ "$#" -eq 1 ] || {
  printf '%s\n' 'Uso: scripts/post_deploy_check.sh https://host-de-beta.example' >&2
  exit 1
}

base_url=${1%/}
case "$base_url" in
  https://*) ;;
  *) printf '%s\n' 'El health check de producción exige HTTPS.' >&2; exit 1 ;;
esac

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

check_route() {
  route=$1
  name=$2
  curl --fail --silent --show-error --location \
    --dump-header "$tmp_dir/headers" \
    --output "$tmp_dir/body" "$base_url$route"
  grep -qi '<title>LinkO</title>' "$tmp_dir/body" || {
    printf '%s\n' "El fallback SPA falló para $name." >&2
    exit 1
  }
}

check_route / inicio
check_route /welcome autenticación
check_route /professional/health-check perfil-profesional

for header in \
  strict-transport-security \
  x-content-type-options \
  referrer-policy \
  permissions-policy \
  content-security-policy; do
  grep -qi "^$header:" "$tmp_dir/headers" || {
    printf '%s\n' "Falta el header requerido: $header" >&2
    exit 1
  }
done

grep -qi "frame-ancestors" "$tmp_dir/headers" || {
  printf '%s\n' 'La CSP no declara frame-ancestors.' >&2
  exit 1
}

if grep -qi 'Backend[[:space:]]*MOCK' "$tmp_dir/body"; then
  printf '%s\n' 'El deployment expone backend MOCK.' >&2
  exit 1
fi

printf '%s\n' 'Health check HTTP aprobado. Completa el checklist autenticado de docs/DEPLOYMENT.md.'
