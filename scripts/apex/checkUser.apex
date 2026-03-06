// Check user status for pranaytiru473@gmail.com
List<User> users = [SELECT Id, Username, Email, IsActive, ContactId, Profile.Name, UserType 
                   FROM User 
                   WHERE Email = 'pranaytiru473@gmail.com' OR Username = 'pranaytiru473@gmail.com' 
                   LIMIT 1];
if (!users.isEmpty()) {
    User u = users[0];
    System.debug('=== USER INFO ===');
    System.debug('Id: ' + u.Id);
    System.debug('Username: ' + u.Username);
    System.debug('Email: ' + u.Email);
    System.debug('IsActive: ' + u.IsActive);
    System.debug('ContactId: ' + u.ContactId);
    System.debug('Profile: ' + u.Profile.Name);
    System.debug('UserType: ' + u.UserType);
    
    // Check permission sets
    List<PermissionSetAssignment> psas = [SELECT PermissionSet.Name, PermissionSet.Label 
                                          FROM PermissionSetAssignment 
                                          WHERE AssigneeId = :u.Id];
    System.debug('=== PERMISSION SETS ===');
    for (PermissionSetAssignment psa : psas) {
        System.debug('PS: ' + psa.PermissionSet.Name + ' (' + psa.PermissionSet.Label + ')');
    }
    
    // Check if user needs password reset
    List<UserLogin> logins = [SELECT Id, UserId, IsFrozen, IsPasswordLocked 
                              FROM UserLogin 
                              WHERE UserId = :u.Id LIMIT 1];
    if (!logins.isEmpty()) {
        UserLogin ul = logins[0];
        System.debug('=== LOGIN STATUS ===');
        System.debug('IsFrozen: ' + ul.IsFrozen);
        System.debug('IsPasswordLocked: ' + ul.IsPasswordLocked);
    }
} else {
    System.debug('USER NOT FOUND with email pranaytiru473@gmail.com');
}
