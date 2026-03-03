public with sharing class GrantAwardService {
    
    public class FactorScore {
        @AuraEnabled public String factorName;
        @AuraEnabled public String factorDescription;
        @AuraEnabled public Integer score;
        @AuraEnabled public Integer maxScore;
        @AuraEnabled public String detail;
        
        public FactorScore(String name, String descText, Integer scoreVal, String detailText) {
            this.factorName = name;
            this.factorDescription = descText;
            this.score = scoreVal;
            this.maxScore = 3;
            this.detail = detailText;
        }
    }
    
    public class AwardResult {
        @AuraEnabled public List<FactorScore> factors;
        @AuraEnabled public Integer totalScore;
        @AuraEnabled public Integer maxScore;
        @AuraEnabled public Decimal awardPercentage;
        @AuraEnabled public Decimal rawAwardAmount;
        @AuraEnabled public Decimal finalAwardAmount;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        
        public AwardResult() {
            this.factors = new List<FactorScore>();
            this.totalScore = 0;
            this.maxScore = 15;
            this.success = true;
        }
        
        public void addFactor(FactorScore factor) {
            this.factors.add(factor);
            this.totalScore += factor.score;
        }
        
        public String toJSON() {
            return JSON.serialize(this);
        }
    }
    
    @AuraEnabled
    public static AwardResult calculateAward(String applicationId) {
        AwardResult result = new AwardResult();
        
        try {
            Grant_Application__c app = [
                SELECT Id, Num_Beneficiaries__c, Year_Founded__c, Project_Category__c,
                       Annual_Budget__c, Amount_Requested__c, Total_Project_Cost__c
                FROM Grant_Application__c
                WHERE Id = :applicationId
                LIMIT 1
            ];
            
            result.addFactor(scoreCommunityImpact(app.Num_Beneficiaries__c));
            result.addFactor(scoreOrganizationTrackRecord(app.Year_Founded__c));
            result.addFactor(scoreProjectCategory(app.Project_Category__c));
            result.addFactor(scoreFinancialNeed(app.Annual_Budget__c));
            result.addFactor(scoreCostEfficiency(app.Amount_Requested__c, app.Total_Project_Cost__c));
            
            result.awardPercentage = (Decimal.valueOf(result.totalScore) / Decimal.valueOf(result.maxScore) * 100).setScale(2);
            result.rawAwardAmount = app.Amount_Requested__c * (result.awardPercentage / 100);
            result.finalAwardAmount = Math.min(roundToNearest100(result.rawAwardAmount), 50000);
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    @AuraEnabled
    public static AwardResult approveApplication(String applicationId, String reviewerComments) {
        AwardResult result = calculateAward(applicationId);
        
        if (!result.success) {
            return result;
        }
        
        try {
            Grant_Application__c app = new Grant_Application__c();
            app.Id = applicationId;
            app.Status__c = 'Approved';
            app.Award_Amount__c = result.finalAwardAmount;
            app.Award_Breakdown__c = result.toJSON();
            app.Reviewer__c = UserInfo.getUserId();
            app.Reviewed_Date__c = DateTime.now();
            if (String.isNotBlank(reviewerComments)) {
                app.Reviewer_Comments__c = reviewerComments;
            }
            
            update app;
            
            createStatusHistory(applicationId, 'Under Review', 'Approved', 'Application approved with award: $' + result.finalAwardAmount);
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    @AuraEnabled
    public static Boolean rejectApplication(String applicationId, String reviewerComments) {
        try {
            if (String.isBlank(reviewerComments)) {
                throw new AuraHandledException('Reviewer comments are required for rejection');
            }
            
            Grant_Application__c app = new Grant_Application__c();
            app.Id = applicationId;
            app.Status__c = 'Rejected';
            app.Reviewer_Comments__c = reviewerComments;
            app.Reviewer__c = UserInfo.getUserId();
            app.Reviewed_Date__c = DateTime.now();
            
            update app;
            
            createStatusHistory(applicationId, 'Under Review', 'Rejected', reviewerComments);
            
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean setUnderReview(String applicationId) {
        try {
            Grant_Application__c app = [
                SELECT Id, Status__c 
                FROM Grant_Application__c 
                WHERE Id = :applicationId
            ];
            
            if (app.Status__c == 'Submitted') {
                String oldStatus = app.Status__c;
                app.Status__c = 'Under Review';
                update app;
                createStatusHistory(applicationId, oldStatus, 'Under Review', 'Review started');
            }
            
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static FactorScore scoreCommunityImpact(Decimal beneficiaries) {
        Integer score;
        String detail;
        
        if (beneficiaries == null || beneficiaries < 50) {
            score = 0;
            detail = 'Below minimum (50)';
        } else if (beneficiaries <= 200) {
            score = 1;
            detail = '50-200 beneficiaries';
        } else if (beneficiaries <= 1000) {
            score = 2;
            detail = '201-1,000 beneficiaries';
        } else {
            score = 3;
            detail = '1,001+ beneficiaries';
        }
        
        return new FactorScore('Community Impact', 'Estimated beneficiaries', score, detail + ' (' + beneficiaries + ')');
    }
    
    private static FactorScore scoreOrganizationTrackRecord(Decimal yearFounded) {
        Integer score;
        String detail;
        Integer currentYear = Date.today().year();
        Integer yearsOperating = currentYear - Integer.valueOf(yearFounded);
        
        if (yearsOperating < 2) {
            score = 0;
            detail = 'Less than 2 years';
        } else if (yearsOperating <= 5) {
            score = 1;
            detail = '2-5 years';
        } else if (yearsOperating <= 15) {
            score = 2;
            detail = '6-15 years';
        } else {
            score = 3;
            detail = '16+ years';
        }
        
        return new FactorScore('Organization Track Record', 'Years operating', score, detail + ' (' + yearsOperating + ' years)');
    }
    
    private static FactorScore scoreProjectCategory(String category) {
        Integer score;
        String detail;
        
        Set<String> tier1 = new Set<String>{'Arts & Culture', 'Workforce Development', 'Other'};
        Set<String> tier2 = new Set<String>{'Youth Programs', 'Senior Services'};
        Set<String> tier3 = new Set<String>{'Public Health', 'Neighborhood Safety'};
        
        if (tier3.contains(category)) {
            score = 3;
            detail = 'High priority category';
        } else if (tier2.contains(category)) {
            score = 2;
            detail = 'Medium priority category';
        } else {
            score = 1;
            detail = 'Standard priority category';
        }
        
        return new FactorScore('Project Category Priority', 'Category alignment', score, detail + ' (' + category + ')');
    }
    
    private static FactorScore scoreFinancialNeed(Decimal annualBudget) {
        Integer score;
        String detail;
        
        if (annualBudget == null) {
            score = 0;
            detail = 'Budget not provided';
        } else if (annualBudget < 100000) {
            score = 3;
            detail = 'Under $100K';
        } else if (annualBudget < 500000) {
            score = 2;
            detail = '$100K-$499K';
        } else {
            score = 1;
            detail = '$500K+';
        }
        
        return new FactorScore('Financial Need', 'Annual operating budget', score, detail + ' ($' + annualBudget?.format() + ')');
    }
    
    private static FactorScore scoreCostEfficiency(Decimal amountRequested, Decimal totalProjectCost) {
        Integer score;
        String detail;
        
        if (amountRequested == null || totalProjectCost == null || totalProjectCost == 0) {
            score = 0;
            detail = 'Missing cost data';
        } else {
            Decimal ratio = (amountRequested / totalProjectCost) * 100;
            
            if (ratio <= 25) {
                score = 3;
                detail = '25% or less';
            } else if (ratio <= 40) {
                score = 2;
                detail = '26%-40%';
            } else {
                score = 1;
                detail = '41%-50%';
            }
            detail += ' (' + ratio.setScale(0) + '%)';
        }
        
        return new FactorScore('Cost Efficiency', 'Request/cost ratio', score, detail);
    }
    
    private static Decimal roundToNearest100(Decimal amount) {
        return Math.round(amount / 100) * 100;
    }
    
    private static void createStatusHistory(Id applicationId, String oldStatus, String newStatus, String comments) {
        Status_History__c history = new Status_History__c();
        history.Application__c = applicationId;
        history.Old_Status__c = oldStatus;
        history.New_Status__c = newStatus;
        history.Changed_At__c = DateTime.now();
        history.Comments__c = comments;
        insert history;
    }
}
