import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';

export default class LoginRedirect extends LightningElement {
    get isGuestUser() {
        return isGuest;
    }
}
