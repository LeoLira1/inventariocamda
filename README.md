# Inventário CAMDA (Flutter + GitHub Actions)

Aplicativo Flutter para inventário de loja agropecuária com sincronização remota, busca, filtro por categoria e cache offline.

## Arquitetura

- `app_template/lib/main.dart`: inicialização do app e injeção do controller.
- `app_template/lib/state/inventory_controller.dart`: estado da aplicação (sincronização, busca, filtros e KPIs).
- `app_template/lib/services/inventory_api_service.dart`: leitura da fonte remota.
- `app_template/lib/services/local_cache_service.dart`: cache local com `SharedPreferences`.
- `app_template/lib/models/inventory_item.dart`: normalização dos campos de inventário.
- `app_template/lib/ui/inventory_page.dart`: interface principal com lista de itens, filtros e botão de sincronização.
- `.github/workflows/android-release.yml`: pipeline para gerar APK e publicar em Release.

## Fonte de dados

A URL padrão configurada no app é:

`https://raw.githubusercontent.com/LeoLira1/camda-estoque/refs/heads/main/inventario_ciclico_tab.py`

Você também pode trocar a URL dentro do app (ícone de engrenagem), caso queira apontar para um endpoint JSON específico do seu banco.

## Como gerar APK no GitHub (sem PC)

1. Suba este repositório no GitHub.
2. Vá em **Actions > Android Release**.
3. Clique em **Run workflow** e informe uma tag, por exemplo `v1.0.0`.
4. Ao finalizar, baixe o APK em:
   - **Artifacts** da execução, ou
   - aba **Releases** (arquivo `app-release.apk`).

## Desenvolvimento local (opcional)

Pré-requisitos: Flutter + Android SDK.

```bash
./scripts/prepare_flutter_project.sh
cd build_app
flutter run
```
