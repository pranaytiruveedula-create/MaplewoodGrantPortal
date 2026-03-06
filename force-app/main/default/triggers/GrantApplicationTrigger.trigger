trigger GrantApplicationTrigger on Grant_Application__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        GrantApplicationTriggerHandler.handleStatusChange(Trigger.new, Trigger.oldMap);
    }
}
