import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApplicationsForReview from '@salesforce/apex/GrantReviewerController.getApplicationsForReview';
import getApplicationStats from '@salesforce/apex/GrantReviewerController.getApplicationStats';
import getApplicationDocuments from '@salesforce/apex/GrantReviewerController.getApplicationDocuments';
import calculateAward from '@salesforce/apex/GrantAwardService.calculateAward';
import approveApplication from '@salesforce/apex/GrantAwardService.approveApplication';
import rejectApplication from '@salesforce/apex/GrantAwardService.rejectApplication';
import setUnderReview from '@salesforce/apex/GrantAwardService.setUnderReview';

const COLUMNS = [
    { label: 'App ID', fieldName: 'Name', type: 'text', sortable: true },
    { label: 'Organization', fieldName: 'Organization_Name__c', type: 'text', sortable: true },
    { label: 'Project Title', fieldName: 'Project_Title__c', type: 'text' },
    { label: 'Amount Requested', fieldName: 'Amount_Requested__c', type: 'currency' },
    { label: 'Submitted', fieldName: 'CreatedDate', type: 'date', sortable: true },
    { label: 'Eligible', fieldName: 'Is_Eligible__c', type: 'boolean' },
    { label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true },
    {
        type: 'action',
        typeAttributes: { rowActions: [
            { label: 'Review', name: 'review' }
        ]}
    }
];

export default class ReviewerDashboard extends LightningElement {
    @track applications = [];
    @track stats = {};
    @track selectedApplication = null;
    @track awardPreview = null;
    @track isLoading = false;
    @track showReviewModal = false;
    @track showApproveModal = false;
    @track showRejectModal = false;
    @track rejectComments = '';
    @track approveComments = '';
    @track filterStatus = '';
    @track filterEligibility = '';
    @track documents = [];
    @track isLoadingDocuments = false;
    
    columns = COLUMNS;
    wiredApplicationsResult;
    wiredStatsResult;
    
    statusOptions = [
        { label: 'All Statuses', value: '' },
        { label: 'Submitted', value: 'Submitted' },
        { label: 'Under Review', value: 'Under Review' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];
    
    eligibilityOptions = [
        { label: 'All', value: '' },
        { label: 'Eligible Only', value: 'true' },
        { label: 'Not Eligible', value: 'false' }
    ];

    @wire(getApplicationsForReview, { statusFilter: '$filterStatus', eligibilityFilter: '$filterEligibility' })
    wiredApplications(result) {
        this.wiredApplicationsResult = result;
        if (result.data) {
            this.applications = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load applications', 'error');
        }
    }
    
    @wire(getApplicationStats)
    wiredStats(result) {
        this.wiredStatsResult = result;
        if (result.data) {
            this.stats = result.data;
        }
    }
    
    get hasApplications() {
        return this.applications && this.applications.length > 0;
    }
    
    get eligibilityResultsParsed() {
        if (!this.selectedApplication?.Eligibility_Results__c) return [];
        try {
            const result = JSON.parse(this.selectedApplication.Eligibility_Results__c);
            return result.rules || [];
        } catch (e) {
            return [];
        }
    }
    
    get awardFactors() {
        return this.awardPreview?.factors || [];
    }
    
    get canApprove() {
        return this.selectedApplication && 
               (this.selectedApplication.Status__c === 'Submitted' || 
                this.selectedApplication.Status__c === 'Under Review');
    }
    
    get canReject() {
        return this.canApprove;
    }

    handleFilterChange(event) {
        const field = event.target.name;
        if (field === 'status') {
            this.filterStatus = event.detail.value;
        } else if (field === 'eligibility') {
            this.filterEligibility = event.detail.value;
        }
    }
    
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'review') {
            this.openReviewModal(row);
        }
    }
    
    async openReviewModal(application) {
        this.isLoading = true;
        this.selectedApplication = application;
        this.showReviewModal = true;
        this.awardPreview = null;
        this.documents = [];
        this.isLoadingDocuments = true;

        try {
            if (application.Status__c === 'Submitted') {
                await setUnderReview({ applicationId: application.Id });
                await refreshApex(this.wiredApplicationsResult);
            }
            
            this.loadDocuments(application.Id);
            
            const result = await calculateAward({ applicationId: application.Id });
            if (result.success) {
                this.awardPreview = result;
            }
        } catch (error) {
            this.showToast('Error', 'Failed to calculate award preview', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    closeReviewModal() {
        this.showReviewModal = false;
        this.selectedApplication = null;
        this.awardPreview = null;
    }
    
    handleApproveClick() {
        this.approveComments = '';
        this.showApproveModal = true;
    }
    
    handleRejectClick() {
        this.rejectComments = '';
        this.showRejectModal = true;
    }
    
    closeApproveModal() {
        this.showApproveModal = false;
    }
    
    closeRejectModal() {
        this.showRejectModal = false;
    }
    
    handleApproveCommentsChange(event) {
        this.approveComments = event.target.value;
    }
    
    handleRejectCommentsChange(event) {
        this.rejectComments = event.target.value;
    }
    
    async confirmApprove() {
        this.isLoading = true;
        try {
            const result = await approveApplication({ 
                applicationId: this.selectedApplication.Id,
                reviewerComments: this.approveComments
            });
            
            if (result.success) {
                this.showToast('Success', `Application approved with award: $${result.finalAwardAmount.toLocaleString()}`, 'success');
                this.showApproveModal = false;
                this.showReviewModal = false;
                await refreshApex(this.wiredApplicationsResult);
                await refreshApex(this.wiredStatsResult);
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to approve application', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    async confirmReject() {
        if (!this.rejectComments.trim()) {
            this.showToast('Error', 'Please provide rejection comments', 'error');
            return;
        }
        
        this.isLoading = true;
        try {
            await rejectApplication({ 
                applicationId: this.selectedApplication.Id,
                reviewerComments: this.rejectComments
            });
            
            this.showToast('Success', 'Application rejected', 'success');
            this.showRejectModal = false;
            this.showReviewModal = false;
            await refreshApex(this.wiredApplicationsResult);
            await refreshApex(this.wiredStatsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to reject application', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredApplicationsResult);
            await refreshApex(this.wiredStatsResult);
            this.showToast('Success', 'Data refreshed', 'success');
        } finally {
            this.isLoading = false;
        }
    }
    
    async loadDocuments(applicationId) {
        try {
            const docs = await getApplicationDocuments({ applicationId });
            this.documents = docs.map(doc => ({
                ...doc,
                downloadUrl: `/sfc/servlet.shepherd/version/download/${doc.versionId}`
            }));
        } catch (error) {
            console.error('Error loading documents:', error);
        } finally {
            this.isLoadingDocuments = false;
        }
    }
    
    get hasDocuments() {
        return this.documents && this.documents.length > 0;
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
