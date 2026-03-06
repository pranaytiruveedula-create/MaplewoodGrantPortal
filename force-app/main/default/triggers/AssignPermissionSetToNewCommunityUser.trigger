trigger AssignPermissionSetToNewCommunityUser on User (after insert) {
    AssignPermissionSetHandler.assignPermissionSets(Trigger.newMap.keySet());
}
