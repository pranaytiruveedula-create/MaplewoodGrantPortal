global without sharing class CustomRegisterController {
    
    private static final String DEFAULT_ACCOUNT_NAME = 'Grant Portal Applicants';
    
    @AuraEnabled
    global static RegistrationResult registerUser(String firstName, String lastName, String email, String password) {
        RegistrationResult result = new RegistrationResult();
        
        try {
            validateInput(lastName, email, password);
            checkForExistingUser(email);
            
            Account portalAccount = getOrCreatePortalAccount();
            String userId = createCommunityUser(portalAccount.Id, firstName, lastName, email, password);
            
            if (String.isNotBlank(userId)) {
                result.success = true;
                result.message = 'Registration successful! Please check your email for verification.';
                result.userId = userId;
            } else {
                result.success = false;
                result.message = 'Registration failed. Please try again or contact support.';
            }
            
        } catch (RegistrationException e) {
            result.success = false;
            result.message = e.getMessage();
        } catch (Exception e) {
            result.success = false;
            result.message = e.getMessage();
        }
        
        return result;
    }
    
    private static void validateInput(String lastName, String email, String password) {
        if (String.isBlank(lastName)) {
            throw new RegistrationException('Last name is required.');
        }
        if (String.isBlank(email)) {
            throw new RegistrationException('Email address is required.');
        }
        if (!isValidEmail(email)) {
            throw new RegistrationException('Please enter a valid email address.');
        }
        if (String.isBlank(password) || password.length() < 8) {
            throw new RegistrationException('Password must be at least 8 characters long.');
        }
    }
    
    private static Boolean isValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        Matcher emailMatcher = emailPattern.matcher(email);
        return emailMatcher.matches();
    }
    
    private static void checkForExistingUser(String email) {
        List<User> existingUsers = [
            SELECT Id, Username, Email 
            FROM User 
            WHERE Email = :email
            LIMIT 1
        ];
        
        if (!existingUsers.isEmpty()) {
            throw new RegistrationException('An account with this email address already exists. Please use the login page or reset your password.');
        }
    }
    
    private static Account getOrCreatePortalAccount() {
        List<Account> existingAccounts = [
            SELECT Id, Name 
            FROM Account 
            WHERE Name = :DEFAULT_ACCOUNT_NAME
            LIMIT 1
        ];
        
        if (!existingAccounts.isEmpty()) {
            return existingAccounts[0];
        }
        
        Account newAccount = new Account(
            Name = DEFAULT_ACCOUNT_NAME,
            Description = 'Account for Grant Portal self-registered users'
        );
        insert newAccount;
        return newAccount;
    }
    
    private static String createCommunityUser(Id accountId, String firstName, String lastName, String email, String password) {
        Contact newContact = new Contact(
            AccountId = accountId,
            FirstName = String.isNotBlank(firstName) ? firstName : '',
            LastName = lastName,
            Email = email
        );
        insert newContact;
        
        String nickname = generateNickname(firstName, lastName);
        
        User newUser = new User(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            Username = email,
            Alias = generateAlias(firstName, lastName),
            CommunityNickname = nickname,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        String userId = Site.createExternalUser(newUser, accountId, password);
        return userId;
    }
    
    private static String generateAlias(String firstName, String lastName) {
        String alias = '';
        if (String.isNotBlank(firstName)) {
            alias += firstName.substring(0, Math.min(1, firstName.length()));
        }
        if (String.isNotBlank(lastName)) {
            alias += lastName.substring(0, Math.min(4, lastName.length()));
        }
        if (String.isBlank(alias)) {
            alias = 'user';
        }
        return alias.toLowerCase();
    }
    
    private static String generateNickname(String firstName, String lastName) {
        String base = '';
        if (String.isNotBlank(firstName)) {
            base = firstName;
        }
        if (String.isNotBlank(lastName)) {
            base += (String.isNotBlank(base) ? '_' : '') + lastName;
        }
        if (String.isBlank(base)) {
            base = 'User';
        }
        return base + '_' + String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 4);
    }
    
    global class RegistrationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String userId;
    }
    
    public class RegistrationException extends Exception {}
}
