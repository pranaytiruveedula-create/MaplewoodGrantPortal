public with sharing class GrantReviewerController {
    
    @AuraEnabled(cacheable=true)
    public static List<Grant_Application__c> getApplicationsForReview(String statusFilter, String eligibilityFilter) {
        String query = 'SELECT Id, Name, Organization_Name__c, Organization_Type__c, Year_Founded__c, ' +
                       'Annual_Budget__c, Project_Title__c, Project_Category__c, Project_Description__c, ' +
                       'Amount_Requested__c, Total_Project_Cost__c, Num_Beneficiaries__c, ' +
                       'Status__c, Is_Eligible__c, Eligibility_Score__c, Eligibility_Results__c, ' +
                       'Award_Amount__c, Award_Breakdown__c, Reviewer_Comments__c, ' +
                       'Contact_Name__c, Contact_Email__c, CreatedDate ' +
                       'FROM Grant_Application__c ';
        
        List<String> conditions = new List<String>();
        
        if (String.isNotBlank(statusFilter)) {
            conditions.add('Status__c = :statusFilter');
        }
        
        if (String.isNotBlank(eligibilityFilter)) {
            Boolean isEligible = Boolean.valueOf(eligibilityFilter);
            conditions.add('Is_Eligible__c = :isEligible');
        }
        
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        query += ' ORDER BY CreatedDate DESC LIMIT 200';
        
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getApplicationStats() {
        Map<String, Object> stats = new Map<String, Object>();
        
        List<AggregateResult> statusCounts = [
            SELECT Status__c, COUNT(Id) cnt
            FROM Grant_Application__c
            GROUP BY Status__c
        ];
        
        Integer submitted = 0;
        Integer underReview = 0;
        Integer approved = 0;
        Integer rejected = 0;
        
        for (AggregateResult ar : statusCounts) {
            String status = (String)ar.get('Status__c');
            Integer count = (Integer)ar.get('cnt');
            
            if (status == 'Submitted') submitted = count;
            else if (status == 'Under Review') underReview = count;
            else if (status == 'Approved') approved = count;
            else if (status == 'Rejected') rejected = count;
        }
        
        AggregateResult totalAward = [
            SELECT SUM(Award_Amount__c) total
            FROM Grant_Application__c
            WHERE Status__c = 'Approved'
        ];
        
        Decimal totalAwarded = (Decimal)totalAward.get('total');
        if (totalAwarded == null) totalAwarded = 0;
        
        stats.put('submitted', submitted);
        stats.put('underReview', underReview);
        stats.put('approved', approved);
        stats.put('rejected', rejected);
        stats.put('totalAwarded', totalAwarded.format());
        
        return stats;
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getApplicationDocuments(String applicationId) {
        List<Map<String, Object>> documents = new List<Map<String, Object>>();
        
        try {
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType,
                       ContentDocument.ContentSize, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :applicationId
                LIMIT 100
            ];
            
            for (ContentDocumentLink link : links) {
                Map<String, Object> doc = new Map<String, Object>();
                doc.put('id', link.ContentDocumentId);
                doc.put('title', link.ContentDocument.Title);
                doc.put('fileType', link.ContentDocument.FileType);
                doc.put('size', formatFileSize(link.ContentDocument.ContentSize));
                doc.put('versionId', link.ContentDocument.LatestPublishedVersionId);
                documents.add(doc);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Unable to retrieve documents: ' + e.getMessage());
        }
        
        return documents;
    }
    
    private static String formatFileSize(Integer bytes) {
        if (bytes == null) return '0 B';
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024) + ' KB';
        return (bytes / (1024 * 1024)) + ' MB';
    }
}
