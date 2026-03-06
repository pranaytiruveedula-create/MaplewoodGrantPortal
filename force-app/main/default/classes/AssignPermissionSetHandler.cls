public without sharing class AssignPermissionSetHandler {
    
    private static final String PERMISSION_SET_NAME = 'Grant_Applicant';
    private static final String COMMUNITY_PROFILE_NAME = 'Customer Community User';
    
    @future
    public static void assignPermissionSets(Set<Id> userIds) {
        try {
            PermissionSet ps = [
                SELECT Id 
                FROM PermissionSet 
                WHERE Name = :PERMISSION_SET_NAME 
                LIMIT 1
            ];
            
            List<User> communityUsers = [
                SELECT Id, ProfileId, Profile.Name 
                FROM User 
                WHERE Id IN :userIds 
                AND Profile.Name = :COMMUNITY_PROFILE_NAME
                AND IsActive = true
            ];
            
            if (communityUsers.isEmpty()) {
                return;
            }
            
            Set<Id> communityUserIds = new Set<Id>();
            for (User u : communityUsers) {
                communityUserIds.add(u.Id);
            }
            
            Set<Id> alreadyAssigned = new Set<Id>();
            for (PermissionSetAssignment existing : [
                SELECT AssigneeId 
                FROM PermissionSetAssignment 
                WHERE PermissionSetId = :ps.Id 
                AND AssigneeId IN :communityUserIds
            ]) {
                alreadyAssigned.add(existing.AssigneeId);
            }
            
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (Id userId : communityUserIds) {
                if (!alreadyAssigned.contains(userId)) {
                    assignments.add(new PermissionSetAssignment(
                        AssigneeId = userId,
                        PermissionSetId = ps.Id
                    ));
                }
            }
            
            if (!assignments.isEmpty()) {
                insert assignments;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error assigning permission set: ' + e.getMessage());
        }
    }
}
