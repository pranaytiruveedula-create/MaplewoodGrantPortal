import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkEligibility from '@salesforce/apex/GrantEligibilityService.checkEligibility';
import saveApplication from '@salesforce/apex/GrantApplicationController.saveApplication';
import basePath from '@salesforce/community/basePath';

export default class GrantApplicationForm extends LightningElement {
    @track currentSection = 1;
    @track isLoading = false;
    @track eligibilityResult = null;
    @track uploadedFiles = [];
    @track showConfirmation = false;
    @track savedApplicationNumber = '';

    _eligibilityDebounceTimer = null;
    _eligibilitySequence = 0;
    
    @track formData = {
        organizationName: '',
        organizationType: '',
        ein: '',
        yearFounded: null,
        annualBudget: null,
        missionStatement: '',
        organizationAddress: '',
        contactName: '',
        contactTitle: '',
        contactEmail: '',
        contactPhone: '',
        projectTitle: '',
        projectCategory: '',
        projectDescription: '',
        targetPopulation: '',
        projectStartDate: null,
        projectEndDate: null,
        amountRequested: null,
        totalProjectCost: null,
        numBeneficiaries: null
    };

    get organizationTypeOptions() {
        return [
            { label: '-- Select --', value: '' },
            { label: '501(c)(3) Nonprofit', value: '501(c)(3)' },
            { label: '501(c)(4) Nonprofit', value: '501(c)(4)' },
            { label: 'Community-Based Organization', value: 'Community-Based Organization' },
            { label: 'Faith-Based Organization', value: 'Faith-Based Organization' },
            { label: 'For-Profit Corporation', value: 'For-Profit Corporation' },
            { label: 'Government Entity', value: 'Government Entity' }
        ];
    }

    get projectCategoryOptions() {
        return [
            { label: '-- Select --', value: '' },
            { label: 'Youth Programs', value: 'Youth Programs' },
            { label: 'Senior Services', value: 'Senior Services' },
            { label: 'Public Health', value: 'Public Health' },
            { label: 'Neighborhood Safety', value: 'Neighborhood Safety' },
            { label: 'Arts & Culture', value: 'Arts & Culture' },
            { label: 'Workforce Development', value: 'Workforce Development' },
            { label: 'Other', value: 'Other' }
        ];
    }

    get isSection1() {
        return this.currentSection === 1;
    }

    get isSection2() {
        return this.currentSection === 2;
    }

    get isSection3() {
        return this.currentSection === 3;
    }

    get step1Class() {
        if (this.currentSection === 1) return 'step active';
        return 'step completed';
    }

    get step2Class() {
        if (this.currentSection === 2) return 'step active';
        if (this.currentSection > 2) return 'step completed';
        return 'step';
    }

    get step3Class() {
        if (this.currentSection === 3) return 'step active';
        return 'step';
    }

    get eligibilitySummaryBadgeClass() {
        if (!this.eligibilityResult) return 'badge badge-pending';
        return this.isEligible ? 'badge badge-eligible' : 'badge badge-not-eligible';
    }

    get hasEligibilityResult() {
        return this.eligibilityResult !== null;
    }

    get isEligible() {
        return this.eligibilityResult?.isEligible === true;
    }

    get eligibilityStatusColorClass() {
        if (!this.eligibilityResult) return 'pending';
        return this.isEligible ? 'eligible' : 'not-eligible';
    }

    get eligibilityStatusIcon() {
        return this.isEligible ? 'utility:success' : 'utility:error';
    }

    get eligibilityStatusLabel() {
        if (!this.eligibilityResult) return 'Not Yet Evaluated';
        return this.isEligible ? 'Eligible' : 'Not Eligible';
    }

    get allRules() {
        const defaultRules = [
            { ruleId: 'R1', ruleName: 'Nonprofit Status', message: 'Select an organization type', statusClass: 'pending', iconName: 'utility:dash', altText: 'Pending' },
            { ruleId: 'R2', ruleName: 'Operating History', message: 'Enter year founded', statusClass: 'pending', iconName: 'utility:dash', altText: 'Pending' },
            { ruleId: 'R3', ruleName: 'Budget Cap', message: 'Enter annual budget', statusClass: 'pending', iconName: 'utility:dash', altText: 'Pending' },
            { ruleId: 'R4', ruleName: 'Funding Ratio', message: 'Enter amount requested and total cost', statusClass: 'pending', iconName: 'utility:dash', altText: 'Pending' },
            { ruleId: 'R5', ruleName: 'Maximum Request', message: 'Enter amount requested', statusClass: 'pending', iconName: 'utility:dash', altText: 'Pending' },
            { ruleId: 'R6', ruleName: 'Minimum Impact', message: 'Enter number of beneficiaries', statusClass: 'pending', iconName: 'utility:dash', altText: 'Pending' }
        ];

        if (!this.eligibilityResult || !this.eligibilityResult.rules) {
            return defaultRules;
        }

        return this.eligibilityResult.rules.map(rule => ({
            ...rule,
            statusClass: rule.passed ? 'passed' : 'failed',
            iconName: rule.passed ? 'utility:success' : 'utility:error',
            altText: rule.passed ? 'Passed' : 'Failed'
        }));
    }

    get isNextDisabled() {
        return false;
    }

    get hasUploadedFiles() {
        return this.uploadedFiles && this.uploadedFiles.length > 0;
    }

    get acceptedFormats() {
        return ['.pdf', '.doc', '.docx', '.xls', '.xlsx'];
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        let value = event.detail?.value ?? event.target.value;
        
        if (event.target.type === 'number') {
            value = value ? Number(value) : null;
        }
        
        this.formData = { ...this.formData, [field]: value };
        
        if (this.shouldRecalculateEligibility(field)) {
            clearTimeout(this._eligibilityDebounceTimer);
            this._eligibilityDebounceTimer = setTimeout(() => {
                this.calculateEligibility();
            }, 400);
        }
    }

    handlePhoneChange(event) {
        const field = event.target.dataset.field;
        let value = event.detail?.value ?? event.target.value;
        
        const digits = value.replace(/\D/g, '').substring(0, 10);
        
        let formatted = '';
        if (digits.length > 0) {
            formatted = '(' + digits.substring(0, 3);
        }
        if (digits.length >= 3) {
            formatted += ') ' + digits.substring(3, 6);
        }
        if (digits.length >= 6) {
            formatted += '-' + digits.substring(6, 10);
        }
        
        this.formData = { ...this.formData, [field]: formatted };
        
        event.target.value = formatted;
    }

    shouldRecalculateEligibility(field) {
        const eligibilityFields = [
            'organizationType', 
            'yearFounded', 
            'annualBudget',
            'amountRequested', 
            'totalProjectCost', 
            'numBeneficiaries'
        ];
        return eligibilityFields.includes(field);
    }

    async calculateEligibility() {
        const { organizationType, yearFounded, annualBudget, 
                amountRequested, totalProjectCost, numBeneficiaries } = this.formData;
        
        if (!organizationType && !yearFounded && !annualBudget && 
            !amountRequested && !totalProjectCost && !numBeneficiaries) {
            this.eligibilityResult = null;
            return;
        }

        const seq = ++this._eligibilitySequence;

        try {
            const result = await checkEligibility({
                organizationType: organizationType || null,
                yearFounded: yearFounded ? parseInt(yearFounded, 10) : null,
                annualBudget: annualBudget ? parseFloat(annualBudget) : null,
                amountRequested: amountRequested ? parseFloat(amountRequested) : null,
                totalProjectCost: totalProjectCost ? parseFloat(totalProjectCost) : null,
                numBeneficiaries: numBeneficiaries ? parseInt(numBeneficiaries, 10) : null
            });
            if (seq === this._eligibilitySequence) {
                this.eligibilityResult = result;
            }
        } catch (error) {
            if (seq === this._eligibilitySequence) {
                console.error('Eligibility check error:', error);
            }
        }
    }

    handleNextSection() {
        if (this.validateSection1()) {
            this.currentSection = 2;
            window.scrollTo(0, 0);
        }
    }

    handlePreviousSection() {
        if (this.currentSection > 1) {
            this.currentSection = this.currentSection - 1;
        }
        window.scrollTo(0, 0);
    }

    handleNextToReview() {
        if (this.validateSection2()) {
            this.currentSection = 3;
            window.scrollTo(0, 0);
        }
    }

    handleEditSection1() {
        this.currentSection = 1;
        window.scrollTo(0, 0);
    }

    handleEditSection2() {
        this.currentSection = 2;
        window.scrollTo(0, 0);
    }

    validateSection1() {
        const requiredFields = [
            'organizationName', 'organizationType', 'ein', 'yearFounded',
            'annualBudget', 'missionStatement', 'organizationAddress',
            'contactName', 'contactEmail', 'contactPhone',
            'amountRequested', 'totalProjectCost', 'numBeneficiaries'
        ];

        let isValid = true;
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
        
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        for (const field of requiredFields) {
            if (!this.formData[field]) {
                isValid = false;
                this.showToast('Error', 'Please fill in all required fields', 'error');
                break;
            }
        }

        return isValid;
    }

    validateSection2() {
        const requiredFields = [
            'projectTitle', 'projectCategory', 'projectDescription',
            'targetPopulation', 'projectStartDate', 'projectEndDate'
        ];

        let isValid = true;
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
        
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        for (const field of requiredFields) {
            if (!this.formData[field]) {
                isValid = false;
                this.showToast('Error', 'Please fill in required field: ' + field, 'error');
                break;
            }
        }

        return isValid;
    }

    triggerFileInput() {
        this.template.querySelector('input[type="file"]').click();
    }

    handleFileSelect(event) {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        const maxSize = 5 * 1024 * 1024;

        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            
            if (file.size > maxSize) {
                this.showToast('Error', file.name + ' exceeds 5MB limit', 'error');
                continue;
            }

            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                this.uploadedFiles = [...this.uploadedFiles, {
                    name: file.name,
                    size: file.size,
                    sizeLabel: this.formatFileSize(file.size),
                    contentType: file.type,
                    base64Data: base64
                }];
            };
            reader.readAsDataURL(file);
        }

        event.target.value = '';
    }

    formatFileSize(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    }

    handleRemoveFile(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.uploadedFiles = this.uploadedFiles.filter((_, i) => i !== index);
    }

    async handleSubmit() {
        const requiredFields = [
            'projectTitle', 'projectCategory', 'projectDescription',
            'targetPopulation', 'projectStartDate', 'projectEndDate'
        ];
        
        for (const field of requiredFields) {
            if (!this.formData[field]) {
                this.showToast('Error', 'Please fill in the required field: ' + field, 'error');
                return;
            }
        }

        this.isLoading = true;

        try {
            const filesToUpload = this.uploadedFiles.map(f => ({
                fileName: f.name,
                base64Data: f.base64Data,
                contentType: f.contentType
            }));

            const applicationData = {
                ...this.formData,
                eligibilityJSON: JSON.stringify(this.eligibilityResult),
                files: filesToUpload.length > 0 ? filesToUpload : null
            };

            const savePromise = saveApplication({
                applicationJSON: JSON.stringify(applicationData)
            });

            const timeoutPromise = new Promise((_, reject) => {
                setTimeout(() => reject(new Error('Request timed out. Check your connection or contact support.')), 30000);
            });

            const result = await Promise.race([savePromise, timeoutPromise]);

            if (result.success) {
                this.savedApplicationNumber = result.applicationNumber;
                this.showConfirmation = true;
                this.showToast('Success', 'Application ' + result.applicationNumber + ' submitted successfully!', 'success');
                this.dispatchEvent(new CustomEvent('applicationsubmitted'));
            } else {
                this.showToast('Error', result.errorMessage || 'Failed to submit application', 'error');
            }
        } catch (error) {
            const msg = error.body?.message || error.message || (typeof error === 'string' ? error : 'Unable to submit. Ensure you are logged in and have access.');
            this.showToast('Error', msg, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleStartNewApplication() {
        this.resetForm();
    }

    handleBackToDashboard() {
        this.dispatchEvent(new CustomEvent('backtodashboard'));
    }

    resetForm() {
        this.currentSection = 1;
        this.eligibilityResult = null;
        this.uploadedFiles = [];
        this.showConfirmation = false;
        this.savedApplicationNumber = '';
        this.formData = {
            organizationName: '',
            organizationType: '',
            ein: '',
            yearFounded: null,
            annualBudget: null,
            missionStatement: '',
            organizationAddress: '',
            contactName: '',
            contactTitle: '',
            contactEmail: '',
            contactPhone: '',
            projectTitle: '',
            projectCategory: '',
            projectDescription: '',
            targetPopulation: '',
            projectStartDate: null,
            projectEndDate: null,
            amountRequested: null,
            totalProjectCost: null,
            numBeneficiaries: null
        };
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleLogout() {
        const sitePrefix = basePath.replace(/\/s$/i, '');
        window.location.href = sitePrefix + '/secur/logout.jsp';
    }
}
