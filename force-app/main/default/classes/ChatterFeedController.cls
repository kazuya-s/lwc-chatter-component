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

        String userId = UserInfo.getUserId();
        List<FeedItem> items = [
            SELECT Id, CreatedById, CreatedBy.Name, Body, CommentCount, LikeCount,
                   CreatedDate, LastModifiedDate,
                   (SELECT Id FROM FeedLikes WHERE InsertedById = :userId)
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

        String userId = UserInfo.getUserId();
        List<FeedItem> items = [
            SELECT Id, CreatedById, CreatedBy.Name, Body, CommentCount, LikeCount,
                   CreatedDate, LastModifiedDate,
                   (SELECT Id FROM FeedLikes WHERE InsertedById = :userId)
            FROM FeedItem
            ORDER BY LastModifiedDate DESC
            LIMIT :size
        ];

        return convertFeedItems(items);
    }

    /**
     * フィード投稿のいいねをトグルする（いいね ⇔ いいね解除）
     * @param feedItemId 対象FeedItemのId
     * @param currentlyLiked 現在いいね済みかどうか（クライアントから渡す）
     * @return { liked: Boolean, likeCount: Integer }
     */
    @AuraEnabled
    public static Map<String, Object> toggleLike(String feedItemId, Boolean currentlyLiked) {
        if (String.isBlank(feedItemId)) {
            throw new AuraHandledException('feedItemId は必須です');
        }

        String userId = UserInfo.getUserId();
        Boolean isNowLiked;

        if (currentlyLiked == true) {
            FeedItem fi = [
                SELECT Id, (SELECT Id FROM FeedLikes WHERE InsertedById = :userId)
                FROM FeedItem WHERE Id = :feedItemId LIMIT 1
            ];
            if (!fi.FeedLikes.isEmpty()) {
                delete fi.FeedLikes;
            }
            isNowLiked = false;
        } else {
            insert new FeedLike(FeedItemId = feedItemId);
            isNowLiked = true;
        }

        FeedItem updated = [SELECT LikeCount FROM FeedItem WHERE Id = :feedItemId LIMIT 1];
        return new Map<String, Object>{
            'liked' => isNowLiked,
            'likeCount' => updated.LikeCount
        };
    }
    
    /**
     * フィードアイテムに紐づくコメントを取得する
     * @param feedItemId 対象FeedItemのId
     * @param pageSize 取得件数（デフォルト: 25）
     * @return コメントのリスト
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getComments(String feedItemId, Integer pageSize) {
        if (String.isBlank(feedItemId)) {
            throw new AuraHandledException('feedItemId は必須です');
        }
        Integer size = (pageSize != null && pageSize > 0) ? pageSize : 25;

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
            c.put('body', comment.CommentBody != null ? comment.CommentBody : '');
            result.add(c);
        }
        return result;
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
            feedItem.put('isLiked', !item.FeedLikes.isEmpty());
            result.add(feedItem);
        }

        return result;
    }
}
