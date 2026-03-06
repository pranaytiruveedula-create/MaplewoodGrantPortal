@isTest
private class CustomLoginControllerTest {
    
    @isTest
    static void testLoginWithInvalidCredentials() {
        Test.startTest();
        try {
            CustomLoginController.login('invalid@example.com', 'wrongpassword', '/grants');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            // AuraHandledException.getMessage() returns 'Script-thrown exception' for security
            System.assert(e.getMessage() != null, 'Should throw AuraHandledException for invalid credentials');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testLoginWithNullUsername() {
        Test.startTest();
        try {
            CustomLoginController.login(null, 'password', '/grants');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Should throw exception for null username');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testLoginWithEmptyPassword() {
        Test.startTest();
        try {
            CustomLoginController.login('test@example.com', '', '/grants');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Should throw exception for empty password');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testLoginWithNullStartUrl() {
        Test.startTest();
        try {
            CustomLoginController.login('test@example.com', 'password123', null);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Should handle null startUrl');
        }
        Test.stopTest();
    }
}
