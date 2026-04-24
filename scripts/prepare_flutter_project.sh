#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="build_app"
rm -rf "$PROJECT_DIR"

# Preferimos --empty para evitar arquivos de exemplo que quebram os testes do template.
flutter create --platforms=android --empty "$PROJECT_DIR"

# Defesa extra: remove arquivos de exemplo caso existam (template padrão do Flutter).
rm -f "$PROJECT_DIR/test/widget_test.dart" "$PROJECT_DIR/lib/main.dart"

# Espelha o template do app e remove arquivos gerados que não existirem no template.
rsync -a --delete app_template/ "$PROJECT_DIR"/

# Garantias para evitar regressão no CI (arquivos padrão não podem voltar).
if [ -f "$PROJECT_DIR/test/widget_test.dart" ]; then
  echo "Erro: test/widget_test.dart não deveria existir após sincronizar template."
  exit 1
fi
if compgen -G "$PROJECT_DIR/test/*.dart" > /dev/null; then
  if grep -n "package:build_app/main.dart" "$PROJECT_DIR"/test/*.dart; then
    echo "Erro: import legado package:build_app/main.dart encontrado."
    exit 1
  fi
fi

cd "$PROJECT_DIR"
flutter pub get
flutter test
