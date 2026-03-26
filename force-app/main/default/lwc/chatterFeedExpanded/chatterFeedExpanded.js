import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getRecordFeed from '@salesforce/apex/ChatterFeedController.getRecordFeed';
import getPublicFeed from '@salesforce/apex/ChatterFeedController.getPublicFeed';

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

            this.feedItems = items.map(item => ({
                ...item,
                createdDate: item.createdDate ? new Date(item.createdDate).toISOString() : null
            }));
        } catch (error) {
            this.errorMessage = error.body
                ? error.body.message
                : 'Chatterフィードの取得に失敗しました。';
            console.error('[ChatterFeedExpanded] Error loading feed:', error);
        } finally {
            this.isLoading = false;
        }
    }

    get hasFeedItems() {
        return !this.isLoading && !this.errorMessage && this.feedItems.length > 0;
    }

    get hasError() {
        return !this.isLoading && !!this.errorMessage;
    }

    /** 再読み込みボタン用（将来の拡張） */
    handleRefresh() {
        this.loadFeed();
    }
}
