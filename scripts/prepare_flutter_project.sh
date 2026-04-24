#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="build_app"
rm -rf "$PROJECT_DIR"

flutter create --platforms=android "$PROJECT_DIR"

# Remove arquivos de exemplo que podem conflitar com o template real.
rm -f "$PROJECT_DIR/test/widget_test.dart" "$PROJECT_DIR/lib/main.dart"

# Espelha o template e garante que não fiquem resíduos do projeto gerado.
rsync -a --delete app_template/ "$PROJECT_DIR"/

cd "$PROJECT_DIR"
flutter pub get
flutter test
