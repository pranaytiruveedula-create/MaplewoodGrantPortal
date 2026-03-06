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
        @AuraEnabled public String projectStartDate;
        @AuraEnabled public String projectEndDate;
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
            application.Project_Start_Date__c = parseDate(wrapper.projectStartDate);
            application.Project_End_Date__c = parseDate(wrapper.projectEndDate);
            application.Amount_Requested__c = wrapper.amountRequested;
            application.Total_Project_Cost__c = wrapper.totalProjectCost;
            application.Num_Beneficiaries__c = wrapper.numBeneficiaries;
            application.Eligibility_Results__c = wrapper.eligibilityJSON;
            application.Status__c = 'Submitted';
            application.Submission_Date__c = Date.today();
            
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Grant_Application__c>{application});
            insert decision.getRecords();
            Id insertedId = decision.getRecords()[0].Id;
            
            Grant_Application__c inserted = [
                SELECT Id, Name 
                FROM Grant_Application__c 
                WHERE Id = :insertedId
                WITH USER_MODE
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
            links.add(cdl);
        }
        
        insert links;
    }
    
    private static Date parseDate(String dateStr) {
        if (String.isBlank(dateStr)) return null;
        try {
            return Date.valueOf(dateStr);
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void createStatusHistory(Id applicationId, String oldStatus, String newStatus, String comments) {
        Status_History__c history = new Status_History__c();
        history.Application__c = applicationId;
        history.Old_Status__c = oldStatus;
        history.New_Status__c = newStatus;
        history.Changed_At__c = DateTime.now();
        history.Comments__c = comments;
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Status_History__c>{history});
        insert decision.getRecords();
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Grant_Application__c> getMyApplications() {
        String query = buildAccessibleFieldsQuery(
            new List<String>{
                'Id', 'Name', 'Organization_Name__c', 'Organization_Type__c',
                'Year_Founded__c', 'Annual_Budget__c', 'Project_Title__c',
                'Project_Category__c', 'Project_Description__c',
                'Status__c', 'Amount_Requested__c', 'Total_Project_Cost__c',
                'Num_Beneficiaries__c', 'Award_Amount__c',
                'Eligibility_Results__c', 'Reviewer_Comments__c',
                'Submission_Date__c', 'CreatedDate'
            },
            'Grant_Application__c',
            'CreatedById = :userId',
            'CreatedDate DESC',
            50
        );
        
        Id userId = UserInfo.getUserId();
        List<Grant_Application__c> apps = Database.query(query);
        return apps;
    }
    
    @AuraEnabled(cacheable=true)
    public static Grant_Application__c getApplicationDetails(String applicationId) {
        try {
            String query = buildAccessibleFieldsQuery(
                new List<String>{
                    'Id', 'Name', 'Organization_Name__c', 'Organization_Type__c', 'EIN__c',
                    'Year_Founded__c', 'Annual_Budget__c', 'Mission_Statement__c',
                    'Organization_Address__c', 'Contact_Name__c', 'Contact_Title__c',
                    'Contact_Email__c', 'Contact_Phone__c', 'Project_Title__c',
                    'Project_Category__c', 'Project_Description__c', 'Target_Population__c',
                    'Project_Start_Date__c', 'Project_End_Date__c', 'Amount_Requested__c',
                    'Total_Project_Cost__c', 'Num_Beneficiaries__c', 'Status__c',
                    'Submission_Date__c', 'Eligibility_Results__c', 'Award_Amount__c',
                    'Reviewer_Comments__c'
                },
                'Grant_Application__c',
                'Id = :applicationId',
                null,
                1
            );
            
            List<Grant_Application__c> apps = Database.query(query);
            if (apps.isEmpty()) {
                throw new AuraHandledException('Application not found or you do not have access.');
            }
            return apps[0];
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Application not found or you do not have access.');
        }
    }
    
    private static String buildAccessibleFieldsQuery(
        List<String> requestedFields,
        String objectName,
        String whereClause,
        String orderBy,
        Integer limitRows
    ) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        
        List<String> accessibleFields = new List<String>();
        for (String fieldName : requestedFields) {
            String fieldKey = fieldName.toLowerCase();
            if (fieldKey == 'id' || fieldKey == 'name' || fieldKey == 'createddate') {
                accessibleFields.add(fieldName);
            } else if (fieldMap.containsKey(fieldKey)) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldKey).getDescribe();
                if (fieldDescribe.isAccessible()) {
                    accessibleFields.add(fieldName);
                }
            }
        }
        
        String query = 'SELECT ' + String.join(accessibleFields, ', ') + ' FROM ' + objectName;
        
        if (String.isNotBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        
        if (String.isNotBlank(orderBy)) {
            query += ' ORDER BY ' + orderBy;
        }
        
        if (limitRows != null && limitRows > 0) {
            query += ' LIMIT ' + limitRows;
        }
        
        return query;
    }
}
