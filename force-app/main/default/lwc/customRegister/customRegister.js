import { LightningElement, api, track } from 'lwc';
import registerUser from '@salesforce/apex/CustomRegisterController.registerUser';
import basePath from '@salesforce/community/basePath';

export default class CustomRegister extends LightningElement {
    @api loginUrl = '/login';
    
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track password = '';
    @track confirmPassword = '';
    @track errorMessage = '';
    @track isLoading = false;
    @track showPassword = false;
    @track showConfirmPassword = false;
    @track registrationSuccess = false;

    get passwordType() {
        return this.showPassword ? 'text' : 'password';
    }

    get confirmPasswordType() {
        return this.showConfirmPassword ? 'text' : 'password';
    }

    get eyeIcon() {
        return this.showPassword ? 'utility:hide' : 'utility:preview';
    }

    get confirmEyeIcon() {
        return this.showConfirmPassword ? 'utility:hide' : 'utility:preview';
    }

    get eyeTitle() {
        return this.showPassword ? 'Hide password' : 'Show password';
    }

    get confirmEyeTitle() {
        return this.showConfirmPassword ? 'Hide password' : 'Show password';
    }

    get isRegisterDisabled() {
        return !this.firstName || !this.lastName || !this.email || 
               !this.password || !this.confirmPassword || 
               this.isLoading || !this.passwordsMatch || !this.isPasswordValid;
    }

    get passwordsMatch() {
        if (!this.password || !this.confirmPassword) return true;
        return this.password === this.confirmPassword;
    }

    get passwordMismatchError() {
        if (!this.confirmPassword) return '';
        return this.passwordsMatch ? '' : 'Passwords do not match';
    }

    get confirmPasswordClass() {
        if (!this.confirmPassword) return 'form-input password-input';
        return this.passwordsMatch 
            ? 'form-input password-input input-valid' 
            : 'form-input password-input input-error';
    }

    get showMatchIcon() {
        return this.confirmPassword && this.password;
    }

    get matchIcon() {
        return this.passwordsMatch ? 'utility:success' : 'utility:error';
    }

    get matchIconVariant() {
        return this.passwordsMatch ? 'success' : 'error';
    }

    get isPasswordValid() {
        if (!this.password) return true;
        return this.password.length >= 8;
    }

    get passwordStrengthMessage() {
        if (!this.password) return '';
        if (this.password.length < 8) return 'Password must be at least 8 characters';
        
        let strength = 0;
        if (this.password.length >= 8) strength++;
        if (/[A-Z]/.test(this.password)) strength++;
        if (/[a-z]/.test(this.password)) strength++;
        if (/[0-9]/.test(this.password)) strength++;
        if (/[^A-Za-z0-9]/.test(this.password)) strength++;
        
        if (strength <= 2) return 'Weak password';
        if (strength <= 3) return 'Fair password';
        if (strength <= 4) return 'Good password';
        return 'Strong password';
    }

    get passwordStrengthClass() {
        if (!this.password) return '';
        if (this.password.length < 8) return 'strength-weak';
        
        let strength = 0;
        if (this.password.length >= 8) strength++;
        if (/[A-Z]/.test(this.password)) strength++;
        if (/[a-z]/.test(this.password)) strength++;
        if (/[0-9]/.test(this.password)) strength++;
        if (/[^A-Za-z0-9]/.test(this.password)) strength++;
        
        if (strength <= 2) return 'strength-weak';
        if (strength <= 3) return 'strength-fair';
        if (strength <= 4) return 'strength-good';
        return 'strength-strong';
    }

    get loginLink() {
        return basePath + this.loginUrl;
    }

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
        this.errorMessage = '';
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
        this.errorMessage = '';
    }

    handleEmailChange(event) {
        this.email = event.target.value;
        this.errorMessage = '';
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
        this.errorMessage = '';
    }

    handleConfirmPasswordChange(event) {
        this.confirmPassword = event.target.value;
        this.errorMessage = '';
    }

    togglePasswordVisibility() {
        this.showPassword = !this.showPassword;
    }

    toggleConfirmPasswordVisibility() {
        this.showConfirmPassword = !this.showConfirmPassword;
    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleRegister();
        }
    }

    async handleRegister() {
        if (this.isRegisterDisabled) return;

        if (!this.passwordsMatch) {
            this.errorMessage = 'Passwords do not match.';
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        try {
            const result = await registerUser({
                firstName: this.firstName,
                lastName: this.lastName,
                email: this.email,
                password: this.password
            });
            
            if (result.success) {
                this.registrationSuccess = true;
            } else {
                this.errorMessage = result.message || 'Registration failed. Please try again.';
            }
        } catch (error) {
            this.errorMessage = error.body?.message || 'An error occurred during registration. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }

    handleGoToLogin() {
        window.location.href = this.loginLink;
    }
}
