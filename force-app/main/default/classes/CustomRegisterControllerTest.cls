@isTest
private class CustomRegisterControllerTest {
    
    @isTest
    static void testValidEmailFormat() {
        Test.startTest();
        CustomRegisterController.RegistrationResult result = CustomRegisterController.registerUser(
            'Test', 'User', 'invalid-email', 'password123'
        );
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for invalid email');
        System.assert(result.message.contains('valid email'), 'Should mention email validation');
    }
    
    @isTest
    static void testMissingLastName() {
        Test.startTest();
        CustomRegisterController.RegistrationResult result = CustomRegisterController.registerUser(
            'Test', '', 'test@example.com', 'password123'
        );
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for missing last name');
        System.assert(result.message.contains('Last name'), 'Should mention last name required');
    }
    
    @isTest
    static void testMissingEmail() {
        Test.startTest();
        CustomRegisterController.RegistrationResult result = CustomRegisterController.registerUser(
            'Test', 'User', '', 'password123'
        );
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for missing email');
        System.assert(result.message.contains('Email'), 'Should mention email required');
    }
    
    @isTest
    static void testShortPassword() {
        Test.startTest();
        CustomRegisterController.RegistrationResult result = CustomRegisterController.registerUser(
            'Test', 'User', 'test@example.com', 'short'
        );
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for short password');
        System.assert(result.message.contains('8 characters'), 'Should mention password length');
    }
    
    @isTest
    static void testExistingUserEmail() {
        User existingUser = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        CustomRegisterController.RegistrationResult result = CustomRegisterController.registerUser(
            'Test', 'User', existingUser.Email, 'password123'
        );
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for existing email');
        System.assert(result.message.contains('already exists'), 'Should mention account exists');
    }
    
    @isTest
    static void testRegistrationResultClass() {
        CustomRegisterController.RegistrationResult result = new CustomRegisterController.RegistrationResult();
        result.success = true;
        result.message = 'Test message';
        result.userId = '005000000000001';
        
        System.assertEquals(true, result.success);
        System.assertEquals('Test message', result.message);
        System.assertEquals('005000000000001', result.userId);
    }
}
