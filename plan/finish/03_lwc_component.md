# 03: LWC コンポーネント実装

## ステータス: 完了

## 作業内容

- [x] `chatterFeedExpanded.js` 作成
  - `@wire` または imperative呼び出しでApexメソッドを使用
  - `recordId` プロパティ（`@api`）でレコードページ対応
  - フィードデータの整形（投稿者名・日時・本文）
- [ ] `chatterFeedExpanded.html` 作成
  - `for:each` でフィード一覧表示
  - `show-more` ボタンなし
  - リッチテキスト対応
- [ ] `chatterFeedExpanded.css` 作成
  - `-webkit-line-clamp: unset` で折りたたみ無効化
  - `overflow: visible`
  - `white-space: pre-wrap`
  - モバイル対応レイアウト
- [ ] `chatterFeedExpanded.js-meta.xml` 作成
  - `isExposed: true`
  - targets: RecordPage, AppPage, MobileNavigation

## 技術メモ

```html
<!-- 折りたたみなしで本文表示 -->
<div class="feed-body" lwc:ref="feedBody">
    <lightning-formatted-rich-text value={item.body}></lightning-formatted-rich-text>
</div>
```

```css
.feed-body {
    -webkit-line-clamp: unset !important;
    overflow: visible !important;
    white-space: pre-wrap;
    word-break: break-word;
}
```

## 依存関係

- Phase 1 完了後に着手可能
- Phase 2（Apex）と並列実行可能
- Phase 2 完了後に Apex 連携部分を統合する
