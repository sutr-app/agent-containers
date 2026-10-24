# 開発・検証規約

## Shell

- スクリプトは Bash を使用し、`set -euo pipefail` を指定する。コメントは理由を英語で記載する。
- 既存の4スペースインデントと命名規則に従う。
- Docker 呼び出しの動作は `tests/auth-scripts-test.sh` のモックで検証し、実装変更前にテストを追加する。
- リポジトリルートで全テスト、構文検査、ShellCheck を実行する。

```bash
rtk proxy bash -c 'for test_file in tests/*-test.sh; do bash "$test_file" || exit; done'
rtk proxy bash -c 'for source_file in scripts/*.sh scripts/lib/*.sh tests/*.sh docker/openai-codex/entrypoint.sh; do bash -n "$source_file" || exit; done'
rtk proxy shellcheck -x -P scripts scripts/*.sh scripts/lib/*.sh tests/*.sh docker/openai-codex/entrypoint.sh
```

## GitHub Actions・Dockerfile・JSON

- YAML は既存の2スペースインデントを使用する。workflow を変更した場合は `rtk proxy actionlint .github/workflows/publish-images.yml` を実行する。今回の検証には actionlint v1.7.12 を使用する。
- Dockerfile を変更した場合は対応する `tests/*-dockerfile-test.sh` を実行する。ビルド時・実行時の挙動を変更した場合は、対象イメージのビルド・起動も検証する。
- JSON は既存の書式を維持し、変更時は `rtk proxy python3 -m json.tool <対象ファイル>` で構文を確認する。
- テストと lint の成功後にコミットする。公開手順は README を参照する。
