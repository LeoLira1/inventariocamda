#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="build_app"
rm -rf "$PROJECT_DIR"
flutter create --platforms=android "$PROJECT_DIR"

# Remove arquivos de exemplo que podem conflitar com o template real.
rm -f "$PROJECT_DIR/test/widget_test.dart" "$PROJECT_DIR/lib/main.dart"

# Espelha o template e garante que não fiquem resíduos do projeto gerado.
rsync -a app_template/ "$PROJECT_DIR"/

# Garantia: o teste de exemplo do template padrão não pode reaparecer.
if [ -f "$PROJECT_DIR/test/widget_test.dart" ]; then
  echo "Erro: widget_test.dart não deveria existir após sincronização do template."
  exit 1
fi

cd "$PROJECT_DIR"
flutter pub get
flutter test
