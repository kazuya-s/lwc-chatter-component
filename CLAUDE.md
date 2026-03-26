# CLAUDE.md

このファイルはセッションをまたいで維持される方針・ルールを記載します。

## プロジェクト概要

SalesforceモバイルアプリのChatter長文折りたたみ問題を解消するLWCコンポーネント。
ScratchOrgを使用して開発・テスト・デプロイを行います。

## 作業方針

### 計画管理
- 計画は `plan/` 配下にファイルとして保存する
- 完了した計画は `plan/finish/` に移動する
- 複数のClaudeが並列作業できるよう、計画は適切に分割する

### 並列作業ルール
- Phase 2（Apex）と Phase 3（LWC）は Phase 1 完了後、並列実行可能
- Phase 4（デプロイ確認）は Phase 2・3 の両方が完了してから実施

### Salesforce開発ルール
- 必ず ScratchOrg を使用してテストを行う
- Apex テストカバレッジは 75% 以上を維持する
- デプロイ前に `sf project deploy start --dry-run` で検証する
- ScratchOrg の有効期限は最大 30 日（デフォルト 7 日）

### コーディング規約
- LWC コンポーネント名: camelCase（例: `chatterFeedExpanded`）
- Apex クラス名: PascalCase（例: `ChatterFeedController`）
- テストクラスは対象クラス名 + `Test`（例: `ChatterFeedControllerTest`）

## ツール・コマンド

```bash
# ScratchOrg セットアップ（初回）
./scripts/setup-scratch-org.sh

# デプロイのみ（ScratchOrg作成済みの場合）
sf project deploy start --source-dir force-app

# テスト実行
sf apex run test --test-level RunLocalTests --wait 10

# ScratchOrg をブラウザで開く
./scripts/open-org.sh
```

## ファイル構成

```
/workspace
├── CLAUDE.md                          # 本ファイル
├── ARCHITECTURE.md                    # アーキテクチャ詳細
├── sfdx-project.json
├── .forceignore
├── config/
│   └── project-scratch-def.json       # ScratchOrg 定義
├── scripts/
│   ├── setup-scratch-org.sh           # ScratchOrg 作成〜デプロイ一括
│   └── open-org.sh                    # ブラウザで Org 表示
├── force-app/main/default/
│   ├── classes/
│   │   ├── ChatterFeedController.cls
│   │   ├── ChatterFeedControllerTest.cls
│   │   └── ...meta.xml
│   └── lwc/
│       └── chatterFeedExpanded/
└── plan/
    ├── finish/                        # 完了済み計画
    └── *.md                           # 未完了の計画
```
