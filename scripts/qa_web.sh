#!/bin/sh

set -eu

root_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

cd "$root_dir"
flutter test --platform chrome --dart-define=BACKEND_MODE=mock \
  test/web_beta_smoke_test.dart

cd "$root_dir/admin"
flutter test --platform chrome --dart-define=BACKEND_MODE=mock \
  test/admin_browser_flow_test.dart

printf '\033[32m%s\033[0m\n' 'All browser QA checks passed!'
