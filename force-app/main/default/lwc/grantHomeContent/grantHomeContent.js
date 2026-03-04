import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class GrantHomeContent extends NavigationMixin(LightningElement) {
    handleLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: { actionName: 'login' }
        });
    }
}
