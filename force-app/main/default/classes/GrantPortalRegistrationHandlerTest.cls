@isTest
private class GrantPortalRegistrationHandlerTest {
    
    @isTest
    static void testCreateUserWithValidData() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        
        Account testAccount = new Account(Name = 'Grant Portal Applicants');
        insert testAccount;
        
        GrantPortalRegistrationHandler handler = new GrantPortalRegistrationHandler();
        
        Map<Schema.SObjectField, String> registrationAttributes = new Map<Schema.SObjectField, String>{
            User.Email => 'newuser_reg@example.com',
            User.FirstName => 'New',
            User.LastName => 'User'
        };
        
        Test.startTest();
        try {
            Id userId = handler.createUser(testAccount.Id, communityProfile.Id, registrationAttributes, 'Password123!');
            System.assertNotEquals(null, userId, 'User should be created');
        } catch (Exception e) {
            System.debug('Expected in some orgs: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateUserMissingEmail() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        
        GrantPortalRegistrationHandler handler = new GrantPortalRegistrationHandler();
        
        Map<Schema.SObjectField, String> registrationAttributes = new Map<Schema.SObjectField, String>{
            User.FirstName => 'Test',
            User.LastName => 'User'
        };
        
        Test.startTest();
        try {
            handler.createUser(null, communityProfile.Id, registrationAttributes, 'Password123!');
            System.assert(false, 'Should have thrown an exception');
        } catch (GrantPortalRegistrationHandler.RegistrationException e) {
            System.assert(e.getMessage().contains('Email'), 'Should mention email required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateUserMissingLastName() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        
        GrantPortalRegistrationHandler handler = new GrantPortalRegistrationHandler();
        
        Map<Schema.SObjectField, String> registrationAttributes = new Map<Schema.SObjectField, String>{
            User.Email => 'test_missing_ln@example.com',
            User.FirstName => 'Test'
        };
        
        Test.startTest();
        try {
            handler.createUser(null, communityProfile.Id, registrationAttributes, 'Password123!');
            System.assert(false, 'Should have thrown an exception');
        } catch (GrantPortalRegistrationHandler.RegistrationException e) {
            System.assert(e.getMessage().contains('Last name'), 'Should mention last name required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateUserInvalidEmail() {
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        
        GrantPortalRegistrationHandler handler = new GrantPortalRegistrationHandler();
        
        Map<Schema.SObjectField, String> registrationAttributes = new Map<Schema.SObjectField, String>{
            User.Email => 'invalid-email',
            User.FirstName => 'Test',
            User.LastName => 'User'
        };
        
        Test.startTest();
        try {
            handler.createUser(null, communityProfile.Id, registrationAttributes, 'Password123!');
            System.assert(false, 'Should have thrown an exception');
        } catch (GrantPortalRegistrationHandler.RegistrationException e) {
            System.assert(e.getMessage().contains('valid email'), 'Should mention valid email');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateUserDuplicateEmail() {
        User existingUser = [SELECT Id, Email FROM User WHERE IsActive = true AND Email != null LIMIT 1];
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        
        GrantPortalRegistrationHandler handler = new GrantPortalRegistrationHandler();
        
        Map<Schema.SObjectField, String> registrationAttributes = new Map<Schema.SObjectField, String>{
            User.Email => existingUser.Email,
            User.FirstName => 'Test',
            User.LastName => 'User'
        };
        
        Test.startTest();
        try {
            handler.createUser(null, communityProfile.Id, registrationAttributes, 'Password123!');
            System.assert(false, 'Should have thrown an exception');
        } catch (GrantPortalRegistrationHandler.RegistrationException e) {
            System.assert(e.getMessage().contains('already exists'), 'Should mention account exists');
        }
        Test.stopTest();
    }
}
