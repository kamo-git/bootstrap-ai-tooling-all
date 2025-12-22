# C# ツール集（加美電機）

このディレクトリは C#/.NET で作る社内ツールを置く。

## 共通ルール
- 最優先: docs/ai/PROJECT_CONTEXT.md
- C#方針: docs/tools/csharp/CSHARP_TOOLING.md
- 新規作成時チェック: docs/tools/csharp/NEW_TOOL_CHECKLIST.md
- 実装変更時は必ず docs/changes/CHANGELOG.md を更新する

## 推奨構成（例）
- tools/csharp/ToolName/
  - ToolName.csproj
  - Program.cs
  - README.md
  - src/...
