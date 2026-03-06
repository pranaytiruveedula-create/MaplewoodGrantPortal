@isTest
private class AssignPermissionSetHandlerTest {
    
    @isTest
    static void testAssignPermissionSetsToNewCommunityUser() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        
        Account testAccount = new Account(Name = 'Test Account for Community User');
        insert testAccount;
        
        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser_assign@example.com'
        );
        insert testContact;
        
        User testUser = new User(
            ContactId = testContact.Id,
            ProfileId = communityProfile.Id,
            Username = 'testuser_assign@example.com.' + System.currentTimeMillis(),
            Email = 'testuser_assign@example.com',
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            CommunityNickname = 'testuser_' + System.currentTimeMillis(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser;
        
        Test.startTest();
        AssignPermissionSetHandler.assignPermissionSets(new Set<Id>{ testUser.Id });
        Test.stopTest();
        
        List<PermissionSetAssignment> assignments = [
            SELECT Id, PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id
            AND PermissionSet.Name = 'Grant_Applicant'
        ];
        
        System.assertEquals(1, assignments.size(), 'Permission set should be assigned');
    }
    
    @isTest
    static void testSkipsNonCommunityUsers() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User standardUser = new User(
            ProfileId = standardProfile.Id,
            Username = 'standarduser_test@example.com.' + System.currentTimeMillis(),
            Email = 'standarduser_test@example.com',
            FirstName = 'Standard',
            LastName = 'User',
            Alias = 'suser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert standardUser;
        
        Test.startTest();
        AssignPermissionSetHandler.assignPermissionSets(new Set<Id>{ standardUser.Id });
        Test.stopTest();
        
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :standardUser.Id
            AND PermissionSet.Name = 'Grant_Applicant'
        ];
        
        System.assertEquals(0, assignments.size(), 'Permission set should not be assigned to non-community users');
    }
    
    @isTest
    static void testSkipsAlreadyAssignedUsers() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        PermissionSet grantApplicantPS = [SELECT Id FROM PermissionSet WHERE Name = 'Grant_Applicant' LIMIT 1];
        
        Account testAccount = new Account(Name = 'Test Account Already Assigned');
        insert testAccount;
        
        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Already',
            LastName = 'Assigned',
            Email = 'already_assigned@example.com'
        );
        insert testContact;
        
        User testUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            testUser = new User(
                ContactId = testContact.Id,
                ProfileId = communityProfile.Id,
                Username = 'already_assigned@example.com.' + System.currentTimeMillis(),
                Email = 'already_assigned@example.com',
                FirstName = 'Already',
                LastName = 'Assigned',
                Alias = 'aaloc',
                CommunityNickname = 'already_' + System.currentTimeMillis(),
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                IsActive = true
            );
            insert testUser;
            
            insert new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = grantApplicantPS.Id
            );
        }
        
        Integer initialCount = [
            SELECT COUNT() 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :testUser.Id 
            AND PermissionSet.Name = 'Grant_Applicant'
        ];
        
        Test.startTest();
        AssignPermissionSetHandler.assignPermissionSets(new Set<Id>{ testUser.Id });
        Test.stopTest();
        
        Integer finalCount = [
            SELECT COUNT() 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :testUser.Id 
            AND PermissionSet.Name = 'Grant_Applicant'
        ];
        
        System.assertEquals(initialCount, finalCount, 'No duplicate assignment should occur');
    }
    
    @isTest
    static void testHandlesEmptyUserSet() {
        Test.startTest();
        AssignPermissionSetHandler.assignPermissionSets(new Set<Id>());
        Test.stopTest();
        System.assert(true, 'Should handle empty set without error');
    }
}
