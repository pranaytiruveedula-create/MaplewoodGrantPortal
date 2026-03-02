@isTest
private class GrantApplicationControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Grant_Application__c app = new Grant_Application__c(
            Organization_Name__c = 'Test Nonprofit',
            Organization_Type__c = '501(c)(3)',
            EIN__c = '12-3456789',
            Year_Founded__c = 2020,
            Annual_Budget__c = 500000,
            Mission_Statement__c = 'Test mission statement',
            Organization_Address__c = '123 Test St, Test City, ST 12345',
            Contact_Name__c = 'John Doe',
            Contact_Title__c = 'Executive Director',
            Contact_Email__c = 'john@test.org',
            Contact_Phone__c = '555-123-4567',
            Project_Title__c = 'Test Project',
            Project_Category__c = 'Youth Programs',
            Project_Description__c = 'Test project description',
            Target_Population__c = 'Test population',
            Project_Start_Date__c = Date.today().addMonths(1),
            Project_End_Date__c = Date.today().addMonths(12),
            Amount_Requested__c = 25000,
            Total_Project_Cost__c = 60000,
            Num_Beneficiaries__c = 100,
            Status__c = 'Submitted',
            Submission_Date__c = Date.today()
        );
        insert app;
    }
    
    @isTest
    static void testSaveApplication() {
        String applicationJSON = JSON.serialize(new Map<String, Object>{
            'organizationName' => 'New Nonprofit',
            'organizationType' => '501(c)(3)',
            'ein' => '98-7654321',
            'yearFounded' => 2019,
            'annualBudget' => 400000,
            'missionStatement' => 'Our mission is to serve',
            'organizationAddress' => '456 Main St, City, ST 54321',
            'contactName' => 'Jane Smith',
            'contactTitle' => 'Director',
            'contactEmail' => 'jane@neworg.org',
            'contactPhone' => '555-987-6543',
            'projectTitle' => 'Community Initiative',
            'projectCategory' => 'Senior Services',
            'projectDescription' => 'A great project description',
            'targetPopulation' => 'Seniors in the community',
            'projectStartDate' => String.valueOf(Date.today().addMonths(2)),
            'projectEndDate' => String.valueOf(Date.today().addMonths(14)),
            'amountRequested' => 30000,
            'totalProjectCost' => 75000,
            'numBeneficiaries' => 150,
            'eligibilityJSON' => '{"isEligible": true, "totalPassed": 6}',
            'files' => null
        });
        
        Test.startTest();
        GrantApplicationController.SaveResult result = GrantApplicationController.saveApplication(applicationJSON);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Save should succeed');
        System.assertNotEquals(null, result.applicationId, 'Application ID should not be null');
        System.assert(result.applicationNumber.startsWith('APP-'), 'Application number should start with APP-');
        
        Grant_Application__c saved = [
            SELECT Organization_Name__c, Status__c 
            FROM Grant_Application__c 
            WHERE Id = :result.applicationId
        ];
        System.assertEquals('New Nonprofit', saved.Organization_Name__c);
        System.assertEquals('Submitted', saved.Status__c);
        
        List<Status_History__c> history = [
            SELECT New_Status__c 
            FROM Status_History__c 
            WHERE Application__c = :result.applicationId
        ];
        System.assertEquals(1, history.size(), 'Should have one status history record');
        System.assertEquals('Submitted', history[0].New_Status__c);
    }
    
    @isTest
    static void testSaveApplicationWithFiles() {
        String base64Content = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        
        String applicationJSON = JSON.serialize(new Map<String, Object>{
            'organizationName' => 'File Test Org',
            'organizationType' => '501(c)(3)',
            'ein' => '11-1111111',
            'yearFounded' => 2018,
            'annualBudget' => 300000,
            'missionStatement' => 'Test mission',
            'organizationAddress' => '789 File St',
            'contactName' => 'File Person',
            'contactTitle' => 'Manager',
            'contactEmail' => 'file@test.org',
            'contactPhone' => '555-111-2222',
            'projectTitle' => 'File Project',
            'projectCategory' => 'Youth Programs',
            'projectDescription' => 'Project with files',
            'targetPopulation' => 'Youth',
            'projectStartDate' => String.valueOf(Date.today().addMonths(1)),
            'projectEndDate' => String.valueOf(Date.today().addMonths(6)),
            'amountRequested' => 20000,
            'totalProjectCost' => 50000,
            'numBeneficiaries' => 75,
            'eligibilityJSON' => '{}',
            'files' => new List<Map<String, String>>{
                new Map<String, String>{
                    'fileName' => 'TestDocument.pdf',
                    'base64Data' => base64Content,
                    'contentType' => 'application/pdf'
                }
            }
        });
        
        Test.startTest();
        GrantApplicationController.SaveResult result = GrantApplicationController.saveApplication(applicationJSON);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Save with files should succeed');
        
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :result.applicationId
        ];
        System.assertEquals(1, links.size(), 'Should have one file attached');
    }
    
    @isTest
    static void testSaveApplicationError() {
        String invalidJSON = '{"organizationName": null}';
        
        Test.startTest();
        GrantApplicationController.SaveResult result = GrantApplicationController.saveApplication(invalidJSON);
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Save should fail with invalid data');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }
    
    @isTest
    static void testGetMyApplications() {
        Test.startTest();
        List<Grant_Application__c> apps = GrantApplicationController.getMyApplications();
        Test.stopTest();
        
        System.assertEquals(1, apps.size(), 'Should return one application');
        System.assertEquals('Test Nonprofit', apps[0].Organization_Name__c);
    }
    
    @isTest
    static void testGetApplicationDetails() {
        Grant_Application__c existingApp = [SELECT Id FROM Grant_Application__c LIMIT 1];
        
        Test.startTest();
        Grant_Application__c details = GrantApplicationController.getApplicationDetails(existingApp.Id);
        Test.stopTest();
        
        System.assertEquals('Test Nonprofit', details.Organization_Name__c);
        System.assertEquals('Test Project', details.Project_Title__c);
        System.assertEquals(25000, details.Amount_Requested__c);
    }
}
