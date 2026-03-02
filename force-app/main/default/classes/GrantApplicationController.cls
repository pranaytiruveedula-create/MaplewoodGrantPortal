public with sharing class GrantApplicationController {
    
    public class ApplicationWrapper {
        @AuraEnabled public String organizationName;
        @AuraEnabled public String organizationType;
        @AuraEnabled public String ein;
        @AuraEnabled public Integer yearFounded;
        @AuraEnabled public Decimal annualBudget;
        @AuraEnabled public String missionStatement;
        @AuraEnabled public String organizationAddress;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactTitle;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String projectTitle;
        @AuraEnabled public String projectCategory;
        @AuraEnabled public String projectDescription;
        @AuraEnabled public String targetPopulation;
        @AuraEnabled public Date projectStartDate;
        @AuraEnabled public Date projectEndDate;
        @AuraEnabled public Decimal amountRequested;
        @AuraEnabled public Decimal totalProjectCost;
        @AuraEnabled public Integer numBeneficiaries;
        @AuraEnabled public String eligibilityJSON;
        @AuraEnabled public List<FileWrapper> files;
    }
    
    public class FileWrapper {
        @AuraEnabled public String fileName;
        @AuraEnabled public String base64Data;
        @AuraEnabled public String contentType;
    }
    
    public class SaveResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String applicationId;
        @AuraEnabled public String applicationNumber;
        @AuraEnabled public String errorMessage;
    }
    
    @AuraEnabled
    public static SaveResult saveApplication(String applicationJSON) {
        SaveResult result = new SaveResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            ApplicationWrapper wrapper = (ApplicationWrapper) JSON.deserialize(
                applicationJSON, 
                ApplicationWrapper.class
            );
            
            Grant_Application__c application = new Grant_Application__c();
            
            application.Organization_Name__c = wrapper.organizationName;
            application.Organization_Type__c = wrapper.organizationType;
            application.EIN__c = wrapper.ein;
            application.Year_Founded__c = wrapper.yearFounded;
            application.Annual_Budget__c = wrapper.annualBudget;
            application.Mission_Statement__c = wrapper.missionStatement;
            application.Organization_Address__c = wrapper.organizationAddress;
            application.Contact_Name__c = wrapper.contactName;
            application.Contact_Title__c = wrapper.contactTitle;
            application.Contact_Email__c = wrapper.contactEmail;
            application.Contact_Phone__c = wrapper.contactPhone;
            application.Project_Title__c = wrapper.projectTitle;
            application.Project_Category__c = wrapper.projectCategory;
            application.Project_Description__c = wrapper.projectDescription;
            application.Target_Population__c = wrapper.targetPopulation;
            application.Project_Start_Date__c = wrapper.projectStartDate;
            application.Project_End_Date__c = wrapper.projectEndDate;
            application.Amount_Requested__c = wrapper.amountRequested;
            application.Total_Project_Cost__c = wrapper.totalProjectCost;
            application.Num_Beneficiaries__c = wrapper.numBeneficiaries;
            application.Eligibility_Results__c = wrapper.eligibilityJSON;
            application.Status__c = 'Submitted';
            application.Submission_Date__c = Date.today();
            
            insert application;
            
            Grant_Application__c inserted = [
                SELECT Id, Name 
                FROM Grant_Application__c 
                WHERE Id = :application.Id
            ];
            
            if (wrapper.files != null && !wrapper.files.isEmpty()) {
                uploadFiles(inserted.Id, wrapper.files);
            }
            
            createStatusHistory(inserted.Id, null, 'Submitted', 'Application submitted');
            
            result.success = true;
            result.applicationId = inserted.Id;
            result.applicationNumber = inserted.Name;
            
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static void uploadFiles(Id applicationId, List<FileWrapper> files) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        for (FileWrapper file : files) {
            ContentVersion cv = new ContentVersion();
            cv.Title = file.fileName;
            cv.PathOnClient = file.fileName;
            cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
            cv.IsMajorVersion = true;
            contentVersions.add(cv);
        }
        
        insert contentVersions;
        
        List<Id> contentVersionIds = new List<Id>();
        for (ContentVersion cv : contentVersions) {
            contentVersionIds.add(cv.Id);
        }
        
        List<ContentVersion> insertedCVs = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersionIds
        ];
        
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion cv : insertedCVs) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = applicationId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            links.add(cdl);
        }
        
        insert links;
    }
    
    private static void createStatusHistory(Id applicationId, String oldStatus, String newStatus, String comments) {
        Status_History__c history = new Status_History__c();
        history.Application__c = applicationId;
        history.Old_Status__c = oldStatus;
        history.New_Status__c = newStatus;
        history.Changed_At__c = DateTime.now();
        history.Comments__c = comments;
        insert history;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Grant_Application__c> getMyApplications() {
        return [
            SELECT Id, Name, Organization_Name__c, Project_Title__c, 
                   Status__c, Amount_Requested__c, 
                   Submission_Date__c, CreatedDate
            FROM Grant_Application__c
            WHERE CreatedById = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static Grant_Application__c getApplicationDetails(String applicationId) {
        return [
            SELECT Id, Name, Organization_Name__c, Organization_Type__c, EIN__c,
                   Year_Founded__c, Annual_Budget__c, Mission_Statement__c,
                   Organization_Address__c, Contact_Name__c, Contact_Title__c,
                   Contact_Email__c, Contact_Phone__c, Project_Title__c,
                   Project_Category__c, Project_Description__c, Target_Population__c,
                   Project_Start_Date__c, Project_End_Date__c, Amount_Requested__c,
                   Total_Project_Cost__c, Num_Beneficiaries__c, Status__c,
                   Submission_Date__c, Eligibility_Results__c, Award_Amount__c,
                   Reviewer_Comments__c, Review_Score__c
            FROM Grant_Application__c
            WHERE Id = :applicationId
        ];
    }
}
