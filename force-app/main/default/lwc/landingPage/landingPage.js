import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';

export default class LandingPage extends LightningElement {

    get isGuestUser() {
        return isGuest;
    }

    handleSignIn(event) {
        event.preventDefault();
        event.stopPropagation();
        
        const loginUrl = window.location.origin + '/grants/login';
        console.log('[LandingPage] Sign In clicked, navigating to:', loginUrl);
        window.location.assign(loginUrl);
    }

    handleRegister(event) {
        event.preventDefault();
        event.stopPropagation();
        
        const registerUrl = window.location.origin + '/grants/SelfRegister';
        console.log('[LandingPage] Register clicked, navigating to:', registerUrl);
        window.location.assign(registerUrl);
    }
}
