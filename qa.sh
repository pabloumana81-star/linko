#!/bin/sh

set -eu

cd "$(dirname "$0")"

flutter analyze
flutter test --dart-define=BACKEND_MODE=mock test/diagnostics_test.dart
flutter test --dart-define=BACKEND_MODE=mock
flutter test --dart-define=BACKEND_MODE=mock integration_test/full_mvp_flow_test.dart -d macos

printf '\033[32m%s\033[0m\n' 'All QA checks passed!'
