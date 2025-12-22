# 新規 Python ツール作成チェックリスト

- [ ] 目的（誰が何のために使うか）が README に明記されている
- [ ] 入力（CSV/Excel/ログ形式、エンコード、必須列、例外）を README に明記
- [ ] 出力（CSV/Excel/DB/グラフ/ログ）を README に明記
- [ ] ログ出力があり、失敗時に原因が追える
- [ ] エラーハンドリング（入力不正/DB不通/権限）がある
- [ ] SQL/DB変更があるなら docs/db/DATABASE.md を更新
- [ ] 変更履歴として docs/changes/CHANGELOG.md を更新
- [ ] コメントが十分（why/前提/業務的意味/例外/暫定処置）
