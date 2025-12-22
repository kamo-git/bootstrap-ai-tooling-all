#!/usr/bin/env bash
set -euo pipefail

# ---------
# Safety checks
# ---------
if [[ ! -d ".git" ]]; then
  echo "ERROR: .git directory not found. Run this at the repository root." >&2
  exit 1
fi

# ---------
# Directories
# ---------
mkdir -p \
  .github \
  .cursor/rules \
  docs/ai \
  docs/changes \
  docs/runbook \
  docs/db \
  docs/api \
  docs/tools/csharp \
  docs/tools/python \
  tools/csharp \
  tools/python

# ---------
# 0) Single source of truth (AI context)
# ---------
cat > docs/ai/PROJECT_CONTEXT.md <<'EOF'
# プロジェクトコンテキスト（加美電機 / LAMP前提）
この文書は、AIコード生成ツール／AIレビューツールが本リポジトリで作業する際の最優先前提である。

## 1. 組織・業務コンテキスト
- 加美電機は日本の中小製造業（SME）。
- 主領域：電子回路基板の製造・実装・検査（AOI/ICT等）・不具合解析・品質対応。
- 多品種少量・例外対応が多く、「現場判断」「過去事例」が重要。

## 2. 運用環境（前提）
- 既存の LAMP 環境がある：Linux + Apache + MySQL/MariaDB + PHP。
- 既存資産と共存しつつ、段階的に改善する。大規模な刷新は前提にしない。

## 3. 開発・保守の現実
- 保守者はWeb専業とは限らない。
- 可読性・デバッグ容易性・修正可能性を最優先。
- 「動くが理解不能」「抽象化しすぎ」「依存追加が多い」実装は避ける。

## 4. フレームワーク / ORM / SQL の方針
- フレームワークは使用可。ただし「導入理由」が明確で、保守性が上がる場合に限る。
- ORMは状況次第：
  - CRUD中心で意図が明瞭になるならORM可。
  - JOIN/集計/複雑条件が絡むなら、SQLの方が明確ならSQL優先。
- ORM使用時も、クエリ意図が追える（必要なら想定SQL形をコメント）こと。

## 5. コード生成の必須ルール
- シンプルで直線的な処理構造（過剰設計しない）。
- 例外・入力揺れ・運用上の失敗を想定した堅牢性（エラーハンドリング、ログ、バリデーション）。
- 「今日のLAMP環境で動く」ことを優先し、追加基盤を要求しない。

## 6. レビュー（PRレビュー/自動レビュー）方針
- 最優先：正しさ、データ整合性、セキュリティ、運用リスク、性能劣化リスク。
- 形式・好みの指摘（bikeshedding）は、実害がある場合のみ。
- 大規模アーキテクチャ変更の提案は、明示依頼がない限り避ける。

## 7. 期待する出力スタイル
- 変更は段階的に。導入手順・影響範囲・ロールバック観点を簡潔に示す。
- 「なぜこの実装か」を短く説明する（コメントまたは本文）。

## 8. コメントとドキュメント更新（義務）
- コメントは「できるだけ残す」ことを義務とする。
  - 「何をしているか」ではなく「なぜそうするか」「業務上の意味」「前提」「例外条件」を優先して書く。
  - 不具合対応・例外対応・客先ルール・暫定処置は必ず理由と背景をコメントに残す。
- コード実装時は、必ずドキュメントも更新することを義務とする。
  - 仕様・運用・手順・設定・API・DB変更など、変更点を文書化する。
  - 更新先が不明な場合は、最低限 docs/ 配下に変更概要を追記する。
  - PRでは「更新したドキュメント」または「更新不要の理由」を必ず明記する。
EOF

# ---------
# 1) GitHub Copilot instructions + PR template
# ---------
cat > .github/copilot-instructions.md <<'EOF'
# Copilot Instructions（加美電機 / LAMP）

最優先は docs/ai/PROJECT_CONTEXT.md の内容。

要点（最小）：
- 加美電機：基板製造・検査（AOI/ICT）・品質対応の中小製造業。例外が多い。
- 既存LAMP（Linux/Apache/MySQL(MariaDB)/PHP）で運用。大刷新は前提にしない。
- 可読性・デバッグ容易性・修正可能性を最優先。過剰設計は禁止。
- フレームワークは導入理由が明確な場合のみ可。
- ORMは状況次第。SQLの方が明確ならSQL優先。ORMでも意図が追えること。
- コメントは可能な限り残す（why/業務的意味/前提/例外）。
- 実装変更時は必ずドキュメント更新まで含める（更新不要なら理由を明記）。
- レビューは正しさ/整合性/セキュリティ/運用リスク重視。些末な指摘は避ける。
EOF

cat > .github/pull_request_template.md <<'EOF'
## 実装内容
-

## 更新したドキュメント
- [ ] docs/changes/CHANGELOG.md
- [ ] docs/db/DATABASE.md
- [ ] docs/runbook/OPERATIONS.md
- [ ] docs/api/API.md（該当する場合）
- [ ] docs/ai/PROJECT_CONTEXT.md（前提変更がある場合）
- [ ] docs/tools/csharp/CSHARP_TOOLING.md（C#方針変更がある場合）
- [ ] docs/tools/python/PYTHON_TOOLING.md（Python方針変更がある場合）
- [ ] その他：

## ドキュメント更新不要の場合の理由
-
EOF

# ---------
# 2) Cursor rules
# ---------
cat > .cursor/rules/kami-lamp.mdc <<'EOF'
---
description: 加美電機 LAMP 前提（生成 + レビュー）コアルール
globs:
  - "**/*"
---

最優先は docs/ai/PROJECT_CONTEXT.md。

要点（最小）：
- 既存LAMP（Linux/Apache/MySQL(MariaDB)/PHP）で即動く実装を優先。追加基盤は要求しない。
- シンプルで明示的、保守しやすいコード。過剰設計・過剰抽象化は禁止。
- フレームワークは導入理由が明確で保守性が上がる場合のみ可。
- ORMは状況次第。JOIN/集計/複雑条件が絡むならSQL優先。
- コメントは可能な限り残す（why/前提/業務的意味/例外）。
- 実装変更時は必ずドキュメント更新まで含める（不明なら docs/ に変更概要を追記）。
- レビューは正しさ、データ整合性、セキュリティ、運用リスク、性能リスクを重視。bikesheddingは避ける。
EOF

# ---------
# 3) Claude Code instructions
# ---------
cat > CLAUDE.md <<'EOF'
# Claude Code Instructions（加美電機 / LAMP）

最優先は docs/ai/PROJECT_CONTEXT.md。

要点（最小）：
- 既存LAMP前提で、段階的改善。
- 可読性・デバッグ容易性・修正可能性を最優先。過剰設計しない。
- フレームワークは導入理由が明確な場合のみ可。
- ORMは状況次第。SQLの方が明確ならSQL優先。
- コメントは可能な限り残す（why/前提/業務的意味/例外）。
- 実装変更時は必ずドキュメント更新まで含める（更新不要なら理由明記）。
- レビューは正しさ/整合性/セキュリティ/運用リスク重視。
EOF

# ---------
# 4) OpenAI Codex instructions
# ---------
cat > AGENTS.md <<'EOF'
# AGENTS.md（加美電機 / LAMP）

最優先は docs/ai/PROJECT_CONTEXT.md。

要点（最小）：
- 既存LAMP（Linux/Apache/MySQL(MariaDB)/PHP）前提。追加基盤なしで動くこと。
- シンプルで明示的な実装。過剰抽象化・過剰設計は禁止。
- フレームワークは導入理由が明確な場合のみ可。
- ORMは状況次第。複雑クエリはSQL優先。ORMでも意図が追えること。
- コメントは可能な限り残す（why/前提/業務的意味/例外）。
- 実装変更時は必ずドキュメント更新まで含める（更新不要なら理由明記）。
- レビューは正しさ/整合性/セキュリティ/運用リスク重視。
EOF

# ---------
# 5) CodeRabbit configuration (FULL)
# ---------
cat > .coderabbit.yaml <<'EOF'
language: "ja-JP"

reviews:
  auto_review:
    enabled: true
    base_branches:
      - ".*"

  profile: "assertive"
  review_status: true

  path_instructions:
    - path: "**/*"
      instructions: |
        最優先: docs/ai/PROJECT_CONTEXT.md の方針に従うこと。

        前提:
        - 加美電機の内製ツール。製造現場・品質（AOI/ICT等）に関わる。
        - 既存LAMP（Linux/Apache/MySQL(MariaDB)/PHP）で運用される前提。
        - ただし本リポジトリでは C# / Python ツールも扱う（言語は問わず方針は共通）。
        - 大規模刷新や追加基盤要求は原則しない。

        実装方針:
        - 可読性・デバッグ容易性・修正可能性を最優先。過剰設計/過剰抽象化は禁止。
        - フレームワークは導入理由が明確で保守性が上がる場合のみ可。
        - ORMは状況次第。JOIN/集計/複雑条件が絡むなら、SQLが明確ならSQL優先。
        - コメントは可能な限り残す（特に why/前提/業務的意味/例外/暫定処置）。

        ドキュメント更新（必須）:
        - 実装変更がある場合、ドキュメント更新が必須。
        - 最低限 docs/changes/CHANGELOG.md が更新されているか確認し、未更新なら最優先で指摘する。
        - DBに関わる変更がある場合 docs/db/DATABASE.md の更新があるか確認し、未更新なら指摘する。
        - 運用手順や障害対応に影響する場合 docs/runbook/OPERATIONS.md の更新があるか確認し、未更新なら指摘する。
        - 更新不要の場合は、その理由がPR内に明記されているか確認する。

        レビュー観点:
        - 正しさ、エッジケース、データ整合性、セキュリティ、運用リスク、性能劣化リスクを重点。
        - 形式や好みの指摘（bikeshedding）は実害がある場合のみ。
EOF

# ---------
# 6) docs templates (common)
# ---------
cat > docs/changes/CHANGELOG.md <<'EOF'
# 変更履歴（CHANGELOG）

このファイルは「何が・なぜ変わったか」を最低限記録するためのもの。
詳細設計やコード解説は不要。判断理由と影響範囲を重視する。

---

## YYYY-MM-DD
### 変更概要
- （例）AOIログ取込処理にエラー判定条件を追加

### 変更理由
- （例）現場で特定条件のログが誤って正常扱いされていたため

### 影響範囲
- 対象画面：XXX
- 対象DB：table_name
- 既存データへの影響：なし / あり（内容）

### ロールバック観点
- （例）該当if条件を元に戻せば復旧可能

---
EOF

cat > docs/runbook/OPERATIONS.md <<'EOF'
# 運用・トラブル対応（Runbook）

この文書は「困ったときに読む」ためのもの。
網羅性より実際に起きたことの記録を優先する。

---

## サービス概要
- 対象：〇〇管理ツール
- 稼働環境：LAMP（Linux / Apache / MySQL(MariaDB) / PHP）および社内ツール（C# / Python）
- 想定利用者：製造技術 / 品質担当

---

## よくあるトラブル

### 画面が表示されない（Web）
- Apacheが起動しているか確認
- PHPエラーは error_log を確認

### ツールが動かない（C#/Python）
- どのPCで、どの手順で、どの入力で失敗したかを確認
- ログ（ファイル/コンソール）を確認
- 入力ファイルの形式（区切り/文字コード/必須列/欠損）を確認

### データが反映されない
- DB接続情報を確認
- CSV/Excelの文字コード・区切り文字・列名揺れを確認

---

## 手動対応・暫定対応

### DBを直接修正したケース
- 実施日：
- 理由：
- 実施内容：
- 後続対応（コード反映の要否）：

---

## ログの場所
- Apache：/var/log/apache2/
- アプリ独自ログ：（あれば記載）

---
EOF

cat > docs/db/DATABASE.md <<'EOF'
# データベース仕様・履歴

この文書は「SQLを読まなくても全体像が分かる」ことを目的とする。
正確さより意図と業務対応関係を重視する。

---

## 使用DB
- MySQL / MariaDB
- 文字コード：utf8mb4

---

## テーブル一覧

### table_name
- 用途：〇〇を管理する
- 主な利用画面：XXX
- 備考：現場ルールにより△△なデータが入ることがある

#### 主なカラム
| カラム名 | 型 | 意味 |
|--------|----|------|
| id | int | 主キー |
| created_at | datetime | 登録日時 |

---

## 変更履歴

### YYYY-MM-DD
- 変更内容：
- 理由：
- 既存データ影響：あり / なし

---
EOF

cat > docs/api/API.md <<'EOF'
# API / 画面インターフェース仕様

※ APIや画面間I/Fが存在しない場合は空でよい。

---

## 一覧

### POST /import
- 概要：CSV取込
- 入力：
  - file：CSVファイル
- 出力：
  - 成功/失敗メッセージ

### 備考
- 現場でのCSV形式揺れあり
- 厳密バリデーションは行っていない（理由：現場対応優先）

---
EOF

cat > docs/README.md <<'EOF'
# ドキュメント一覧

- ai/PROJECT_CONTEXT.md  
  → AIコード生成・AIレビュー用の前提条件（最重要）

- changes/CHANGELOG.md  
  → 変更理由と影響範囲の記録（必須）

- runbook/OPERATIONS.md  
  → 運用・トラブル対応

- db/DATABASE.md  
  → DB構造と業務上の意味

- api/API.md  
  → API / 画面I/F（あれば）

- tools/csharp/CSHARP_TOOLING.md  
  → C#/.NET ツール方針

- tools/python/PYTHON_TOOLING.md  
  → Python ツール方針

※ コード変更時は、必ずどれかの文書を更新すること（最低限 CHANGELOG）
EOF

# ---------
# 7) C# tooling docs/templates
# ---------
cat > docs/tools/csharp/CSHARP_TOOLING.md <<'EOF'
# C# ツール方針（加美電機向け）

この文書は C#/.NET で作る社内ツールの共通方針。
最優先は docs/ai/PROJECT_CONTEXT.md の前提。

## 対象ユースケース（典型）
- 検査装置ログの取り込み/整形（CSV/TSV/独自形式）
- DBへの投入・抽出（MySQL/MariaDB）
- 現場向け小規模GUI/CLI
- 既存資産（古いコード/手作業）を段階的に置換

## 必須ルール
- 可能な限りコメントを残す（why/業務的意味/前提/例外/暫定処置）。
- 実装変更時は必ずドキュメントも更新する（最低限 docs/changes/CHANGELOG.md）。
- 過剰設計・過剰抽象化は禁止。読みやすさ・追いやすさ優先。
- 例外・入力揺れ（文字コード、区切り、欠損、異常値）を前提に堅牢に作る。

## .NET 設計指針（現場向け）
- まずは「単一責務の小さなクラス」+「直線的な処理フロー」。
- DI/クリーンアーキテクチャ等は、保守が容易になる範囲に限定。
- ログは必須（Console/ファイル/必要ならDB）。障害解析できる粒度で。

## DBアクセス
- 原則：SQLが明確なら SQL を優先。
- ORM は状況次第（読みやすさが増すなら可）。
  - CRUD中心ならORM可
  - JOIN/集計/複雑条件はSQLの方が明確ならSQL優先
- 推奨：Dapper（SQLを保持しつつ薄い抽象）または ADO.NET（最小依存）
- 重要：クエリの意図・前提・例外をコメントで残す

## 実行形態
- CLI優先（現場PCで動く、手順が単純、ログ採取しやすい）
- GUIが必要なら WinForms/WPF を最小構成で（過剰なMVVMは避ける）
EOF

cat > docs/tools/csharp/NEW_TOOL_CHECKLIST.md <<'EOF'
# 新規 C# ツール作成チェックリスト

- [ ] 目的（誰が何のために使うか）が README に明記されている
- [ ] 入力（ファイル形式/エンコード/必須列/例外）を README に明記
- [ ] 出力（ファイル/DB/画面）を README に明記
- [ ] ログ出力があり、失敗時に原因が追える
- [ ] エラーハンドリング（入力不正/DB不通/権限）がある
- [ ] SQL/DB変更があるなら docs/db/DATABASE.md を更新
- [ ] 変更履歴として docs/changes/CHANGELOG.md を更新
- [ ] コメントが十分（why/前提/業務的意味/例外/暫定処置）
EOF

cat > tools/csharp/README.md <<'EOF'
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
EOF

# ---------
# 8) Python tooling docs/templates
# ---------
cat > docs/tools/python/PYTHON_TOOLING.md <<'EOF'
# Python ツール方針（加美電機向け）

この文書は Python で作る社内ツールの共通方針。
最優先は docs/ai/PROJECT_CONTEXT.md の前提。

## 対象ユースケース（典型）
- AOI/ICT ログの解析、集計、可視化（CSV/Excel）
- 製造データの前処理（欠損・外れ値・形式揺れの吸収）
- DB への投入・抽出（MySQL/MariaDB）
- バッチ処理・定期処理（cron等）

## 必須ルール
- 可能な限りコメントを残す（why/業務的意味/前提/例外/暫定処置）。
- 実装変更時は必ずドキュメントも更新する（最低限 docs/changes/CHANGELOG.md）。
- 過剰設計・過剰抽象化は禁止。読みやすさ・追いやすさ優先。
- 例外・入力揺れ（文字コード、区切り、欠損、異常値）を前提に堅牢に作る。

## Python 実装指針（現場向け）
- 入口は CLI（argparse）を基本。入出力を明確に。
- 依存は最小限。導入手順が簡単であることを優先。
- ログは必須（標準logging）。障害解析できる粒度で。

## データ処理
- pandas は可。ただし処理の意図が分かるように分割・コメントを書く。
- Excel入出力が絡む場合は、入力仕様（シート名/列名/型）を README に明記。

## DBアクセス
- 原則：SQLが明確なら SQL を優先。
- ORM は状況次第（読みやすさが増すなら可）。
  - CRUD中心ならORM可
  - JOIN/集計/複雑条件はSQLの方が明確ならSQL優先
- 推奨：SQLAlchemy Core（SQL寄り）または mysqlclient/pymysql + 生SQL（最小）
- 重要：クエリの意図・前提・例外をコメントで残す
EOF

cat > docs/tools/python/NEW_TOOL_CHECKLIST.md <<'EOF'
# 新規 Python ツール作成チェックリスト

- [ ] 目的（誰が何のために使うか）が README に明記されている
- [ ] 入力（CSV/Excel/ログ形式、エンコード、必須列、例外）を README に明記
- [ ] 出力（CSV/Excel/DB/グラフ/ログ）を README に明記
- [ ] ログ出力があり、失敗時に原因が追える
- [ ] エラーハンドリング（入力不正/DB不通/権限）がある
- [ ] SQL/DB変更があるなら docs/db/DATABASE.md を更新
- [ ] 変更履歴として docs/changes/CHANGELOG.md を更新
- [ ] コメントが十分（why/前提/業務的意味/例外/暫定処置）
EOF

cat > tools/python/README.md <<'EOF'
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
EOF

echo "DONE: All files created/updated."
echo "Next: git status && git add -A && git commit -m 'Bootstrap AI/tooling guardrails and docs templates (LAMP + C# + Python)'"
