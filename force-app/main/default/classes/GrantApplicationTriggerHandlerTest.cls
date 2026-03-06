@isTest
private class GrantApplicationTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        Grant_Application__c app = new Grant_Application__c();
        app.Organization_Name__c = 'Test Nonprofit';
        app.Organization_Type__c = '501(c)(3)';
        app.EIN__c = '12-3456789';
        app.Year_Founded__c = 2010;
        app.Annual_Budget__c = 500000;
        app.Mission_Statement__c = 'Test mission';
        app.Contact_Name__c = 'John Doe';
        app.Contact_Email__c = 'john@test.org';
        app.Contact_Phone__c = '555-123-4567';
        app.Project_Title__c = 'Test Project';
        app.Project_Category__c = 'Youth Programs';
        app.Project_Description__c = 'Test description';
        app.Amount_Requested__c = 25000;
        app.Total_Project_Cost__c = 60000;
        app.Num_Beneficiaries__c = 200;
        app.Status__c = 'Submitted';
        insert app;
    }
    
    @isTest
    static void testStatusChangeCreatesHistory() {
        Grant_Application__c app = [SELECT Id, Status__c FROM Grant_Application__c LIMIT 1];
        
        Test.startTest();
        app.Status__c = 'Under Review';
        update app;
        Test.stopTest();
        
        List<Status_History__c> histories = [
            SELECT Id, Old_Status__c, New_Status__c, Comments__c 
            FROM Status_History__c 
            WHERE Application__c = :app.Id
        ];
        
        System.assertEquals(1, histories.size(), 'Should create one history record');
        System.assertEquals('Submitted', histories[0].Old_Status__c, 'Old status should be Submitted');
        System.assertEquals('Under Review', histories[0].New_Status__c, 'New status should be Under Review');
    }
    
    @isTest
    static void testNoHistoryWhenStatusUnchanged() {
        Grant_Application__c app = [SELECT Id, Status__c, Project_Title__c FROM Grant_Application__c LIMIT 1];
        
        Integer existingHistoryCount = [SELECT COUNT() FROM Status_History__c WHERE Application__c = :app.Id];
        
        Test.startTest();
        app.Project_Title__c = 'Updated Title';
        update app;
        Test.stopTest();
        
        Integer newHistoryCount = [SELECT COUNT() FROM Status_History__c WHERE Application__c = :app.Id];
        System.assertEquals(existingHistoryCount, newHistoryCount, 'No new history should be created when status unchanged');
    }
    
    @isTest
    static void testMultipleStatusChanges() {
        Grant_Application__c app = [SELECT Id, Status__c FROM Grant_Application__c LIMIT 1];
        
        Test.startTest();
        app.Status__c = 'Under Review';
        update app;
        
        app.Status__c = 'Approved';
        update app;
        Test.stopTest();
        
        List<Status_History__c> histories = [
            SELECT Id, Old_Status__c, New_Status__c 
            FROM Status_History__c 
            WHERE Application__c = :app.Id
            ORDER BY Changed_At__c ASC
        ];
        
        System.assertEquals(2, histories.size(), 'Should create two history records');
        System.assertEquals('Submitted', histories[0].Old_Status__c);
        System.assertEquals('Under Review', histories[0].New_Status__c);
        System.assertEquals('Under Review', histories[1].Old_Status__c);
        System.assertEquals('Approved', histories[1].New_Status__c);
    }
    
    @isTest
    static void testBulkStatusChange() {
        List<Grant_Application__c> apps = new List<Grant_Application__c>();
        for (Integer i = 0; i < 50; i++) {
            Grant_Application__c app = new Grant_Application__c();
            app.Organization_Name__c = 'Bulk Test Org ' + i;
            app.Organization_Type__c = '501(c)(3)';
            app.EIN__c = '12-345678' + Math.mod(i, 10);
            app.Year_Founded__c = 2010;
            app.Annual_Budget__c = 500000;
            app.Contact_Name__c = 'Test Contact';
            app.Contact_Email__c = 'test' + i + '@test.org';
            app.Project_Title__c = 'Bulk Project ' + i;
            app.Project_Category__c = 'Youth Programs';
            app.Amount_Requested__c = 10000;
            app.Total_Project_Cost__c = 30000;
            app.Num_Beneficiaries__c = 100;
            app.Status__c = 'Submitted';
            apps.add(app);
        }
        insert apps;
        
        Test.startTest();
        for (Grant_Application__c app : apps) {
            app.Status__c = 'Under Review';
        }
        update apps;
        Test.stopTest();
        
        Set<Id> appIds = new Set<Id>();
        for (Grant_Application__c app : apps) {
            appIds.add(app.Id);
        }
        
        Integer historyCount = [SELECT COUNT() FROM Status_History__c WHERE Application__c IN :appIds];
        System.assertEquals(50, historyCount, 'Should create 50 history records for bulk update');
    }
}
