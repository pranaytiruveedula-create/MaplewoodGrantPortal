public with sharing class GrantEligibilityService {
    
    public class EligibilityRule {
        @AuraEnabled public Integer ruleId;
        @AuraEnabled public String ruleName;
        @AuraEnabled public Boolean passed;
        @AuraEnabled public String message;
        
        public EligibilityRule(Integer ruleId, String ruleName, Boolean passed, String message) {
            this.ruleId = ruleId;
            this.ruleName = ruleName;
            this.passed = passed;
            this.message = message;
        }
    }
    
    public class EligibilityResult {
        @AuraEnabled public List<EligibilityRule> rules;
        @AuraEnabled public Integer totalPassed;
        @AuraEnabled public Integer totalRules;
        @AuraEnabled public Boolean isEligible;
        
        public EligibilityResult() {
            this.rules = new List<EligibilityRule>();
            this.totalPassed = 0;
            this.totalRules = 6;
            this.isEligible = false;
        }
        
        public void addRule(EligibilityRule rule) {
            this.rules.add(rule);
            if (rule.passed) {
                this.totalPassed++;
            }
            this.isEligible = (this.totalPassed == this.totalRules);
        }
        
        public String toJSON() {
            return JSON.serialize(this);
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static EligibilityResult checkEligibility(
        String organizationType,
        Integer yearFounded,
        Decimal annualBudget,
        Decimal amountRequested,
        Decimal totalProjectCost,
        Integer numBeneficiaries
    ) {
        EligibilityResult result = new EligibilityResult();
        
        // Rule 1: Nonprofit Status
        result.addRule(checkNonprofitStatus(organizationType));
        
        // Rule 2: Minimum Operating History (2 years)
        result.addRule(checkOperatingHistory(yearFounded));
        
        // Rule 3: Budget Cap (under $2M)
        result.addRule(checkBudgetCap(annualBudget));
        
        // Rule 4: Funding Ratio (request <= 50% of project cost)
        result.addRule(checkFundingRatio(amountRequested, totalProjectCost));
        
        // Rule 5: Maximum Request ($50,000)
        result.addRule(checkMaximumRequest(amountRequested));
        
        // Rule 6: Minimum Impact (50 beneficiaries)
        result.addRule(checkMinimumImpact(numBeneficiaries));
        
        return result;
    }
    
    private static EligibilityRule checkNonprofitStatus(String organizationType) {
        Set<String> eligibleTypes = new Set<String>{
            '501(c)(3)',
            '501(c)(4)',
            'Community-Based Organization',
            'Faith-Based Organization'
        };
        
        if (String.isBlank(organizationType)) {
            return new EligibilityRule(
                1,
                'Nonprofit Status',
                false,
                'Organization type is required'
            );
        }
        
        Boolean passed = eligibleTypes.contains(organizationType);
        String message = passed 
            ? 'Eligible organization type' 
            : 'Only nonprofit and community organizations are eligible';
        
        return new EligibilityRule(1, 'Nonprofit Status', passed, message);
    }
    
    private static EligibilityRule checkOperatingHistory(Integer yearFounded) {
        if (yearFounded == null) {
            return new EligibilityRule(
                2,
                'Operating History',
                false,
                'Year founded is required'
            );
        }
        
        Integer currentYear = Date.today().year();
        Integer yearsOperating = currentYear - yearFounded;
        Boolean passed = yearsOperating >= 2;
        
        String message = passed 
            ? 'Organization has been operating for ' + yearsOperating + ' years'
            : 'Organization must be at least 2 years old (currently ' + yearsOperating + ' years)';
        
        return new EligibilityRule(2, 'Operating History', passed, message);
    }
    
    private static EligibilityRule checkBudgetCap(Decimal annualBudget) {
        if (annualBudget == null) {
            return new EligibilityRule(
                3,
                'Budget Cap',
                false,
                'Annual budget is required'
            );
        }
        
        Decimal budgetLimit = 2000000;
        Boolean passed = annualBudget < budgetLimit;
        
        String message = passed 
            ? 'Operating budget is within limit' 
            : 'Organizations with budgets of $2M or more are not eligible';
        
        return new EligibilityRule(3, 'Budget Cap', passed, message);
    }
    
    private static EligibilityRule checkFundingRatio(Decimal amountRequested, Decimal totalProjectCost) {
        if (amountRequested == null || totalProjectCost == null || totalProjectCost == 0) {
            return new EligibilityRule(
                4,
                'Funding Ratio',
                false,
                'Amount requested and total project cost are required'
            );
        }
        
        Decimal ratio = (amountRequested / totalProjectCost) * 100;
        Boolean passed = ratio <= 50;
        
        String message = passed 
            ? 'Requested amount is ' + ratio.setScale(0) + '% of project cost'
            : 'Requested amount cannot exceed 50% of total project cost (currently ' + ratio.setScale(0) + '%)';
        
        return new EligibilityRule(4, 'Funding Ratio', passed, message);
    }
    
    private static EligibilityRule checkMaximumRequest(Decimal amountRequested) {
        if (amountRequested == null) {
            return new EligibilityRule(
                5,
                'Maximum Request',
                false,
                'Amount requested is required'
            );
        }
        
        Decimal maxRequest = 50000;
        Boolean passed = amountRequested <= maxRequest;
        
        String message = passed 
            ? 'Requested amount is within the $50,000 maximum'
            : 'Maximum grant amount is $50,000';
        
        return new EligibilityRule(5, 'Maximum Request', passed, message);
    }
    
    private static EligibilityRule checkMinimumImpact(Integer numBeneficiaries) {
        if (numBeneficiaries == null) {
            return new EligibilityRule(
                6,
                'Minimum Impact',
                false,
                'Number of beneficiaries is required'
            );
        }
        
        Integer minBeneficiaries = 50;
        Boolean passed = numBeneficiaries >= minBeneficiaries;
        
        String message = passed 
            ? 'Project will serve ' + numBeneficiaries + ' beneficiaries'
            : 'Project must serve at least 50 beneficiaries (currently ' + numBeneficiaries + ')';
        
        return new EligibilityRule(6, 'Minimum Impact', passed, message);
    }
}
