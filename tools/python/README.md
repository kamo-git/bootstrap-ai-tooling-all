# Python ツール集（加美電機）

このディレクトリは Python で作る社内ツールを置く。

## 共通ルール
- 最優先: docs/ai/PROJECT_CONTEXT.md
- Python方針: docs/tools/python/PYTHON_TOOLING.md
- 新規作成時チェック: docs/tools/python/NEW_TOOL_CHECKLIST.md
- 実装変更時は必ず docs/changes/CHANGELOG.md を更新する

## 推奨構成（例）
- tools/python/tool_name/
  - README.md
  - main.py
  - requirements.txt（または pyproject.toml）
  - src/...
