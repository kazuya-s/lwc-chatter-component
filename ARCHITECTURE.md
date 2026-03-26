# ARCHITECTURE.md

## 問題

SalesforceモバイルアプリのChatterビューでは、長い投稿が自動的に折りたたまれる。
標準UIには折りたたみを無効化する設定がないため、カスタムLWCコンポーネントで解決する。

## アーキテクチャ

```
[Salesforce Mobile App]
        ↓
[chatterFeedExpanded LWC]
        ↓ @wire / imperative Apex call
[ChatterFeedController.cls]
        ↓ ConnectApi
[Chatter Feed Items]
```

## コンポーネント詳細

### `ChatterFeedController.cls` (Apex)

- `ConnectApi.ChatterFeeds.getFeedItemsFromFeed()` を使用してChatterフィードを取得
- `@AuraEnabled(cacheable=true)` メソッドでLWCから呼び出し可能
- レコードページ用（recordId引数あり）とグローバルフィード用の2メソッドを提供

### `chatterFeedExpanded` (LWC)

| ファイル | 役割 |
|---------|------|
| `.js` | Apexメソッド呼び出し、データ整形、ページネーション |
| `.html` | 投稿リスト表示テンプレート（show-moreなし） |
| `.css` | 折りたたみ無効化CSS、モバイル対応レイアウト |
| `.js-meta.xml` | App Builder配置設定、モバイルtargets |

## 折りたたみ無効化の技術的アプローチ

標準Chatterでは以下のCSSで折りたたみを実装している:
```css
-webkit-line-clamp: 3;
overflow: hidden;
```

本コンポーネントではこれを明示的にリセットし、全文表示する:
```css
.feed-body {
    -webkit-line-clamp: unset;
    overflow: visible;
    white-space: pre-wrap;
    word-break: break-word;
}
```

## モバイル対応

`js-meta.xml` に以下の targets を設定してモバイルナビゲーションに追加可能にする:
- `lightning__RecordPage` - レコード詳細ページ
- `lightning__AppPage` - カスタムアプリページ
- `lightning__MobileNavigation` - モバイルナビゲーション

## テスト方針

- Apex: `ConnectApi.FeedElement` のモックを使用（`@IsTest` スコープ内）
- LWC: Jest（`@salesforce/lwc-jest`）でコンポーネントのレンダリングを検証
- ScratchOrg: 実際のChatter投稿で長文表示を目視確認

## 制限事項

- ConnectApi はScratchOrgまたはDeveloper Edition以上のOrg必須
- Chatter機能がOrg設定で有効化されている必要がある
- ScratchOrg は最大30日で期限切れになる
