# Maplewood County Grant Portal \- Salesforce Track

## Salesforce Components

### Custom Objects

* `Grant_Application__c` \- Main application record (33 custom fields, 6 validation rules)
* `Status_History__c` \- Tracks status changes (6 custom fields)

### Apex Classes

| Class | Purpose | Test Coverage |
|:------|:--------|:--------------|
| `GrantEligibilityService` | 6\-rule eligibility checker | 100% |
| `GrantApplicationController` | Application submission/retrieval with CRUD/FLS enforcement | 98% |
| `GrantAwardService` | 5\-factor award calculator | 92% |
| `GrantReviewerController` | Reviewer dashboard data | 97% |
| `CustomLoginController` | Custom Experience Cloud login | \- |
| `CustomRegisterController` | Custom self\-registration with validation | \- |
| `AssignPermissionSetHandler` | Auto\-assigns permission sets to new community users | \- |
| `GrantPortalRegistrationHandler` | Registration handler for Experience Cloud | \- |
| `GrantApplicationTriggerHandler` | Trigger handler for status history tracking | \- |

### LWC Components

| Component | Location | Purpose |
|:----------|:---------|:--------|
| `grantApplicationForm` | Experience Cloud | Multi\-step application form with real\-time eligibility |
| `applicantDashboard` | Experience Cloud | Shows applicant's submitted applications and status |
| `customLogin` | Experience Cloud | Custom login page with branding |
| `customRegister` | Experience Cloud | Custom registration with password validation |
| `grantHomeContent` | Experience Cloud | Landing page content |
| `landingPage` | Experience Cloud | Home page component |
| `siteHeader` | Experience Cloud | Site header with navigation |
| `loginRedirect` | Experience Cloud | Login redirect handler |
| `reviewerDashboard` | Lightning App | Internal dashboard for reviewing/approving applications |

### Flows

* `Grant_Application_Status_Email_Alert` \- Sends email notifications when application status changes
* `Grant_Application_Wizard` \- Application wizard flow

### Triggers

* `GrantApplicationTrigger` \- Creates Status\_History\_\_c records on status changes
* `AssignPermissionSetToNewCommunityUser` \- Auto\-assigns Grant\_Application\_Access permission set to new community users

### Experience Cloud Site

* **Site Name:** Maplewood\_Grant\_Portal
* **URL Path:** /grants/

### Reports & Dashboards

* Grant Program Overview Dashboard
* Applications by Status Report
* Applications by Category Report
* Funding Summary Report

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
sf org login web --set-default --alias GrantDev
```

3. Deploy source:

```bash
sf project deploy start --source-dir force-app --wait 15
```

4. Assign permission sets:

```bash
sf org assign permset --name Grant_Reviewer --target-org GrantDev
sf org assign permset --name Grant_Applicant --target-org GrantDev
sf org assign permset --name Grant_Application_Access --target-org GrantDev
```

5. Configure Experience Cloud Site:
   * Setup → Digital Experiences → All Sites
   * Activate the "Maplewood Grant Portal" site
   * Publish the site

6. Configure Guest User Profile:
   * Setup → Digital Experiences → All Sites → Workspaces (for Maplewood Grant Portal)
   * Administration → Pages → Go to Builder
   * Settings → General → Guest User Profile
   * Enable Apex Class Access for: `CustomLoginController`, `CustomRegisterController`, `GrantPortalRegistrationHandler`

7. Access the Experience Cloud site at: `https://[your-domain].develop.my.site.com/grants/`

## Test Credentials

* **Applicant:** Register via Experience Cloud self\-registration (use any valid email)
* **Reviewer:** Log in as System Administrator with Grant\_Reviewer permission set

## Features Implemented

* [x] Experience Cloud registration with custom registration form
* [x] Custom login page with branding
* [x] Two\-section application form (Organization Info + Project Details)
* [x] Real\-time eligibility engine with 6 rules
* [x] Document upload capability (PDF, JPG, PNG up to 5MB)
* [x] Applicant dashboard showing application status with detail modal
* [x] Internal reviewer Lightning App
* [x] Award calculation engine with 5\-factor scoring matrix
* [x] Approve/Reject workflow with comments
* [x] Status history tracking via Apex trigger
* [x] Email notifications on status change (via Flow)
* [x] Auto\-assignment of permission sets to new community users
* [x] Validation rules for data integrity
* [x] Reports and Dashboard for administrators
* [x] US phone number formatting on application form

## Eligibility Engine

**Class:** `GrantEligibilityService.cls`

**Approach:** The eligibility engine evaluates 6 rules in real\-time as the applicant fills the form. Each rule returns a pass/fail status with a message. The LWC calls the `@AuraEnabled` method `checkEligibility()` on field changes.

**Rules:**

| Rule | Criteria |
|:-----|:---------|
| Nonprofit Status | Must be 501(c)(3), 501(c)(4), Community\-Based Organization, or Faith\-Based Organization |
| Operating History | Organization must have 2+ years of operation |
| Budget Cap | Annual budget under $2,000,000 |
| Funding Ratio | Request cannot exceed 50% of total project cost |
| Maximum Request | Grant request up to $50,000 |
| Community Impact | Must serve at least 50 beneficiaries |

## Award Calculator

**Class:** `GrantAwardService.cls`

**Approach:** When a reviewer clicks "Approve", the engine calculates the award using a 5\-factor scoring matrix. Each factor scores 1\-3 points. The award percentage equals total score divided by 15 (max), applied to the requested amount, rounded to nearest $100, and capped at $50,000.

**Scoring Matrix:**

| Factor | 1 Point | 2 Points | 3 Points |
|:-------|:--------|:---------|:---------|
| Community Impact | 50\-200 beneficiaries | 201\-1,000 | 1,001+ |
| Organization Track Record | 2\-5 years | 6\-15 years | 16+ years |
| Project Category Priority | Arts & Culture, Workforce Dev, Other | Youth Programs, Senior Services | Public Health, Neighborhood Safety |
| Financial Need | $500K\-$2M budget | $100K\-$499K | Under $100K |
| Cost Efficiency | 41\-50% ratio | 26\-40% ratio | 25% or less |

**Formula:**

```
Award = Amount_Requested × (Total_Score / 15)
Award = Round to nearest $100
Award = Cap at $50,000
```

## Known Limitations

* Email notifications may go to spam folder in development environments (expected behavior \- requires proper email authentication in production)
* Portal license limits may be reached in development orgs \- deactivate unused test users as needed
* File upload visibility defaults to Viewer access for community users

## AI Tool Usage

**Tools Used:** Cursor AI with Claude

**Help Example:** Used AI to implement the `AssignPermissionSetHandler` class with `@future` annotation to automatically assign permission sets to new community users upon registration, solving the CRUD/FLS permission issues for community users.

**Correction Example:** AI initially set `ContentDocumentLink.Visibility = 'InternalUsers'` which caused an `INVALID_FIELD_FOR_INSERT_UPDATE` error for community users. Corrected by removing the Visibility field and setting `ShareType = 'V'` to allow proper file sharing.

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── GrantEligibilityService.cls
│   ├── GrantApplicationController.cls
│   ├── GrantAwardService.cls
│   ├── GrantReviewerController.cls
│   ├── CustomLoginController.cls
│   ├── CustomRegisterController.cls
│   ├── AssignPermissionSetHandler.cls
│   ├── GrantPortalRegistrationHandler.cls
│   ├── GrantApplicationTriggerHandler.cls
│   └── *Test.cls (test classes)
├── lwc/
│   ├── grantApplicationForm/
│   ├── applicantDashboard/
│   ├── reviewerDashboard/
│   ├── customLogin/
│   ├── customRegister/
│   ├── grantHomeContent/
│   ├── landingPage/
│   ├── siteHeader/
│   └── loginRedirect/
├── objects/
│   ├── Grant_Application__c/
│   │   ├── fields/ (33 fields)
│   │   └── validationRules/ (6 rules)
│   └── Status_History__c/
│       └── fields/ (6 fields)
├── triggers/
│   ├── GrantApplicationTrigger.trigger
│   └── AssignPermissionSetToNewCommunityUser.trigger
├── flows/
│   ├── Grant_Application_Status_Email_Alert.flow-meta.xml
│   └── Grant_Application_Wizard.flow-meta.xml
├── permissionsets/
│   ├── Grant_Applicant.permissionset-meta.xml
│   ├── Grant_Reviewer.permissionset-meta.xml
│   └── Guest_User_Registration.permissionset-meta.xml
├── digitalExperiences/
│   └── site/Maplewood_Grant_Portal1/
├── reports/
├── dashboards/
├── email/
└── networks/
```

## Test Results

| Metric | Result |
|:-------|:-------|
| Total Tests | 89 |
| Pass Rate | 100% |
| Org\-Wide Coverage | 86% |
| GrantEligibilityService | 100% |
| GrantApplicationController | 98% |
| GrantAwardService | 92% |
| GrantReviewerController | 97% |

## Demo Video Script

1. Show Experience Cloud landing page
2. Register as a new applicant
3. Fill the application form \- show eligibility indicators updating in real\-time
4. Trigger a failing eligibility rule (e.g., budget over $2M), then fix it
5. Upload a supporting document
6. Review and submit the application
7. Show the applicant dashboard with the submitted application
8. Switch to the reviewer Lightning App
9. Open the application \- show eligibility results
10. Approve the application \- show award calculation breakdown
11. Switch back to applicant view \- show approved status and award amount
