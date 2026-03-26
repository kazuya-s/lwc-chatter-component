@IsTest
private class ChatterFeedControllerTest {

    // =========================================================================
    // テストデータ準備
    // =========================================================================

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Chatterテスト用アカウント');
        insert acc;

        List<FeedItem> feedItems = new List<FeedItem>();
        for (Integer i = 0; i < 3; i++) {
            feedItems.add(new FeedItem(
                ParentId = acc.Id,
                Body = 'テスト投稿 ' + i + ' - ' + 'あ'.repeat(50),
                Type = 'TextPost'
            ));
        }
        insert feedItems;
    }

    // =========================================================================
    // getRecordFeed テスト
    // =========================================================================

    @IsTest
    static void testGetRecordFeed_success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getRecordFeed(acc.Id, 25);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
        System.assert(result.size() >= 3, '3件以上のフィードアイテムが返されるべき');

        Map<String, Object> firstItem = result[0];
        System.assertNotEquals(null, firstItem.get('id'), 'IDが設定されているべき');
        System.assertNotEquals(null, firstItem.get('actorId'), '投稿者IDが設定されているべき');
        System.assertNotEquals(null, firstItem.get('body'), '本文が設定されているべき');
    }

    @IsTest
    static void testGetRecordFeed_withDefaultPageSize() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        // pageSize を null で渡してデフォルト値（25）が使われることを確認
        List<Map<String, Object>> result = ChatterFeedController.getRecordFeed(acc.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
    }

    @IsTest
    static void testGetRecordFeed_withPageSizeLimit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getRecordFeed(acc.Id, 1);
        Test.stopTest();

        System.assertEquals(1, result.size(), '件数制限が反映されるべき');
    }

    @IsTest
    static void testGetRecordFeed_blankRecordId_throwsException() {
        Test.startTest();
        try {
            ChatterFeedController.getRecordFeed('', 25);
            System.assert(false, '例外が発生するべき');
        } catch (AuraHandledException e) {
            System.assert(true, '正しく例外がスローされた');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetRecordFeed_nullRecordId_throwsException() {
        Test.startTest();
        try {
            ChatterFeedController.getRecordFeed(null, 25);
            System.assert(false, '例外が発生するべき');
        } catch (AuraHandledException e) {
            System.assert(true, '正しく例外がスローされた');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetRecordFeed_noMatchingRecord_returnsEmpty() {
        // 存在しないレコードID
        String fakeId = '0011000000000001';

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getRecordFeed(fakeId, 25);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
        System.assertEquals(0, result.size(), 'フィードなしの場合は空リストが返されるべき');
    }

    // =========================================================================
    // getPublicFeed テスト
    // =========================================================================

    @IsTest
    static void testGetPublicFeed_success() {
        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getPublicFeed(25);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
        System.assert(result.size() >= 3, '3件以上のフィードアイテムが返されるべき');
    }

    @IsTest
    static void testGetPublicFeed_withDefaultPageSize() {
        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getPublicFeed(null);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
    }

    @IsTest
    static void testGetPublicFeed_withPageSizeLimit() {
        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getPublicFeed(1);
        Test.stopTest();

        System.assertEquals(1, result.size(), '件数制限が反映されるべき');
    }

    // =========================================================================
    // getComments テスト
    // =========================================================================

    @IsTest
    static void testGetComments_blankFeedItemId_throwsException() {
        Test.startTest();
        try {
            ChatterFeedController.getComments('', 25);
            System.assert(false, '例外が発生するべき');
        } catch (AuraHandledException e) {
            System.assert(true, '正しく例外がスローされた');
        }
        Test.stopTest();
    }

    // =========================================================================
    // postComment テスト
    // =========================================================================

    @IsTest
    static void testPostComment_success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :acc.Id LIMIT 1];

        Test.startTest();
        Map<String, Object> result = ChatterFeedController.postComment(fi.Id, 'テスト返信コメント');
        Test.stopTest();

        System.assertNotEquals(null, result.get('id'), 'IDが返されるべき');
        // bodyはplainTextToHtml変換後のHTML（特殊文字なしの場合そのまま）
        String body = (String) result.get('body');
        System.assert(body.contains('テスト返信コメント'), '本文が正しく返されるべき');
        System.assertNotEquals(null, result.get('actorId'), '投稿者IDが返されるべき');
        System.assertNotEquals(null, result.get('createdDate'), '作成日が返されるべき');
    }

    @IsTest
    static void testPostComment_blankFeedItemId_throwsException() {
        Test.startTest();
        try {
            ChatterFeedController.postComment('', 'コメント');
            System.assert(false, '例外が発生するべき');
        } catch (AuraHandledException e) {
            System.assert(true, '正しく例外がスローされた');
        }
        Test.stopTest();
    }

    @IsTest
    static void testPostComment_blankBody_throwsException() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :acc.Id LIMIT 1];

        Test.startTest();
        try {
            ChatterFeedController.postComment(fi.Id, '');
            System.assert(false, '例外が発生するべき');
        } catch (AuraHandledException e) {
            System.assert(true, '正しく例外がスローされた');
        }
        Test.stopTest();
    }

    // =========================================================================
    // フィールド値の検証テスト
    // =========================================================================

    @IsTest
    static void testGetRecordFeed_fieldValues() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getRecordFeed(acc.Id, 25);
        Test.stopTest();

        System.assert(result.size() > 0, '1件以上返されるべき');
        for (Map<String, Object> item : result) {
            // 全アイテムで必須フィールドが設定されていることを確認
            System.assertNotEquals(null, item.get('id'), 'IDが設定されているべき');
            System.assertNotEquals(null, item.get('createdDate'), '作成日が設定されているべき');
            System.assertNotEquals(null, item.get('modifiedDate'), '更新日が設定されているべき');
            System.assertNotEquals(null, item.get('actorId'), '投稿者IDが設定されているべき');
            System.assertNotEquals(null, item.get('commentCount'), 'コメント数が設定されているべき');
            System.assertNotEquals(null, item.get('likeCount'), 'いいね数が設定されているべき');
            System.assertNotEquals(null, item.get('body'), '本文が設定されているべき');
        }
    }
}
