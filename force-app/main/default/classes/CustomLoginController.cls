public without sharing class CustomLoginController {
    
    @AuraEnabled
    public static String login(String username, String password, String startUrl) {
        try {
            ApexPages.PageReference pageRef = Site.login(username, password, startUrl);
            if (pageRef != null) {
                return pageRef.getUrl();
            }
            throw new AuraHandledException('Invalid username or password.');
        } catch (Exception e) {
            throw new AuraHandledException('Invalid username or password. Please try again.');
        }
    }
}
