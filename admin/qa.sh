#!/bin/sh

set -eu

cd "$(dirname "$0")"

flutter analyze
flutter test

printf '\033[32m%s\033[0m\n' 'All admin QA checks passed!'
