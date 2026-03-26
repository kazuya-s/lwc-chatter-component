@IsTest(SeeAllData=true)
private class ChatterFeedControllerCommentsTest {

    @IsTest
    static void testGetComments_success() {
        Account acc = new Account(Name = 'コメントテスト用');
        insert acc;
        FeedItem fi = new FeedItem(ParentId = acc.Id, Body = 'テスト投稿', Type = 'TextPost');
        insert fi;
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'テストコメント1');
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'テストコメント2');

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getComments(fi.Id, 25);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
        System.assert(result.size() >= 2, '2件以上のコメントが返されるべき');

        Map<String, Object> first = result[0];
        System.assertNotEquals(null, first.get('id'), 'IDが設定されているべき');
        System.assertNotEquals(null, first.get('actorName'), '投稿者名が設定されているべき');
        System.assertNotEquals(null, first.get('body'), 'コメント本文が設定されているべき');
    }

    @IsTest
    static void testGetComments_withDefaultPageSize() {
        Account acc = new Account(Name = 'コメントテスト用2');
        insert acc;
        FeedItem fi = new FeedItem(ParentId = acc.Id, Body = 'テスト投稿2', Type = 'TextPost');
        insert fi;

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getComments(fi.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
    }

    @IsTest
    static void testGetComments_withPageSizeLimit() {
        Account acc = new Account(Name = 'コメントテスト用3');
        insert acc;
        FeedItem fi = new FeedItem(ParentId = acc.Id, Body = 'テスト投稿3', Type = 'TextPost');
        insert fi;
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'コメントA');
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'コメントB');
        insert new FeedComment(FeedItemId = fi.Id, CommentBody = 'コメントC');

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getComments(fi.Id, 2);
        Test.stopTest();

        System.assert(result.size() <= 2, '件数制限が反映されるべき');
    }

    @IsTest
    static void testGetComments_emptyComments_returnsEmpty() {
        Account acc = new Account(Name = 'コメントテスト用4');
        insert acc;
        FeedItem fi = new FeedItem(ParentId = acc.Id, Body = 'テスト投稿4', Type = 'TextPost');
        insert fi;

        Test.startTest();
        List<Map<String, Object>> result = ChatterFeedController.getComments(fi.Id, 25);
        Test.stopTest();

        System.assertNotEquals(null, result, '結果がnullであってはならない');
        System.assertEquals(0, result.size(), 'コメントなしの場合は空リストが返されるべき');
    }
}
