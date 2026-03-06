public with sharing class GrantApplicationTriggerHandler {
    
    public static void handleStatusChange(List<Grant_Application__c> newRecords, Map<Id, Grant_Application__c> oldMap) {
        List<Status_History__c> historyRecords = new List<Status_History__c>();
        
        for (Grant_Application__c app : newRecords) {
            Grant_Application__c oldApp = oldMap.get(app.Id);
            
            if (app.Status__c != oldApp.Status__c) {
                Status_History__c history = new Status_History__c();
                history.Application__c = app.Id;
                history.Old_Status__c = oldApp.Status__c;
                history.New_Status__c = app.Status__c;
                history.Changed_At__c = DateTime.now();
                history.Changed_By__c = UserInfo.getUserId();
                history.Comments__c = 'Status changed from ' + oldApp.Status__c + ' to ' + app.Status__c;
                historyRecords.add(history);
            }
        }
        
        if (!historyRecords.isEmpty()) {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, historyRecords);
            insert decision.getRecords();
        }
    }
}
