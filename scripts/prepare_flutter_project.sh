#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="build_app"
rm -rf "$PROJECT_DIR"
flutter create --platforms=android "$PROJECT_DIR"

rsync -a app_template/ "$PROJECT_DIR"/

cd "$PROJECT_DIR"
flutter pub get
flutter test
