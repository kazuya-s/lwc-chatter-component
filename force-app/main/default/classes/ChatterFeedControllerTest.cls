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
        System.assertEquals(3, result.size(), '3件のフィードアイテムが返されるべき');

        Map<String, Object> firstItem = result[0];
        System.assertNotEquals(null, firstItem.get('id'), 'IDが設定されているべき');
        System.assertNotEquals(null, firstItem.get('actorName'), '投稿者名が設定されているべき');
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
            System.assert(e.getMessage().contains('recordId'), 'エラーメッセージに recordId が含まれるべき');
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
    static void testGetComments_success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :acc.Id LIMIT 1];

        // コメントを追加
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'テストコメント1');
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'テストコメント2');

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getComments(fi.Id, 25);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
        System.assertEquals(2, result.size(), '2件のコメントが返されるべき');

        Map<String, Object> first = result[0];
        System.assertNotEquals(null, first.get('id'), 'IDが設定されているべき');
        System.assertNotEquals(null, first.get('actorName'), '投稿者名が設定されているべき');
        System.assertEquals('テストコメント1', first.get('body'), 'コメント本文が正しく返されるべき');
    }

    @IsTest
    static void testGetComments_withDefaultPageSize() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :acc.Id LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getComments(fi.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
    }

    @IsTest
    static void testGetComments_withPageSizeLimit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :acc.Id LIMIT 1];

        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'コメントA');
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'コメントB');
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'コメントC');

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getComments(fi.Id, 2);
        Test.stopTest();

        System.assertEquals(2, result.size(), '件数制限が反映されるべき');
    }

    @IsTest
    static void testGetComments_blankFeedItemId_throwsException() {
        Test.startTest();
        try {
            ChatterFeedController.getComments('', 25);
            System.assert(false, '例外が発生するべき');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('feedItemId'), 'エラーメッセージに feedItemId が含まれるべき');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetComments_nullBody_returnsEmptyString() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :acc.Id LIMIT 1];
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = null);

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getComments(fi.Id, 25);
        Test.stopTest();

        System.assertEquals(1, result.size(), '1件返されるべき');
        System.assertEquals('', result[0].get('body'), 'bodyがnullの場合は空文字列が返されるべき');
    }

    // =========================================================================
    // フィールド値の検証テスト
    // =========================================================================

    @IsTest
    static void testGetRecordFeed_fieldValues() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        // 本文なしのフィードアイテム（Body=null）を追加
        insert new FeedItem(ParentId = acc.Id, Body = null, Type = 'TextPost');

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getRecordFeed(acc.Id, 25);
        Test.stopTest();

        Boolean foundEmpty = false;
        for (Map<String, Object> item : result) {
            if (item.get('body') == '') {
                foundEmpty = true;
            }
            // 全アイテムで必須フィールドが設定されていることを確認
            System.assertNotEquals(null, item.get('id'), 'IDが設定されているべき');
            System.assertNotEquals(null, item.get('createdDate'), '作成日が設定されているべき');
            System.assertNotEquals(null, item.get('modifiedDate'), '更新日が設定されているべき');
            System.assertNotEquals(null, item.get('actorId'), '投稿者IDが設定されているべき');
            System.assertNotEquals(null, item.get('actorName'), '投稿者名が設定されているべき');
            System.assertNotEquals(null, item.get('commentCount'), 'コメント数が設定されているべき');
            System.assertNotEquals(null, item.get('likeCount'), 'いいね数が設定されているべき');
        }
        System.assert(foundEmpty, 'bodyがnullの場合、空文字列が返されるべき');
    }
}
