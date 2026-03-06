import { LightningElement, api, track } from 'lwc';
import login from '@salesforce/apex/CustomLoginController.login';
import basePath from '@salesforce/community/basePath';

export default class CustomLogin extends LightningElement {
    @api forgotPasswordUrl = '/forgot-password';
    @api selfRegisterUrl = '/register';
    
    @track username = '';
    @track password = '';
    @track errorMessage = '';
    @track isLoading = false;
    @track showPassword = false;

    get passwordType() {
        return this.showPassword ? 'text' : 'password';
    }

    get eyeIcon() {
        return this.showPassword ? 'utility:hide' : 'utility:preview';
    }

    get eyeTitle() {
        return this.showPassword ? 'Hide password' : 'Show password';
    }

    get isLoginDisabled() {
        return !this.username || !this.password || this.isLoading;
    }

    get forgotPasswordLink() {
        return basePath + this.forgotPasswordUrl;
    }

    get registerLink() {
        return basePath + this.selfRegisterUrl;
    }

    handleUsernameChange(event) {
        this.username = event.target.value;
        this.errorMessage = '';
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
        this.errorMessage = '';
    }

    togglePasswordVisibility() {
        this.showPassword = !this.showPassword;
    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleLogin();
        }
    }

    async handleLogin() {
        if (this.isLoginDisabled) return;

        this.isLoading = true;
        this.errorMessage = '';

        try {
            const result = await login({ 
                username: this.username, 
                password: this.password,
                startUrl: basePath + '/dashboard'
            });
            
            if (result) {
                window.location.href = result;
            }
        } catch (error) {
            this.errorMessage = error.body?.message || 'Invalid username or password. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }
}
