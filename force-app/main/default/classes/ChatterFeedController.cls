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
