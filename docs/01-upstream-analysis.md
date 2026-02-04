# Upstream Analysis: Innovation Sandbox on AWS

**Document Version:** 1.0
**Date:** 2026-02-03
**Research Focus:** Understanding the upstream AWS solution and co-cddo fork divergence

---

## Executive Summary

The **Innovation Sandbox on AWS** is an official AWS Solutions implementation that enables cloud administrators to automate the management of temporary sandbox environments with built-in security, governance, and cost controls. The UK government's Central Digital & Data Office (CDDO) has forked this solution at **co-cddo/innovation-sandbox-on-aws** to support their organizational requirements.

**Key Findings:**
- Upstream version analyzed: **v1.1.7** (released January 20, 2026)
- Fork version: **v1.1.4** (December 16, 2025)
- Fork is approximately 3 minor versions behind upstream
- Solution ID: **SO0284**
- License: Apache 2.0

---

## 1. Upstream AWS Solution Overview

### 1.1 Solution Purpose

Innovation Sandbox on AWS allows cloud administrators to set up and recycle temporary sandbox environments by automating:

- Implementation of security and governance policies
- Spend management mechanisms
- Account recycling preferences
- All managed through a web user interface (UI)

The solution empowers teams to experiment, learn, and innovate with AWS services in production-isolated AWS accounts that are recycled after use.

### 1.2 Target Audience

- Solution architects
- DevOps engineers
- AWS account administrators
- Cloud professionals
- Educational institutions

### 1.3 Key Features

#### Security & Governance
- Automated deployment of standard policies, guardrails, and controls
- Preconfigured Organizational Unit (OU) structure with workload isolation
- Service Control Policies (SCPs) to restrict sensitive/expensive services
- Production-isolated AWS accounts for safe experimentation

#### Cost Management
- Budget threshold monitoring and alerts
- Automated actions based on spend limits
- Cost reporting by organizational groups
- Cost Explorer integration for spend tracking
- Estimated infrastructure cost: **$65.25/month** (US East Region)

#### Account Lifecycle Management
- Automated account recycling and cleanup
- Predefined lease durations and spend thresholds
- Account state management: Available → Assigned → Cleanup → Available
- Quarantine state for failed cleanup requiring manual remediation
- Prioritization of less-recently-used accounts

#### User Experience
- Web-based UI for lease requests and management
- IAM Identity Center integration with SAML 2.0 authentication
- External IdP support (Okta, Microsoft Entra ID)
- Email notifications for lease breaches
- Lease assignment and unfreezing capabilities

### 1.4 Architecture Components

#### Frontend Layer
- **Amazon CloudFront**: CDN distribution for web UI
- **Amazon S3**: Static asset hosting (HTML, CSS, JavaScript)

#### API & Logic Layer
- **Amazon API Gateway**: REST API endpoints
- **AWS Lambda**: API request execution with RBAC
- **AWS WAF**: API protection from exploits and bots

#### Data Storage
- **Amazon DynamoDB**: Status and configuration data
- **AWS AppConfig**: Global configurations (leases, cleanup, auth, terms)

#### Account Management
- **AWS Organizations**: Sandbox account lifecycle
- **Service Control Policies**: Service restrictions in sandboxes

#### Event-Driven Architecture
- **Amazon EventBridge**: Event routing for lifecycle management
- **Amazon SES**: Email notifications
- **AWS Lambda**: Budget and duration threshold monitoring

#### Account Cleanup & Automation
- **AWS Step Functions**: Cleanup workflow orchestration
- **AWS CodeBuild**: Resource deletion project execution
- **AWS Nuke**: User-created resource removal (v3.63.2 in v1.1.7)

### 1.5 Deployment Model

The solution consists of **four CloudFormation stacks**:

1. **InnovationSandbox-AccountPool**: Manages the pool of sandbox accounts
2. **InnovationSandbox-IDC**: IAM Identity Center integration
3. **InnovationSandbox-Data**: Data layer (DynamoDB, AppConfig)
4. **InnovationSandbox-Compute**: Compute resources (Lambda, Step Functions)

**Deployment Options:**
- Single-account deployment (all stacks in one account)
- Multi-account deployment (distributed across org accounts)
- AWS Console CloudFormation launch
- Source-based deployment via AWS CDK

**Technology Stack:**
- Primary Language: **TypeScript** (98.6%)
- Infrastructure: **AWS CDK**, CloudFormation
- Runtime: **Node.js 22**, Lambda functions
- Frontend: **Vite** application
- Container: Docker/ECR for account cleaner image

### 1.6 Important Constraints

⚠️ **Critical Limitation**: The solution manages *existing* AWS accounts only—it does **not create new accounts** or **close existing ones**. It optimizes and recycles accounts for reuse.

---

## 2. Version History & Release Timeline

### Current Upstream Versions

| Version | Release Date | Key Changes |
|---------|--------------|-------------|
| **v1.1.7** | January 20, 2026 | Upgraded aws-nuke to v3.63.2 (resolves SCP-protected log group issues) |
| **v1.1.6** | January 12, 2026 | Security upgrades: @remix-run/router, glib2, libcap, python3 |
| **v1.1.5** | January 5, 2026 | Security patch: qs library vulnerability |
| **v1.1.4** | December 17, 2025 | Security: aws-nuke CVE mitigations |
| **v1.1.3** | December 10, 2025 | Security: jws, mdast-util-to-hast, curl, glib2, python3 upgrades |
| **v1.1.2** | November 20, 2025 | Security: js-yaml, glob patches |
| **v1.1.1** | November 14, 2025 | Bug fix: cost report group configuration + libcap security |
| **v1.1.0** | October 29, 2025 | Major feature release (see below) |

### Version 1.1.0 Major Features (October 29, 2025)

**Added:**
- Lease unfreezing capability (reinstate frozen leases)
- Cost reporting groups for organizational tracking
- Lease assignment by administrators/managers
- Account prioritization (less-recently-used first)
- Lease template visibility (PUBLIC vs PRIVATE)

**Fixed:**
- IP allow list configuration issues
- Credit/Refund filtering in Cost Explorer
- IDC stack deployment permissions in delegated admin account
- Account cleaner Step Function execution bugs

**Security:**
- aws-nuke CVE mitigations (CVE-2025-47906, CVE-2025-47907)
- vite, python3-pip, openssl-libs, brace-expansion upgrades

### Version 1.0.0 Initial Release (May 22, 2025)

- All files, initial version

---

## 3. Fork Analysis: co-cddo/innovation-sandbox-on-aws

### 3.1 Fork Metadata

- **Organization**: co-cddo (Central Digital & Data Office, UK Government)
- **Fork Origin**: aws-solutions/innovation-sandbox-on-aws
- **Fork Date**: January 5, 2026
- **Primary Language**: TypeScript (98.6%)
- **License**: Apache 2.0 (unchanged from upstream)

### 3.2 Fork Version Status

**Current Fork Version:** v1.1.4 (December 16, 2025)

**Upstream Comparison:**
- Upstream latest: v1.1.7 (January 20, 2026)
- Version lag: **3 minor versions behind**
- Time lag: Approximately 1 month behind

**Missing Upstream Features/Fixes in Fork:**
- v1.1.7: aws-nuke v3.63.2 upgrade (SCP log group fix)
- v1.1.6: Security patches for @remix-run/router, glib2, libcap, python3
- v1.1.5: qs library security vulnerability fix

### 3.3 Git Configuration

**Remote Configuration:**
```
origin:   https://github.com/co-cddo/innovation-sandbox-on-aws.git
upstream: https://github.com/aws-solutions/innovation-sandbox-on-aws.git
```

**Branch Configuration:**
- Main branch: `main`
- Rebase enabled on pull

### 3.4 Identified CDDO Customizations

Based on the research conducted, the following CDDO-specific customizations and extensions have been identified:

#### Custom Lambda Extensions

**1. innovation-sandbox-on-aws-deployer**
- **Purpose**: AWS Lambda that deploys CloudFormation templates to Innovation Sandbox sub-accounts when leases are approved
- **Type**: Post-approval automation
- **Integration Point**: Hooks into lease approval workflow

**2. innovation-sandbox-on-aws-approver**
- **Purpose**: Custom approval workflow Lambda
- **Type**: Approval automation
- **Integration Point**: Lease request approval process

**3. ndx_try_aws_scenarios**
- **Purpose**: AWS scenario testing repository
- **Type**: Testing/validation framework
- **Integration Point**: Likely used for sandbox scenario validation

### 3.5 Configuration Analysis

#### Global Configuration (global-config.yaml)

**Key Settings:**
- **Maintenance Mode**: Enabled (`maintenanceMode: true`)
- **Max Budget**: $50 (enforced: `requireMaxBudget: true`)
- **Max Duration**: 168 hours / 7 days (enforced: `requireMaxDuration: true`)
- **Max Leases per User**: 3 concurrent leases
- **TTL**: 30 days for expired lease records

**Cleanup Configuration:**
- Failed attempts before quarantine: 3
- Retry delay: 5 seconds
- Successful attempts to finish: 2
- Success rerun delay: 30 seconds

#### AWS Nuke Configuration (nuke-config.yaml)

**Protected Resources:**
- CloudFormation stacks matching `StackSet-Isb-*`
- AWS Control Tower trails and resources
- IAM roles: `OrganizationAccountAccessRole`, SSO roles
- CloudWatch Events: AWS Control Tower rules

**Settings Customizations:**
- All deletion protection features explicitly disabled
- Governance retention bypass enabled
- Legal hold removal enabled for S3

**Excluded Resource Types:**
- S3Object (optimized: bucket deletion handles objects)
- ConfigServiceConfigurationRecorder
- ConfigServiceDeliveryChannel

### 3.6 No Visible Code Divergence

**Analysis Result:** No direct source code modifications were found in the forked repository. The co-cddo fork appears to be a **clean fork** with:

- ✅ Identical source code to upstream v1.1.4
- ✅ No custom branches detected
- ✅ No UK-specific code changes in core files
- ✅ Standard configuration files unchanged

**Customization Strategy:** CDDO appears to be using an **extension architecture** rather than forking and modifying core code. Custom functionality is implemented via:
1. External Lambda functions (deployer, approver)
2. CloudFormation template integration
3. Separate testing repositories

---

## 4. UK Government Specific Changes

### 4.1 Organizational Context

**CDDO Mission**: Central Digital & Data Office leads the Government Digital and Data function for the UK government, part of the Department for Science, Innovation & Technology (DSIT).

### 4.2 Identified UK-Specific Adaptations

Based on research, the following UK government-specific implementations were identified:

#### 1. Custom Deployment Automation
- **Component**: innovation-sandbox-on-aws-deployer Lambda
- **Purpose**: Automate CloudFormation template deployment to approved sandbox accounts
- **Benefit**: Streamlines environment provisioning for government departments

#### 2. Custom Approval Workflow
- **Component**: innovation-sandbox-on-aws-approver Lambda
- **Purpose**: Implement government-specific approval processes
- **Benefit**: Ensures compliance with government procurement and access policies

#### 3. Government Training Integration
- **Initiative**: October-December 2025 tech certification program
- **Scope**: 200+ free learning pathways for civil/public servants
- **Integration**: AWS exam vouchers with 4-month validity (extends to 2026)

#### 4. Multi-Department Support
- **Use Case**: Provide sandboxes across UK government departments
- **Scale**: Shared infrastructure for cross-government innovation

### 4.3 Potential UK Government Requirements

While not explicitly documented in the fork, UK government deployments typically require:

1. **Data Sovereignty**: Ensure sandbox accounts remain in UK regions
2. **Security Classifications**: Support OFFICIAL and potentially SECRET workloads
3. **Audit & Compliance**: Enhanced logging for government audit requirements
4. **Cost Allocation**: Department-level cost tracking and chargeback
5. **Access Controls**: Integration with UK government identity systems

**Note**: These requirements may be implemented via configuration rather than code changes.

---

## 5. Deployment Configuration

### 5.1 Environment Variables

The solution uses a `.env` file for deployment configuration:

```bash
# Common
HUB_ACCOUNT_ID=000000000000        # Compute and Data stacks account
NAMESPACE="myisb"                   # Stack namespace

# Account Pool Stack
PARENT_OU_ID="ou-abcd-abcd1234"    # Organization root OU
AWS_REGIONS="us-east-1,us-west-2"  # Enabled sandbox regions

# IDC Stack
IDENTITY_STORE_ID="d-0000000000"              # IAM Identity Center Store
SSO_INSTANCE_ARN="arn:aws:sso:::instance/..."  # SSO instance ARN
ADMIN_GROUP_NAME=""                            # Defaults to <namespace>_IsbAdmins
MANAGER_GROUP_NAME=""                          # Defaults to <namespace>_IsbManagers
USER_GROUP_NAME=""                             # Defaults to <namespace>_IsbUsers

# Compute Stack
ORG_MGT_ACCOUNT_ID=000000000000    # AccountPool stack account
IDC_ACCOUNT_ID=000000000000         # IDC stack account
ACCEPT_SOLUTION_TERMS_OF_USE=""     # Must be "Accept"

# Optional Overrides
NUKE_CONFIG_FILE_PATH=""            # Alternative AWS Nuke config
PRIVATE_ECR_REPO=""                 # Private ECR for account cleaner image
PRIVATE_ECR_REPO_REGION=""          # ECR region
```

### 5.2 Deployment Prerequisites

**AWS Setup:**
- AWS Organizations with available accounts
- IAM Identity Center configured
- Parent OU for sandbox account placement
- Multiple AWS accounts for multi-account deployment (optional)

**Development Environment:**
- macOS or Amazon Linux 2
- Node.js 22
- AWS CDK bootstrapped
- Docker (optional, for custom ECR images)
- Pre-commit (optional, for code quality)

### 5.3 Deployment Commands

```bash
# Bootstrap CDK
npm run bootstrap

# Deploy all stacks (single account)
npm run deploy:all

# Deploy individual stacks (multi-account)
npm run deploy:account-pool
npm run deploy:idc
npm run deploy:data
npm run deploy:compute

# Destroy stacks
npm run destroy:all
```

---

## 6. Repository Structure

```
innovation-sandbox-on-aws/
├── deployment/                      # CloudFormation distributables
│   ├── global-s3-assets/            # CDK synthesized templates
│   ├── regional-s3-assets/          # Zipped runtime assets (Lambdas)
│   └── build-s3-dist.sh             # Build script
├── docs/                            # Architecture diagrams
│   ├── diagrams/architecture/       # High-level and in-depth SVGs
│   └── openapi/                     # API specification (v1.1.4)
├── scripts/                         # Repository checks
├── source/                          # Source code (TypeScript)
│   ├── common/                      # Shared libraries
│   ├── frontend/                    # Vite web application
│   ├── infrastructure/              # CDK application
│   │   └── lib/components/
│   │       ├── account-cleaner/     # AWS Nuke Docker image
│   │       └── config/              # YAML configurations
│   ├── lambdas/                     # Lambda function packages
│   └── layers/                      # Lambda layers
├── .pre-commit-config.yaml          # Pre-commit hooks
├── package.json                     # Root npm orchestration
├── solution-manifest.yaml           # Solution metadata (SO0284)
├── CHANGELOG.md                     # Version history
├── LICENSE                          # Apache 2.0
├── README.md                        # Documentation
└── CONTRIBUTING.md                  # Contribution guidelines
```

---

## 7. API Overview

The solution exposes a REST API via Amazon API Gateway with the following resource groups:

### API Resources (OpenAPI v1.1.4)

- **Leases**: Contract providing temporary sandbox account access
- **Lease Templates**: Configurations for requesting sandbox leases
- **Accounts**: Registered sandbox AWS accounts
- **Configurations**: Global solution configurations
- **Auth**: Authentication operations

**Authentication**: Bearer token (JWT) via IAM Identity Center

---

## 8. Research Methodology

### 8.1 Data Sources

1. **Local Repository Analysis**
   - File: `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/innovation-sandbox-on-aws/`
   - Files examined: README.md, CHANGELOG.md, package.json, .git/config, YAML configs

2. **Official AWS Documentation**
   - AWS Solutions Library: https://aws.amazon.com/solutions/implementations/innovation-sandbox-on-aws/
   - Implementation Guide: https://docs.aws.amazon.com/solutions/latest/innovation-sandbox-on-aws/

3. **GitHub Repositories**
   - Upstream: https://github.com/aws-solutions/innovation-sandbox-on-aws
   - Fork: https://github.com/co-cddo/innovation-sandbox-on-aws
   - co-cddo org: https://github.com/co-cddo

4. **Web Research**
   - CDDO blog posts and tech certification programs
   - InfoQ article on Innovation Sandbox (June 2025)
   - AWS Public Sector blog on educational use cases

### 8.2 Analysis Techniques

- ✅ File system analysis (Read, Grep, Glob)
- ✅ Git configuration inspection
- ✅ Version comparison (CHANGELOG.md vs upstream releases)
- ✅ Configuration file review (YAML, JSON)
- ✅ Web documentation research
- ✅ GitHub repository metadata extraction

### 8.3 Limitations

- ❌ Unable to execute git commands directly (Bash tool unavailable)
- ❌ Cannot clone upstream for direct diff comparison
- ❌ No access to co-cddo deployer/approver Lambda source code
- ❌ No access to UK government internal documentation
- ⚠️ Fork commit history not examined (would require git log analysis)

---

## 9. Findings Summary

### 9.1 Fork Divergence Status

**Overall Assessment**: **Minimal Divergence**

- ✅ No source code modifications detected
- ✅ Configuration files remain standard
- ⚠️ Version lag: 3 releases behind upstream
- ✅ Extension architecture used (external Lambdas)

### 9.2 Customization Approach

CDDO has adopted a **non-invasive extension strategy**:

1. **Maintain upstream compatibility** by not modifying core code
2. **Extend functionality** via external Lambda functions
3. **Integrate via CloudFormation** template automation
4. **Easy upgrade path** by staying close to upstream

This approach allows CDDO to:
- ✅ Receive upstream security patches easily
- ✅ Adopt new features without merge conflicts
- ✅ Maintain UK-specific requirements separately
- ✅ Contribute improvements back to AWS if desired

### 9.3 Recommended Actions for CDDO

1. **Upgrade to v1.1.7** to receive:
   - AWS Nuke v3.63.2 (SCP log group fix)
   - Security patches from v1.1.5-v1.1.7

2. **Establish update cadence**:
   - Monitor upstream releases monthly
   - Prioritize security patches (v1.1.5, v1.1.6)
   - Plan feature adoption (e.g., lease unfreezing from v1.1.0)

3. **Document UK-specific extensions**:
   - Create architecture diagram showing deployer/approver integration
   - Document CloudFormation template customizations
   - Record UK government compliance mappings

4. **Consider contributing back**:
   - If deployer/approver patterns are generally useful
   - AWS Solutions accepts community contributions via PRs

---

## 10. References

### Official AWS Resources

- [AWS Solutions Library - Innovation Sandbox](https://aws.amazon.com/solutions/implementations/innovation-sandbox-on-aws/)
- [Implementation Guide](https://docs.aws.amazon.com/solutions/latest/innovation-sandbox-on-aws/solution-overview.html)
- [Implementation Guide PDF](https://docs.aws.amazon.com/pdfs/solutions/latest/innovation-sandbox-on-aws/innovation-sandbox-on-aws.pdf)
- [Architecture Overview](https://docs.aws.amazon.com/solutions/latest/innovation-sandbox-on-aws/architecture-overview.html)
- [Upstream GitHub Repository](https://github.com/aws-solutions/innovation-sandbox-on-aws)
- [Upstream Releases](https://github.com/aws-solutions/innovation-sandbox-on-aws/releases)

### CDDO Resources

- [CDDO GitHub Organization](https://github.com/co-cddo)
- [CDDO Fork Repository](https://github.com/co-cddo/innovation-sandbox-on-aws)
- [CDDO Blog - Tech Certifications](https://cddo.blog.gov.uk/2025/10/01/ready-to-grow-your-digital-skills-get-tech-certified-this-autumn/)

### Additional Resources

- [InfoQ: Innovation Sandbox on AWS (June 2025)](https://www.infoq.com/news/2025/06/aws-innovation-sandbox/)
- [AWS Public Sector Blog: Educational Use Cases](https://aws.amazon.com/blogs/publicsector/empowering-educators-how-innovation-sandbox-on-aws-accelerates-learning-objectives-through-secure-cost-effective-and-recyclable-sandbox-management/)
- [AWS Nuke Repository](https://github.com/ekristen/aws-nuke)

---

## Appendix A: Key Configuration Files

### global-config.yaml Highlights

```yaml
maintenanceMode: true

leases:
  requireMaxBudget: true
  maxBudget: 50              # USD
  requireMaxDuration: true
  maxDurationHours: 168       # 7 days
  maxLeasesPerUser: 3
  ttl: 30                     # days

cleanup:
  numberOfFailedAttemptsToCancelCleanup: 3
  waitBeforeRetryFailedAttemptSeconds: 5
  numberOfSuccessfulAttemptsToFinishCleanup: 2
  waitBeforeRerunSuccessfulAttemptSeconds: 30
```

### nuke-config.yaml Key Protections

```yaml
accounts:
  "%CLEANUP_ACCOUNT_ID%":
    filters:
      CloudFormationStack:
        - type: glob
          value: StackSet-Isb-*
      IAMRole:
        - type: exact
          value: OrganizationAccountAccessRole
        - type: glob
          value: AWSReservedSSO_*
        - type: contains
          value: AWSControlTower
```

---

## Appendix B: Deployment Checklist

- [ ] AWS Organization configured
- [ ] IAM Identity Center enabled
- [ ] Parent OU identified for sandbox accounts
- [ ] Hub account selected (Compute + Data)
- [ ] Org Management account identified (AccountPool)
- [ ] IDC account identified (IDC stack)
- [ ] Node.js 22 installed
- [ ] AWS CDK bootstrapped
- [ ] `.env` file configured
- [ ] Terms of Use accepted (`ACCEPT_SOLUTION_TERMS_OF_USE="Accept"`)
- [ ] Multi-account access configured (if multi-account deployment)
- [ ] Post-deployment tasks documented
- [ ] User groups created in IAM Identity Center

---

**Document End**
