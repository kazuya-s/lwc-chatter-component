# 02: Apex コントローラー実装

## ステータス: 完了

## 作業内容

- [x] `ChatterFeedController.cls` 作成
  - `getRecordFeed(recordId)`: レコードに紐づくChatterフィードを取得
  - `getPublicFeed()`: グローバルChatterフィードを取得
  - `@AuraEnabled(cacheable=true)` 修飾子
  - 返却型: `List<Map<String, Object>>`（LWCで扱いやすい形式）
- [ ] `ChatterFeedController.cls-meta.xml` 作成
- [ ] `ChatterFeedControllerTest.cls` 作成
  - ConnectApi モックを使用
  - カバレッジ 75% 以上
- [ ] `ChatterFeedControllerTest.cls-meta.xml` 作成

## 技術メモ

```apex
// ConnectApi でChatterフィードを取得
ConnectApi.FeedItemPage page = ConnectApi.ChatterFeeds.getFeedItemsFromFeed(
    null,
    ConnectApi.FeedType.Record,
    recordId
);

// テスト時はモックを設定
ConnectApi.FeedItemPage mockPage = new ConnectApi.FeedItemPage();
ConnectApi.ChatterFeeds.setTestGetFeedItemsFromFeed(null, ConnectApi.FeedType.Record, recordId, mockPage);
```

## 依存関係

- Phase 1 完了後に着手可能
- Phase 3（LWC）と並列実行可能
