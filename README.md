# lwc-chatter-component

SalesforceモバイルアプリのChatter長文折りたたみ問題を解消するLWCコンポーネントです。

## 概要

Salesforceモバイルアプリの標準ChatterビューはCSSの `-webkit-line-clamp` により長い投稿を自動折りたたみします。このコンポーネントはその制限を回避し、投稿を常に全文表示します。

## 構成

```
force-app/main/default/
├── classes/
│   ├── ChatterFeedController.cls       # Apex: FeedItemをSOQLで取得
│   └── ChatterFeedControllerTest.cls   # Apexテスト
└── lwc/
    └── chatterFeedExpanded/
        ├── chatterFeedExpanded.html    # 投稿リスト表示テンプレート
        ├── chatterFeedExpanded.js      # Apex呼び出し・データ整形
        ├── chatterFeedExpanded.css     # 折りたたみ無効化CSS
        └── chatterFeedExpanded.js-meta.xml
```

## セットアップ

### 前提条件

- Salesforce CLI (`sf`) がインストール済み
- Dev Hub org への接続済み（`sf org login web --set-default-dev-hub`）

### ScratchOrg 作成 〜 デプロイ

```bash
./scripts/setup-scratch-org.sh
```

### デプロイのみ（ScratchOrg作成済みの場合）

```bash
sf project deploy start --source-dir force-app
```

### テスト実行

```bash
sf apex run test --test-level RunLocalTests --wait 10
```

### ScratchOrgをブラウザで開く

```bash
./scripts/open-org.sh
```

## 使い方

コンポーネントは Lightning App Builder から配置します。

| 配置場所 | 挙動 |
|---------|------|
| レコードページ | そのレコードのChatterフィードを全文表示 |
| アプリページ / ホームページ | グローバルChatterフィードを全文表示 |

### App Builderのプロパティ

| プロパティ | 説明 | デフォルト |
|-----------|------|----------|
| 表示件数 | 1ページに表示するChatter投稿の最大件数 | 25 |
| グローバルフィードを表示 | ONにするとグローバルフィードを表示（アプリページ/ホームページ用） | false |

## 技術的アプローチ

標準Chatterの折りたたみCSSを明示的にリセットすることで全文表示を実現します。

```css
.feed-body {
    -webkit-line-clamp: unset !important;
    overflow: visible !important;
    max-height: none !important;
    white-space: pre-wrap;
}
```

Apexコントローラーは `FeedItem` オブジェクトをSOQLで直接取得します。

```apex
SELECT Id, CreatedBy.Name, Body, CommentCount, LikeCount, CreatedDate
FROM FeedItem
WHERE ParentId = :recordId
ORDER BY LastModifiedDate DESC
LIMIT :pageSize
```

## 開発

### ブランチ戦略

- `main` : 本番デプロイ済みコード
- `feature/*` : 機能開発

### Apexカバレッジ要件

テストカバレッジ 75% 以上を維持してください。

```bash
sf apex run test --test-level RunLocalTests --code-coverage --wait 10
```
