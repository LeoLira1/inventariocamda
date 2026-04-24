#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="build_app"
rm -rf "$PROJECT_DIR"

# Cria um projeto Android mínimo para evitar arquivos de exemplo (ex.: widget_test padrão).
flutter create --platforms=android --empty "$PROJECT_DIR"

# Espelha o template do app e remove arquivos gerados que não existirem no template.
rsync -a --delete app_template/ "$PROJECT_DIR"/

cd "$PROJECT_DIR"
flutter pub get
flutter test
