import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkEligibility from '@salesforce/apex/GrantEligibilityService.checkEligibility';
import saveApplication from '@salesforce/apex/GrantApplicationController.saveApplication';

export default class GrantApplicationForm extends LightningElement {
    @track currentSection = 1;
    @track isLoading = false;
    @track eligibilityResult = null;
    @track uploadedFiles = [];
    @track showConfirmation = false;
    @track savedApplicationNumber = '';
    
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
            { label: 'Food Security', value: 'Food Security' },
            { label: 'Housing Assistance', value: 'Housing Assistance' },
            { label: 'Job Training', value: 'Job Training' },
            { label: 'Health Services', value: 'Health Services' },
            { label: 'Education', value: 'Education' },
            { label: 'Environmental', value: 'Environmental' },
            { label: 'Arts & Culture', value: 'Arts & Culture' },
            { label: 'Other', value: 'Other' }
        ];
    }

    get isSection1() {
        return this.currentSection === 1;
    }

    get isSection2() {
        return this.currentSection === 2;
    }

    get showEligibilityPanel() {
        return this.eligibilityResult !== null;
    }

    get isEligible() {
        return this.eligibilityResult?.isEligible === true;
    }

    get eligibilityStatusClass() {
        return this.isEligible 
            ? 'slds-box slds-theme_success slds-m-bottom_medium'
            : 'slds-box slds-theme_error slds-m-bottom_medium';
    }

    get eligibilityStatusText() {
        if (!this.eligibilityResult) return '';
        return this.isEligible 
            ? `Eligible - ${this.eligibilityResult.totalPassed}/6 criteria met`
            : `Not Eligible - ${this.eligibilityResult.totalPassed}/6 criteria met`;
    }

    get formattedRules() {
        if (!this.eligibilityResult || !this.eligibilityResult.rules) {
            return [];
        }
        return this.eligibilityResult.rules.map(rule => ({
            ...rule,
            iconName: rule.passed ? 'utility:success' : 'utility:error',
            altText: rule.passed ? 'Passed' : 'Failed'
        }));
    }

    get isNextDisabled() {
        return !this.isEligible;
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
            this.calculateEligibility();
        }
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

        try {
            this.eligibilityResult = await checkEligibility({
                organizationType: organizationType || null,
                yearFounded: yearFounded ? parseInt(yearFounded, 10) : null,
                annualBudget: annualBudget ? parseFloat(annualBudget) : null,
                amountRequested: amountRequested ? parseFloat(amountRequested) : null,
                totalProjectCost: totalProjectCost ? parseFloat(totalProjectCost) : null,
                numBeneficiaries: numBeneficiaries ? parseInt(numBeneficiaries, 10) : null
            });
        } catch (error) {
            console.error('Eligibility check error:', error);
        }
    }

    handleNextSection() {
        if (this.validateSection1()) {
            this.currentSection = 2;
            window.scrollTo(0, 0);
        }
    }

    handlePreviousSection() {
        this.currentSection = 1;
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

        if (!this.isEligible) {
            isValid = false;
            this.showToast('Error', 'Your organization must meet all eligibility criteria to proceed', 'error');
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
                this.showToast('Error', 'Please fill in all required fields', 'error');
                break;
            }
        }

        return isValid;
    }

    handleUploadFinished(event) {
        const files = event.detail.files;
        this.uploadedFiles = [...this.uploadedFiles, ...files];
        this.showToast('Success', `${files.length} file(s) uploaded`, 'success');
    }

    handleRemoveFile(event) {
        const index = event.target.dataset.index;
        this.uploadedFiles = this.uploadedFiles.filter((_, i) => i !== parseInt(index, 10));
    }

    async handleSubmit() {
        if (!this.validateSection2()) {
            return;
        }

        this.isLoading = true;

        try {
            const applicationData = {
                ...this.formData,
                eligibilityJSON: JSON.stringify(this.eligibilityResult),
                files: null
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
                this.showToast('Success', `Application ${result.applicationNumber} submitted successfully!`, 'success');
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
}
