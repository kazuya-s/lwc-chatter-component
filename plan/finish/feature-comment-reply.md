# Plan: コメント返信機能（完了）

## ブランチ
`feature/comment-reply`（完了）

## 最終設計方針

- **POST**: DML `insert FeedComment` でプレーンテキストとして保存（`lightning-textarea` 入力）
- **GET**: `ConnectApi.ChatterFeeds.getCommentsForFeedElement(null, feedItemId)` でセグメント取得 + HTML変換（SOQL + ConnectApi ハイブリッド）
- **表示**: `lightning-formatted-rich-text` でHTML表示

### セグメント → HTML 変換
| ConnectApi | HTML |
|-----------|------|
| `TextSegment` | テキスト（HTMLエスケープ + `\n`→`<br>`） |
| `MarkupBeginSegment(Bold)` | `<b>` |
| `MarkupEndSegment(Bold)` | `</b>` |
| `LinkSegment` | `<a href="url">text</a>` |

## 実装済み

### Apex (ChatterFeedController.cls)
- [x] `getComments`: ConnectApi + SOQL ハイブリッド
- [x] `postComment`: DML保存、戻り値は `plainTextToHtml()` 変換
- [x] `segmentsToHtml()`, `plainTextToHtml()`, `escapeHtml()` ヘルパー

### テスト（全19テスト、100%パス）
- [x] `ChatterFeedControllerTest.cls`
- [x] `ChatterFeedControllerCommentsTest.cls` (SeeAllData=true、ConnectApi用)

### LWC (chatterFeedExpanded)
- [x] `lightning-textarea` で返信入力（常時表示）
- [x] `lightning-formatted-rich-text` でコメント表示
