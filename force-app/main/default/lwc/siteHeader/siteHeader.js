import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import { getRecord } from 'lightning/uiRecordApi';

export default class SiteHeader extends LightningElement {
    userId = Id;
    userName = 'User';
    currentPage = '';

    @wire(CurrentPageReference)
    setCurrentPageReference(pageRef) {
        if (pageRef) {
            this.currentPage = pageRef.attributes?.name || '';
        }
    }

    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else if (error) {
            console.error('Error loading user:', error);
        }
    }

    get isLoggedIn() {
        return !!this.userId;
    }
}
