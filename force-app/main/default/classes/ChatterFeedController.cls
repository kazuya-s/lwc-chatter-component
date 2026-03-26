public with sharing class ChatterFeedController {

    /**
     * レコードに紐づくChatterフィードを取得する
     * @param recordId 対象レコードのId
     * @param pageSize 1ページあたりの件数（デフォルト: 25）
     * @return フィードアイテムのリスト
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecordFeed(String recordId, Integer pageSize) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('recordId は必須です');
        }
        Integer size = (pageSize != null && pageSize > 0) ? pageSize : 25;

        List<FeedItem> items = [
            SELECT Id, CreatedById, CreatedBy.Name, Body, CommentCount, LikeCount,
                   CreatedDate, LastModifiedDate
            FROM FeedItem
            WHERE ParentId = :recordId
            ORDER BY LastModifiedDate DESC
            LIMIT :size
        ];

        return convertFeedItems(items);
    }

    /**
     * グローバルChatterフィードを取得する
     * @param pageSize 1ページあたりの件数（デフォルト: 25）
     * @return フィードアイテムのリスト
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPublicFeed(Integer pageSize) {
        Integer size = (pageSize != null && pageSize > 0) ? pageSize : 25;

        List<FeedItem> items = [
            SELECT Id, CreatedById, CreatedBy.Name, Body, CommentCount, LikeCount,
                   CreatedDate, LastModifiedDate
            FROM FeedItem
            ORDER BY LastModifiedDate DESC
            LIMIT :size
        ];

        return convertFeedItems(items);
    }

    /**
     * フィードアイテムに紐づくコメントを取得する（ConnectApi使用）
     * @param feedItemId 対象FeedItemのId
     * @param pageSize 取得件数（デフォルト: 25）
     * @return コメントのリスト（bodyはlightning-formatted-rich-text用HTML）
     */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getComments(String feedItemId, Integer pageSize) {
        if (String.isBlank(feedItemId)) {
            throw new AuraHandledException('feedItemId は必須です');
        }
        Integer size = (pageSize != null && pageSize > 0) ? pageSize : 25;

        // ConnectApiでbodyセグメントをHTMLに変換
        ConnectApi.CommentPage commentPage = ConnectApi.ChatterFeeds.getCommentsForFeedElement(
            null, feedItemId
        );
        Map<String, String> bodyById = new Map<String, String>();
        for (ConnectApi.Comment comment : commentPage.items) {
            bodyById.put(comment.id, segmentsToHtml(
                comment.body != null ? comment.body.messageSegments : null
            ));
        }

        // SOQLで投稿者情報を取得
        List<FeedComment> comments = [
            SELECT Id, CreatedById, CreatedBy.Name, CommentBody, CreatedDate
            FROM FeedComment
            WHERE FeedItemId = :feedItemId
            ORDER BY CreatedDate ASC
            LIMIT :size
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (FeedComment comment : comments) {
            Map<String, Object> c = new Map<String, Object>();
            c.put('id', comment.Id);
            c.put('createdDate', comment.CreatedDate);
            c.put('actorId', comment.CreatedById);
            c.put('actorName', comment.CreatedBy.Name);
            String html = bodyById.containsKey(comment.Id)
                ? bodyById.get(comment.Id)
                : plainTextToHtml(comment.CommentBody);
            c.put('body', html);
            result.add(c);
        }
        return result;
    }

    /**
     * フィード投稿にコメントを返信する
     * @param feedItemId 対象FeedItemのId
     * @param body コメント本文
     * @return 投稿したコメントの情報
     */
    @AuraEnabled
    public static Map<String, Object> postComment(String feedItemId, String body) {
        if (String.isBlank(feedItemId)) {
            throw new AuraHandledException('feedItemId は必須です');
        }
        if (String.isBlank(body)) {
            throw new AuraHandledException('コメント本文は必須です');
        }

        FeedComment comment = new FeedComment(
            FeedItemId = feedItemId,
            CommentBody = body
        );
        insert comment;

        FeedComment inserted = [
            SELECT Id, CreatedById, CreatedBy.Name, CommentBody, CreatedDate
            FROM FeedComment WHERE Id = :comment.Id LIMIT 1
        ];

        return new Map<String, Object>{
            'id'          => inserted.Id,
            'createdDate' => inserted.CreatedDate,
            'actorId'     => inserted.CreatedById,
            'actorName'   => inserted.CreatedBy.Name,
            'body'        => plainTextToHtml(inserted.CommentBody)
        };
    }

    /**
     * ConnectApi メッセージセグメントを lightning-formatted-rich-text 用 HTML に変換する
     */
    private static String segmentsToHtml(List<ConnectApi.MessageSegment> segments) {
        if (segments == null || segments.isEmpty()) return '';

        String html = '';
        for (ConnectApi.MessageSegment segment : segments) {
            if (segment instanceof ConnectApi.TextSegment) {
                String text = ((ConnectApi.TextSegment) segment).text;
                if (text != null) {
                    html += escapeHtml(text).replace('\n', '<br>');
                }
            } else if (segment instanceof ConnectApi.MarkupBeginSegment) {
                html += markupTypeToOpenTag(((ConnectApi.MarkupBeginSegment) segment).markupType);
            } else if (segment instanceof ConnectApi.MarkupEndSegment) {
                html += markupTypeToCloseTag(((ConnectApi.MarkupEndSegment) segment).markupType);
            } else if (segment instanceof ConnectApi.LinkSegment) {
                ConnectApi.LinkSegment link = (ConnectApi.LinkSegment) segment;
                html += '<a href="' + escapeHtml(link.url) + '">' + escapeHtml(link.text) + '</a>';
            }
        }
        return html;
    }

    private static String escapeHtml(String s) {
        if (s == null) return '';
        return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;');
    }

    private static String markupTypeToOpenTag(ConnectApi.MarkupType mt) {
        if (mt == ConnectApi.MarkupType.Bold) return '<b>';
        if (mt == ConnectApi.MarkupType.Italic) return '<i>';
        if (mt == ConnectApi.MarkupType.Underline) return '<u>';
        if (mt == ConnectApi.MarkupType.Strikethrough) return '<s>';
        return '';
    }

    private static String markupTypeToCloseTag(ConnectApi.MarkupType mt) {
        if (mt == ConnectApi.MarkupType.Bold) return '</b>';
        if (mt == ConnectApi.MarkupType.Italic) return '</i>';
        if (mt == ConnectApi.MarkupType.Underline) return '</u>';
        if (mt == ConnectApi.MarkupType.Strikethrough) return '</s>';
        return '';
    }

    /**
     * プレーンテキストを lightning-formatted-rich-text 用 HTML に変換する
     */
    private static String plainTextToHtml(String text) {
        if (String.isBlank(text)) return '';
        return escapeHtml(text).replace('\n', '<br>');
    }

    /**
     * FeedItem リストをLWCで扱いやすいMap形式に変換する
     */
    private static List<Map<String, Object>> convertFeedItems(List<FeedItem> items) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        for (FeedItem item : items) {
            Map<String, Object> feedItem = new Map<String, Object>();
            feedItem.put('id', item.Id);
            feedItem.put('createdDate', item.CreatedDate);
            feedItem.put('modifiedDate', item.LastModifiedDate);
            feedItem.put('actorId', item.CreatedById);
            feedItem.put('actorName', item.CreatedBy.Name);
            feedItem.put('actorPhotoUrl', null);
            feedItem.put('body', item.Body != null ? item.Body : '');
            feedItem.put('commentCount', item.CommentCount);
            feedItem.put('likeCount', item.LikeCount);
            result.add(feedItem);
        }

        return result;
    }
}
