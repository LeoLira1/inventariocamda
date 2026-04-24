#!/usr/bin/env bash
set -euo pipefail

TARGET="scripts/prepare_flutter_project.sh"

required_patterns=(
  'rm -f "\$PROJECT_DIR/test/widget_test.dart" "\$PROJECT_DIR/lib/main.dart"'
  'rsync -a --delete app_template/ "\$PROJECT_DIR"/'
  'if \[ -f "\$PROJECT_DIR/test/widget_test.dart" \]; then'
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -Eq "$pattern" "$TARGET"; then
    echo "Falha: padrão obrigatório não encontrado em $TARGET"
    echo "Padrão: $pattern"
    exit 1
  fi
done

echo "OK: regras anti-conflito do prepare script estão presentes."
