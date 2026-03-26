import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getRecordFeed from '@salesforce/apex/ChatterFeedController.getRecordFeed';
import getPublicFeed from '@salesforce/apex/ChatterFeedController.getPublicFeed';
import getComments from '@salesforce/apex/ChatterFeedController.getComments';
import postComment from '@salesforce/apex/ChatterFeedController.postComment';

export default class ChatterFeedExpanded extends LightningElement {
    /** レコードページで自動設定されるレコードId */
    @api recordId;

    /** グローバルフィードを使用するか（App Builderで設定） */
    @api useGlobalFeed = false;

    /** 1ページの表示件数（App Builderで設定） */
    @api pageSize = 25;

    @track feedItems = [];
    @track isLoading = true;
    @track errorMessage = null;

    // ページ参照からrecordIdを補完する（必要な場合）
    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (pageRef && pageRef.attributes && pageRef.attributes.recordId && !this.recordId) {
            this.recordId = pageRef.attributes.recordId;
        }
    }

    connectedCallback() {
        this.loadFeed();
    }

    async loadFeed() {
        this.isLoading = true;
        this.errorMessage = null;

        try {
            let items;
            if (this.useGlobalFeed || !this.recordId) {
                items = await getPublicFeed({ pageSize: this.pageSize });
            } else {
                items = await getRecordFeed({
                    recordId: this.recordId,
                    pageSize: this.pageSize
                });
            }

            const mapped = items.map(item => ({
                ...item,
                createdDate: item.createdDate ? new Date(item.createdDate).toISOString() : null,
                comments: [],
                showComments: false
            }));
            this.feedItems = mapped;

            // コメントがある投稿のコメントを並行取得
            const commentLoads = mapped
                .filter(item => item.commentCount > 0)
                .map(item => this.loadComments(item.id));
            await Promise.all(commentLoads);
        } catch (error) {
            this.errorMessage = error.body
                ? error.body.message
                : 'Chatterフィードの取得に失敗しました。';
            console.error('[ChatterFeedExpanded] Error loading feed:', error);
        } finally {
            this.isLoading = false;
        }
    }

    async loadComments(feedItemId) {
        try {
            const comments = await getComments({ feedItemId, pageSize: 50 });
            const mapped = comments.map(c => ({
                ...c,
                createdDate: c.createdDate ? new Date(c.createdDate).toISOString() : null
            }));
            this.feedItems = this.feedItems.map(item =>
                item.id === feedItemId ? { ...item, comments: mapped } : item
            );
        } catch (error) {
            console.error('[ChatterFeedExpanded] Error loading comments:', feedItemId, error);
        }
    }

    get hasFeedItems() {
        return !this.isLoading && !this.errorMessage && this.feedItems.length > 0;
    }

    get hasError() {
        return !this.isLoading && !!this.errorMessage;
    }

    handleReplyClick(event) {
        const feedItemId = event.currentTarget.dataset.id;
        this.feedItems = this.feedItems.map(item =>
            item.id === feedItemId
                ? { ...item, showReplyBox: !item.showReplyBox, replyBody: '', replyError: null }
                : item
        );
    }

    handleReplyInput(event) {
        const feedItemId = event.currentTarget.dataset.id;
        const value = event.target.value;
        this.feedItems = this.feedItems.map(item =>
            item.id === feedItemId ? { ...item, replyBody: value } : item
        );
    }

    async handleReplySubmit(event) {
        const feedItemId = event.currentTarget.dataset.id;
        const item = this.feedItems.find(i => i.id === feedItemId);
        if (!item || !item.replyBody || !item.replyBody.trim()) return;

        this.feedItems = this.feedItems.map(i =>
            i.id === feedItemId ? { ...i, isPosting: true, replyError: null } : i
        );

        try {
            const newComment = await postComment({ feedItemId, body: item.replyBody.trim() });
            const mapped = {
                ...newComment,
                createdDate: newComment.createdDate ? new Date(newComment.createdDate).toISOString() : null
            };
            this.feedItems = this.feedItems.map(i => {
                if (i.id !== feedItemId) return i;
                return {
                    ...i,
                    comments: [...i.comments, mapped],
                    commentCount: i.commentCount + 1,
                    showReplyBox: false,
                    replyBody: '',
                    isPosting: false
                };
            });
        } catch (error) {
            const msg = error.body ? error.body.message : 'コメントの投稿に失敗しました。';
            this.feedItems = this.feedItems.map(i =>
                i.id === feedItemId ? { ...i, isPosting: false, replyError: msg } : i
            );
        }
    }

    handleReplyCancel(event) {
        const feedItemId = event.currentTarget.dataset.id;
        this.feedItems = this.feedItems.map(item =>
            item.id === feedItemId ? { ...item, showReplyBox: false, replyBody: '', replyError: null } : item
        );
    }

    /** 再読み込みボタン用（将来の拡張） */
    handleRefresh() {
        this.loadFeed();
    }
}
