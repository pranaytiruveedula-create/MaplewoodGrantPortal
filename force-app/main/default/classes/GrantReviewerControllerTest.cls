@isTest
private class GrantReviewerControllerTest {
    
    @TestSetup
    static void setupTestData() {
        List<Grant_Application__c> apps = new List<Grant_Application__c>();
        
        Grant_Application__c app1 = new Grant_Application__c();
        app1.Organization_Name__c = 'Org One';
        app1.EIN__c = '11-1111111';
        app1.Organization_Type__c = '501(c)(3)';
        app1.Year_Founded__c = 2015;
        app1.Annual_Budget__c = 300000;
        app1.Contact_Name__c = 'Contact One';
        app1.Contact_Email__c = 'one@example.com';
        app1.Project_Title__c = 'Project One';
        app1.Project_Category__c = 'Youth Programs';
        app1.Project_Description__c = 'Description';
        app1.Amount_Requested__c = 25000;
        app1.Total_Project_Cost__c = 80000;
        app1.Num_Beneficiaries__c = 200;
        app1.Project_Start_Date__c = Date.today().addMonths(2);
        app1.Project_End_Date__c = Date.today().addMonths(14);
        app1.Status__c = 'Submitted';
        app1.Is_Eligible__c = true;
        apps.add(app1);
        
        Grant_Application__c app2 = new Grant_Application__c();
        app2.Organization_Name__c = 'Org Two';
        app2.EIN__c = '22-2222222';
        app2.Organization_Type__c = '501(c)(3)';
        app2.Year_Founded__c = 2010;
        app2.Annual_Budget__c = 500000;
        app2.Contact_Name__c = 'Contact Two';
        app2.Contact_Email__c = 'two@example.com';
        app2.Project_Title__c = 'Project Two';
        app2.Project_Category__c = 'Public Health';
        app2.Project_Description__c = 'Description';
        app2.Amount_Requested__c = 40000;
        app2.Total_Project_Cost__c = 100000;
        app2.Num_Beneficiaries__c = 500;
        app2.Project_Start_Date__c = Date.today().addMonths(2);
        app2.Project_End_Date__c = Date.today().addMonths(14);
        app2.Status__c = 'Under Review';
        app2.Is_Eligible__c = true;
        apps.add(app2);
        
        Grant_Application__c app3 = new Grant_Application__c();
        app3.Organization_Name__c = 'Org Three';
        app3.EIN__c = '33-3333333';
        app3.Organization_Type__c = '501(c)(3)';
        app3.Year_Founded__c = 2020;
        app3.Annual_Budget__c = 100000;
        app3.Contact_Name__c = 'Contact Three';
        app3.Contact_Email__c = 'three@example.com';
        app3.Project_Title__c = 'Project Three';
        app3.Project_Category__c = 'Senior Services';
        app3.Project_Description__c = 'Description';
        app3.Amount_Requested__c = 15000;
        app3.Total_Project_Cost__c = 50000;
        app3.Num_Beneficiaries__c = 100;
        app3.Project_Start_Date__c = Date.today().addMonths(2);
        app3.Project_End_Date__c = Date.today().addMonths(14);
        app3.Status__c = 'Approved';
        app3.Is_Eligible__c = false;
        app3.Award_Amount__c = 10000;
        apps.add(app3);
        
        insert apps;
    }
    
    @isTest
    static void testGetApplicationsNoFilter() {
        Test.startTest();
        List<Grant_Application__c> apps = GrantReviewerController.getApplicationsForReview('', '');
        Test.stopTest();
        
        System.assertEquals(3, apps.size(), 'Should return all 3 applications');
    }
    
    @isTest
    static void testGetApplicationsWithStatusFilter() {
        Test.startTest();
        List<Grant_Application__c> apps = GrantReviewerController.getApplicationsForReview('Submitted', '');
        Test.stopTest();
        
        System.assertEquals(1, apps.size(), 'Should return 1 submitted application');
        System.assertEquals('Submitted', apps[0].Status__c, 'Status should be Submitted');
    }
    
    @isTest
    static void testGetApplicationsWithEligibilityFilter() {
        Test.startTest();
        List<Grant_Application__c> apps = GrantReviewerController.getApplicationsForReview('', 'true');
        Test.stopTest();
        
        System.assertEquals(2, apps.size(), 'Should return 2 eligible applications');
    }
    
    @isTest
    static void testGetApplicationsWithBothFilters() {
        Test.startTest();
        List<Grant_Application__c> apps = GrantReviewerController.getApplicationsForReview('Under Review', 'true');
        Test.stopTest();
        
        System.assertEquals(1, apps.size(), 'Should return 1 application');
        System.assertEquals('Org Two', apps[0].Organization_Name__c, 'Should be Org Two');
    }
    
    @isTest
    static void testGetApplicationStats() {
        Test.startTest();
        Map<String, Object> stats = GrantReviewerController.getApplicationStats();
        Test.stopTest();
        
        System.assertEquals(1, stats.get('submitted'), 'Should have 1 submitted');
        System.assertEquals(1, stats.get('underReview'), 'Should have 1 under review');
        System.assertEquals(1, stats.get('approved'), 'Should have 1 approved');
        System.assertEquals(0, stats.get('rejected'), 'Should have 0 rejected');
        System.assertNotEquals(null, stats.get('totalAwarded'), 'Total awarded should be set');
    }
}
