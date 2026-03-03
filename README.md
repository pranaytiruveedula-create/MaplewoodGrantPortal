# Maplewood County Grant Portal \- Salesforce Track

## Salesforce Components

* **Custom Objects:**
  * `Grant_Application__c` \- Main application record (33 custom fields)
  * `Status_History__c` \- Tracks status changes (6 custom fields)

* **Apex Classes:**
  * `GrantEligibilityService` \- 6\-rule eligibility checker (100% coverage)
  * `GrantApplicationController` \- Application submission/retrieval (98% coverage)
  * `GrantAwardService` \- 5\-factor award calculator (92% coverage)
  * `GrantReviewerController` \- Reviewer dashboard data (97% coverage)
  * Test classes for each service

* **LWC Components:**
  * `grantApplicationForm` \- Multi\-step application form with real\-time eligibility
  * `applicantDashboard` \- Shows applicant's submitted applications and status
  * `reviewerDashboard` \- Internal dashboard for reviewing/approving applications

* **Experience Cloud Site:** Maplewood\_Grant\_Portal

## Prerequisites

* Salesforce CLI (sf/sfdx)
* A Salesforce Developer Org (free at developer.salesforce.com)
* Experience Cloud enabled in your org

## Setup Instructions

1. Clone the repository:

```bash
git clone [repository-url]
cd MaplewoodGrantPortal
```

2. Authenticate to your org:

```bash
sf org login web --set-default --alias myorg
```

3. Deploy source:

```bash
sf project deploy start --source-dir force-app --wait 15
```

4. Assign permission sets:

```bash
sf org assign permset --name Grant_Reviewer --target-org myorg
sf org assign permset --name Grant_Applicant --target-org myorg
```

5. Create the Experience Cloud site:
   * Setup → Digital Experiences → All Sites → New
   * Select "Customer Account Portal" template
   * Name: "Maplewood Grant Portal"
   * Add `grantApplicationForm` and `applicantDashboard` LWC components to pages
   * Publish the site

6. Create the Grant Reviewer Lightning App:
   * Setup → App Manager → New Lightning App
   * Name: "Grant Reviewer"
   * Add `Grant_Application__c` tab and a new tab for `reviewerDashboard` component

7. Access the Experience Cloud site at: `https://[your-domain].my.site.com/grants/`

## Test Credentials

* **Applicant:** Register via Experience Cloud self\-registration
* **Reviewer:** Log in as System Administrator with Grant\_Reviewer permission set

## Features Implemented

* [x] Experience Cloud registration
* [x] Two\-section application form (Organization Info + Project Details)
* [x] Real\-time eligibility engine with 6 rules
* [x] Document upload capability
* [x] Applicant dashboard showing application status
* [x] Internal reviewer Lightning App
* [x] Award calculation engine with 5\-factor scoring matrix
* [x] Approve/Reject workflow with comments
* [x] Status history tracking
* [x] Validation rules for data integrity

## Eligibility Engine

**Class:** `GrantEligibilityService.cls`

**Approach:** The eligibility engine evaluates 6 rules in real\-time as the applicant fills the form. Each rule returns a pass/fail status with a message. The LWC calls the `@AuraEnabled` method `checkEligibility()` on field changes.

**Rules:**

| Rule | Criteria |
|:-----|:---------|
| Nonprofit Status | Must be 501(c)(3), 501(c)(4), or 501(c)(6) |
| Operating History | Organization must have 2+ years of operation |
| Budget Range | Annual budget between $50,000 and $2,000,000 |
| Request Amount | Grant request between $5,000 and $50,000 |
| Matching Funds | Request cannot exceed 50% of total project cost |
| Community Impact | Must serve at least 50 beneficiaries |

## Award Calculator

**Class:** `GrantAwardService.cls`

**Approach:** When a reviewer clicks "Approve", the engine calculates the award using a 5\-factor scoring matrix. Each factor scores 1\-3 points. The award percentage equals total score divided by 15 (max), applied to the requested amount, rounded to nearest $100, and capped at $50,000.

**Scoring Matrix:**

| Factor | 1 Point | 2 Points | 3 Points |
|:-------|:--------|:---------|:---------|
| Community Impact | 50\-200 beneficiaries | 201\-1,000 | 1,001+ |
| Organization Track Record | 2\-5 years | 6\-15 years | 16+ years |
| Project Category Priority | Arts, Workforce Dev, Other | Youth, Senior Services | Public Health, Safety |
| Financial Need | $500K+ budget | $100K\-$499K | Under $100K |
| Cost Efficiency | 41\-50% ratio | 26\-40% ratio | 25% or less |

**Formula:**

```
Award = Amount_Requested × (Total_Score / 15)
Award = Round to nearest $100
Award = Cap at $50,000
```

## Known Limitations

* File upload from LWC to Apex requires additional configuration for Community users
* Form submission as Community user may require profile\-level Apex class access grants
* The "New Application" navigation button uses `NavigationMixin` which may need page configuration in Experience Builder

## AI Tool Usage

**Tools Used:** Cursor AI with Claude

**Help Example:** Used AI to generate the complete 5\-factor scoring matrix implementation in `GrantAwardService.cls`, including the inner classes for structured results and all scoring logic based on the specification.

**Correction Example:** AI initially used `desc` as a variable name in `GrantAwardService.cls`, which is a reserved word in Apex. The deployment failed with "Identifier name is reserved: desc". Corrected by renaming the variable to `descText`.

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── GrantEligibilityService.cls
│   ├── GrantEligibilityServiceTest.cls
│   ├── GrantApplicationController.cls
│   ├── GrantApplicationControllerTest.cls
│   ├── GrantAwardService.cls
│   ├── GrantAwardServiceTest.cls
│   ├── GrantReviewerController.cls
│   └── GrantReviewerControllerTest.cls
├── lwc/
│   ├── grantApplicationForm/
│   ├── applicantDashboard/
│   └── reviewerDashboard/
├── objects/
│   ├── Grant_Application__c/
│   │   ├── fields/ (33 fields)
│   │   └── validationRules/ (6 rules)
│   └── Status_History__c/
│       └── fields/ (6 fields)
├── permissionsets/
│   ├── Grant_Applicant.permissionset-meta.xml
│   └── Grant_Reviewer.permissionset-meta.xml
├── layouts/
└── tabs/
```

## Test Results

| Metric | Result |
|:-------|:-------|
| Total Tests | 64 |
| Pass Rate | 100% |
| Org\-Wide Coverage | 86% |
| GrantEligibilityService | 100% |
| GrantApplicationController | 98% |
| GrantAwardService | 92% |
| GrantReviewerController | 97% |
