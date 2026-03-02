@isTest
private class GrantEligibilityServiceTest {
    
    @isTest
    static void testFullyEligibleApplication() {
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            '501(c)(3)',   // organizationType - valid nonprofit
            2020,          // yearFounded - 4+ years old
            500000,        // annualBudget - under $2M
            25000,         // amountRequested - under $50K
            60000,         // totalProjectCost - request is < 50% of cost
            100            // numBeneficiaries - over 50
        );
        Test.stopTest();
        
        System.assertEquals(6, result.totalPassed, 'All 6 rules should pass');
        System.assertEquals(true, result.isEligible, 'Application should be eligible');
        System.assertEquals(6, result.rules.size(), 'Should have 6 rules');
        
        for (GrantEligibilityService.EligibilityRule rule : result.rules) {
            System.assertEquals(true, rule.passed, 'Rule ' + rule.ruleId + ' should pass: ' + rule.message);
        }
    }
    
    @isTest
    static void testIneligibleOrganizationType() {
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            'For-Profit Corporation',
            2020,
            500000,
            25000,
            60000,
            100
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isEligible, 'For-profit should not be eligible');
        System.assertEquals(5, result.totalPassed, 'Only 5 rules should pass');
        
        GrantEligibilityService.EligibilityRule rule1 = result.rules[0];
        System.assertEquals(false, rule1.passed, 'Nonprofit status rule should fail');
    }
    
    @isTest
    static void testInsufficientOperatingHistory() {
        Integer currentYear = Date.today().year();
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            '501(c)(3)',
            currentYear,   // Founded this year - less than 2 years
            500000,
            25000,
            60000,
            100
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isEligible, 'New organization should not be eligible');
        System.assertEquals(5, result.totalPassed, 'Only 5 rules should pass');
        
        GrantEligibilityService.EligibilityRule rule2 = result.rules[1];
        System.assertEquals(false, rule2.passed, 'Operating history rule should fail');
    }
    
    @isTest
    static void testBudgetOverCap() {
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            '501(c)(3)',
            2020,
            2500000,       // Over $2M budget
            25000,
            60000,
            100
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isEligible, 'Large budget org should not be eligible');
        
        GrantEligibilityService.EligibilityRule rule3 = result.rules[2];
        System.assertEquals(false, rule3.passed, 'Budget cap rule should fail');
    }
    
    @isTest
    static void testFundingRatioExceeded() {
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            '501(c)(3)',
            2020,
            500000,
            40000,         // Requesting $40K
            60000,         // For $60K project = 66.7% ratio (exceeds 50%)
            100
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isEligible, 'High funding ratio should not be eligible');
        
        GrantEligibilityService.EligibilityRule rule4 = result.rules[3];
        System.assertEquals(false, rule4.passed, 'Funding ratio rule should fail');
    }
    
    @isTest
    static void testMaximumRequestExceeded() {
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            '501(c)(3)',
            2020,
            500000,
            75000,         // Over $50K maximum
            200000,        // Large project so ratio is OK
            100
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isEligible, 'Over max request should not be eligible');
        
        GrantEligibilityService.EligibilityRule rule5 = result.rules[4];
        System.assertEquals(false, rule5.passed, 'Maximum request rule should fail');
    }
    
    @isTest
    static void testInsufficientBeneficiaries() {
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            '501(c)(3)',
            2020,
            500000,
            25000,
            60000,
            30             // Under 50 beneficiaries
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isEligible, 'Low beneficiary count should not be eligible');
        
        GrantEligibilityService.EligibilityRule rule6 = result.rules[5];
        System.assertEquals(false, rule6.passed, 'Minimum impact rule should fail');
    }
    
    @isTest
    static void testNullValues() {
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            null,
            null,
            null,
            null,
            null,
            null
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isEligible, 'Null values should not be eligible');
        System.assertEquals(0, result.totalPassed, 'No rules should pass with null values');
    }
    
    @isTest
    static void testAllEligibleOrganizationTypes() {
        List<String> eligibleTypes = new List<String>{
            '501(c)(3)',
            '501(c)(4)',
            'Community-Based Organization',
            'Faith-Based Organization'
        };
        
        Test.startTest();
        for (String orgType : eligibleTypes) {
            GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
                orgType,
                2020,
                500000,
                25000,
                60000,
                100
            );
            
            GrantEligibilityService.EligibilityRule rule1 = result.rules[0];
            System.assertEquals(true, rule1.passed, 'Organization type ' + orgType + ' should be eligible');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testEdgeCases() {
        // Test exactly 2 years old
        Integer twoYearsAgo = Date.today().year() - 2;
        
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            '501(c)(3)',
            twoYearsAgo,   // Exactly 2 years
            1999999.99,    // Just under $2M
            50000,         // Exactly $50K max
            100000,        // Exactly 50% ratio
            50             // Exactly 50 beneficiaries
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isEligible, 'Edge case values should be eligible');
        System.assertEquals(6, result.totalPassed, 'All rules should pass at boundaries');
    }
    
    @isTest
    static void testResultJSONSerialization() {
        Test.startTest();
        GrantEligibilityService.EligibilityResult result = GrantEligibilityService.checkEligibility(
            '501(c)(3)',
            2020,
            500000,
            25000,
            60000,
            100
        );
        String jsonResult = result.toJSON();
        Test.stopTest();
        
        System.assertNotEquals(null, jsonResult, 'JSON should not be null');
        System.assert(jsonResult.contains('rules'), 'JSON should contain rules');
        System.assert(jsonResult.contains('isEligible'), 'JSON should contain isEligible');
    }
}
