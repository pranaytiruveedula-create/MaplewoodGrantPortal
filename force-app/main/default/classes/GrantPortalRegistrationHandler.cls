public without sharing class GrantPortalRegistrationHandler implements Auth.ConfigurableSelfRegHandler {
    
    private static final String DEFAULT_ACCOUNT_NAME = 'Grant Portal Applicants';
    private static final String COMMUNITY_PROFILE = 'Customer Community User';
    
    public class RegistrationException extends Exception {}
    
    public Id createUser(Id accountId, Id profileId, Map<SObjectField, String> registrationAttributes, String password) {
        String email = registrationAttributes.get(User.Email);
        String firstName = registrationAttributes.get(User.FirstName);
        String lastName = registrationAttributes.get(User.LastName);
        
        validateRequiredFields(email, lastName);
        checkForExistingUser(email);
        
        Account portalAccount = getOrCreatePortalAccount();
        Contact newContact = createContact(portalAccount.Id, firstName, lastName, email);
        User newUser = createPortalUser(newContact, profileId, password);
        
        return newUser.Id;
    }
    
    private void validateRequiredFields(String email, String lastName) {
        if (String.isBlank(email)) {
            throw new RegistrationException('Email address is required.');
        }
        if (String.isBlank(lastName)) {
            throw new RegistrationException('Last name is required.');
        }
        if (!isValidEmail(email)) {
            throw new RegistrationException('Please enter a valid email address.');
        }
    }
    
    private Boolean isValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        Matcher emailMatcher = emailPattern.matcher(email);
        return emailMatcher.matches();
    }
    
    private void checkForExistingUser(String email) {
        List<User> existingUsers = [
            SELECT Id, Username, Email 
            FROM User 
            WHERE Email = :email OR Username = :email
            LIMIT 1
        ];
        
        if (!existingUsers.isEmpty()) {
            throw new RegistrationException('An account with this email address already exists. Please use the login page or reset your password.');
        }
        
        List<Contact> existingContacts = [
            SELECT Id, Email 
            FROM Contact 
            WHERE Email = :email
            LIMIT 1
        ];
        
        if (!existingContacts.isEmpty()) {
            throw new RegistrationException('An account with this email address already exists. Please use the login page or reset your password.');
        }
    }
    
    private Account getOrCreatePortalAccount() {
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
    
    private Contact createContact(Id accountId, String firstName, String lastName, String email) {
        Contact newContact = new Contact(
            AccountId = accountId,
            FirstName = String.isNotBlank(firstName) ? firstName : '',
            LastName = lastName,
            Email = email
        );
        insert newContact;
        return newContact;
    }
    
    private User createPortalUser(Contact contact, Id profileId, String password) {
        Id actualProfileId = profileId;
        if (actualProfileId == null) {
            List<Profile> profiles = [
                SELECT Id FROM Profile WHERE Name = :COMMUNITY_PROFILE LIMIT 1
            ];
            if (!profiles.isEmpty()) {
                actualProfileId = profiles[0].Id;
            }
        }
        
        String uniqueUsername = contact.Email + '.' + System.currentTimeMillis();
        String nickname = generateNickname(contact.FirstName, contact.LastName);
        
        User newUser = new User(
            ContactId = contact.Id,
            ProfileId = actualProfileId,
            Username = uniqueUsername,
            Email = contact.Email,
            FirstName = contact.FirstName,
            LastName = contact.LastName,
            Alias = generateAlias(contact.FirstName, contact.LastName),
            CommunityNickname = nickname,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        
        if (String.isNotBlank(password)) {
            insert newUser;
            System.setPassword(newUser.Id, password);
        } else {
            insert newUser;
        }
        
        return newUser;
    }
    
    private String generateAlias(String firstName, String lastName) {
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
    
    private String generateNickname(String firstName, String lastName) {
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
}
