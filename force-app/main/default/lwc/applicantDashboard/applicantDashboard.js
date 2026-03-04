import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getMyApplications from '@salesforce/apex/GrantApplicationController.getMyApplications';

export default class ApplicantDashboard extends NavigationMixin(LightningElement) {
    @track applications = [];
    @track selectedApplication = null;
    @track isLoading = true;
    @track showDetailModal = false;
    @track showApplicationForm = false;
    @track error;

    _wiredApplications;

    @wire(getMyApplications)
    wiredApplications(result) {
        this._wiredApplications = result;
        this.isLoading = false;
        const { error, data } = result;
        if (data) {
            this.applications = data.map(app => ({
                ...app,
                statusClass: this.getStatusClass(app.Status__c),
                statusIcon: this.getStatusIcon(app.Status__c),
                formattedDate: this.formatDate(app.CreatedDate),
                hasAward: app.Status__c === 'Approved' && app.Award_Amount__c
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'Failed to load applications';
            this.applications = [];
        }
    }

    get hasApplications() {
        return this.applications && this.applications.length > 0;
    }

    get noApplicationsMessage() {
        return 'You have not submitted any grant applications yet.';
    }

    getStatusClass(status) {
        const classes = {
            'Submitted': 'slds-badge slds-badge_lightest',
            'Under Review': 'slds-badge badge-review',
            'Approved': 'slds-badge slds-theme_success',
            'Rejected': 'slds-badge slds-theme_error'
        };
        return classes[status] || 'slds-badge';
    }

    getStatusIcon(status) {
        const icons = {
            'Submitted': 'utility:email',
            'Under Review': 'utility:clock',
            'Approved': 'utility:check',
            'Rejected': 'utility:close'
        };
        return icons[status] || 'utility:help';
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric' 
        });
    }

    handleViewDetails(event) {
        const appId = event.currentTarget.dataset.id;
        this.selectedApplication = this.applications.find(app => app.Id === appId);
        if (this.selectedApplication) {
            this.showDetailModal = true;
        }
    }

    closeDetailModal() {
        this.showDetailModal = false;
        this.selectedApplication = null;
    }

    handleNewApplication() {
        this.showApplicationForm = true;
    }

    handleLogout() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: { actionName: 'logout' }
        });
    }

    handleApplicationSubmitted() {
        this.showApplicationForm = false;
        refreshApex(this._wiredApplications);
    }

    handleBackToDashboard() {
        this.showApplicationForm = false;
    }

    get eligibilityRules() {
        if (!this.selectedApplication?.Eligibility_Results__c) return [];
        try {
            const result = JSON.parse(this.selectedApplication.Eligibility_Results__c);
            return (result.rules || []).map(rule => ({
                ...rule,
                iconName: rule.passed ? 'utility:success' : 'utility:error',
                iconVariant: rule.passed ? 'success' : 'error'
            }));
        } catch (e) {
            return [];
        }
    }

    get showReviewerComments() {
        return this.selectedApplication?.Status__c === 'Rejected' && 
               this.selectedApplication?.Reviewer_Comments__c;
    }

    get showAwardDetails() {
        return this.selectedApplication?.Status__c === 'Approved' && 
               this.selectedApplication?.Award_Amount__c;
    }

    get awardBreakdown() {
        if (!this.selectedApplication?.Award_Breakdown__c) return null;
        try {
            return JSON.parse(this.selectedApplication.Award_Breakdown__c);
        } catch (e) {
            return null;
        }
    }
}
