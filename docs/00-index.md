# Complete Documentation Index

**Last Updated:** 2026-02-03
**Total Documents:** 30+
**Organization:** Phased architecture archaeology project

---

## Navigation

**📚 [README](./README.md)** - Start here for overview and quick links

---

## Phase 1: Repository Discovery

### 00-repo-inventory.md
**Comprehensive inventory of all 12 repositories in the NDX ecosystem**

- Repository metadata (IaC types, workflows, documentation)
- Technology stack analysis
- Cross-repository architecture patterns
- Key statistics (275+ CloudFormation templates, 12+ CDK stacks, etc.)
- Deprecation notices (ndx-try-aws-isb placeholder, billing-seperator temporary)

**Audience:** All teams
**Read Time:** 15 minutes

---

### 01-upstream-analysis.md
**Analysis of AWS Solutions upstream fork and CDDO customizations**

- Upstream ISB version: v1.1.7 (latest)
- CDDO fork version: v1.1.4 (3 versions behind)
- Version history and changelog
- Fork divergence analysis (no code changes, extension architecture)
- UK government specific adaptations
- Upgrade recommendations

**Audience:** Platform architects, DevOps
**Read Time:** 10 minutes

---

## Phase 2: AWS Organization Structure

### 02-aws-organization.md
**Complete AWS Organization hierarchy and account inventory**

- Organization ID: o-4g8nrlnr9s
- 16 accounts across Security, Infrastructure, Workloads, InnovationSandbox OUs
- Account lifecycle state machine (Entry → Available → Active → CleanUp → Quarantine)
- Email naming convention (ndx-try-provider+...)
- Current pool status: 5 available, 4 quarantined, 0 active

**Audience:** All teams
**Read Time:** 10 minutes
**Key Diagrams:** Organization hierarchy, account lifecycle state machine

---

### 03-hub-account-resources.md
**Inventory of all resources in Hub Account (568672915267)**

- CloudFormation stacks (ISB, deployer, LZA, Control Tower)
- Lambda functions (19+ functions documented)
- DynamoDB tables (LeaseTable, SandboxAccountTable, etc.)
- EventBridge rules and event patterns
- S3 buckets (frontend, costs, artifacts, etc.)
- Multi-region resources (eu-west-2 primary, us-east-1 secondary)

**Audience:** Operations, DevOps
**Read Time:** 8 minutes

---

### 04-cross-account-trust.md
**IAM trust relationships and cross-account access patterns**

- GitHub OIDC provider configuration
- GitHub Actions IAM roles (5 roles for deployer, approver, NDX)
- ISB operational roles (IntermediateRole, deployer role)
- Billing separator roles
- Cross-account access diagram
- Missing OIDC roles for 7 repositories

**Audience:** Security, DevOps
**Read Time:** 7 minutes
**Key Diagrams:** Repository to role mapping, cross-account access flows

---

### 05-service-control-policies.md
**Complete SCP inventory and organizational unit attachments**

- 19 total SCPs (Control Tower, LZA, Terraform, ISB Core)
- OU-level SCP mappings
- Policy inheritance model
- Dual SCP management (LZA + Terraform) conflict analysis
- Cost avoidance policies (compute, services)
- Security policies (restrictions, protection, write protection)

**Audience:** Security, compliance
**Read Time:** 12 minutes
**Key Diagrams:** SCP inheritance tree, OU attachment mapping

---

## Phase 3: ISB Core Architecture

### 10-isb-core-architecture.md
**Deep dive into Innovation Sandbox Core platform**

- System architecture (API, compute, data, events layers)
- 4 CDK stacks (AccountPool, IDC, Data, Compute)
- 19 Lambda functions catalog
- DynamoDB schemas (LeaseTable, LeaseTemplateTable, SandboxAccountTable)
- React frontend architecture
- Event-driven integration patterns
- Complete AWS Nuke cleanup workflow

**Audience:** Development team, architects
**Read Time:** 30 minutes
**Key Diagrams:** System context, CDK stack architecture, event flow, state machine

---

### 11-lease-lifecycle.md
**Complete lease lifecycle state machine and data flows**

- Lease states (PendingApproval, Active, Frozen, Expired, BudgetExceeded)
- Lease request flow (API → DynamoDB → EventBridge)
- Approval flow (auto-approve vs manual review)
- Account provisioning (OU management, IDC permission sets)
- Lease monitoring (budget/duration threshold checks)
- Cleanup workflow (Step Functions → AWS Nuke → quarantine logic)
- EventBridge event catalog (LeaseRequested, LeaseApproved, LeaseTerminated, etc.)
- DynamoDB interaction patterns

**Audience:** Development team
**Read Time:** 35 minutes
**Key Diagrams:** Lease state diagram, sequence diagrams for all major flows

---

## Phase 4: ISB Satellite Components

### 20-approver-system.md
**AI-powered lease approval scoring engine**

- 19-rule scoring engine (user history, org policy, financial, risk)
- 9-state Step Functions workflow
- Amazon Bedrock integration (Claude 3 Sonnet)
- Scoring categories and weights
- Auto-approve threshold (80+), manual review (50-79), auto-reject (<50)
- AI assessment prompts and responses
- DynamoDB ApprovalHistory schema
- Manual review workflow (admin dashboard)

**Audience:** Development team, operations
**Read Time:** 25 minutes
**Key Diagrams:** Step Functions state machine, scoring flow, AI integration

---

### 21-billing-separator.md
**72-hour quarantine for billing data propagation (TEMPORARY SOLUTION)**

- SQS delay queue architecture (259,200s visibility timeout)
- Cost data availability verification
- Release logic (check at 72h, retry at 96h, force release alert)
- QuarantineStatus DynamoDB tracking
- Decommissioning plan (when Cost Explorer provides real-time data)
- Integration with Costs satellite

**Audience:** Operations, platform architects
**Read Time:** 15 minutes
**Key Diagrams:** Quarantine state machine, SQS message flow, decision matrix

---

### 22-cost-tracking.md
**AWS Cost Explorer integration for lease cost reporting**

- EventBridge Scheduler (24-hour delay after lease termination)
- Cost Collector Lambda (GetCostAndUsage API)
- Cost data analysis (by service, region, daily breakdown)
- CostReports DynamoDB schema
- Budget compliance checking
- QuickSight dashboards (executive summary, OU breakdown, overages)
- Chargeback report generation (monthly CSV to S3)

**Audience:** Finance, operations
**Read Time:** 20 minutes
**Key Diagrams:** Cost collection flow, data transformations, dashboard mockups

---

### 23-deployer.md (referenced but not yet created in this phase)
**CloudFormation/CDK auto-deployment to sandbox accounts**

- EventBridge trigger on LeaseApproved
- GitHub API integration (template fetching, CDK detection)
- Sparse git clone for CDK projects
- CloudFormation stack deployment (cross-account)
- Parameter enrichment from lease data
- Deployment status tracking

**Audience:** Development team
**Read Time:** TBD

---

## Phase 5: NDX Websites

### 30-ndx-website.md (referenced but not yet created)
**NDX informational platform architecture**

- Eleventy static site generation
- GOV.UK Frontend design system
- S3 + CloudFront hosting
- Scenario catalog integration
- Link to ISB signup flow

**Audience:** Content team, development
**Read Time:** TBD

---

### 31-scenario-platform.md (referenced but not yet created)
**Try AWS scenarios (275+ CloudFormation templates)**

- 7 pre-built scenarios (Council Chatbot, Planning AI, etc.)
- CloudFormation template organization
- Evidence pack generation (screenshot automation)
- Integration with Deployer

**Audience:** Content team, development
**Read Time:** TBD

---

## Phase 6: LZA & Terraform

### 40-lza-configuration.md (referenced but not yet created)
**AWS Landing Zone Accelerator YAML configuration**

- Account definitions
- OU structure
- Network configuration
- Security baselines
- IAM policies and roles

**Audience:** Infrastructure team, security
**Read Time:** TBD

---

### 41-terraform-scp.md (referenced but not yet created)
**Terraform-managed Service Control Policies**

- 5-layer cost defense architecture
- SCP consolidation analysis
- Conflict with LZA SCPs
- Deployment automation

**Audience:** Infrastructure team, security
**Read Time:** TBD

---

### 42-terraform-org.md (referenced but not yet created)
**Terraform organization management**

- S3 backend configuration
- Billing visibility management
- Organization-level resources

**Audience:** Infrastructure team
**Read Time:** TBD

---

## Phase 7: CI/CD Pipelines

### 50-github-actions.md (referenced but not yet created)
**GitHub Actions workflows across all repositories**

- Workflow inventory (deploy, ci, pr-check, test)
- Deployment pipelines
- Testing automation
- Missing workflows analysis

**Audience:** DevOps, development
**Read Time:** TBD

---

### 51-oidc-configuration.md (referenced but not yet created)
**GitHub OIDC provider and IAM roles**

- OIDC provider setup
- Role trust policies
- Repository scoping
- Security best practices

**Audience:** Security, DevOps
**Read Time:** TBD

---

### 52-deployment-flows.md (referenced but not yet created)
**End-to-end deployment flows for each component**

- ISB Core deployment order
- Satellite deployment
- Infrastructure deployment
- Rollback procedures

**Audience:** DevOps, operations
**Read Time:** TBD

---

## Phase 8: Security & Compliance

### 60-iam-policies.md (referenced but not yet created)
**IAM policy inventory and analysis**

- Lambda execution roles
- Cross-account access policies
- Least privilege validation
- Policy conflicts

**Audience:** Security, compliance
**Read Time:** TBD

---

### 61-data-protection.md (referenced but not yet created)
**Data encryption, PII handling, GDPR compliance**

- Encryption at rest (DynamoDB, S3)
- Encryption in transit (TLS)
- PII data flows
- Data retention policies

**Audience:** Security, compliance, legal
**Read Time:** TBD

---

### 62-compliance-mappings.md (referenced but not yet created)
**UK government compliance requirements**

- OFFICIAL data classification
- Cyber Essentials Plus
- GDPR compliance
- Audit logging

**Audience:** Compliance, legal
**Read Time:** TBD

---

## Phase 9: Data Flows & Integration

### 70-data-flows.md
**Comprehensive data flow documentation**

- Flow 1: User signup → ISB lease (Mermaid sequence diagram)
- Flow 2: Lease approval → deployment (19-rule scoring, Deployer)
- Flow 3: Cost data collection (Cost Explorer → DynamoDB)
- Flow 4: Billing separation & cleanup (72h quarantine, AWS Nuke)
- EventBridge event catalog
- DynamoDB transaction patterns
- Performance characteristics

**Audience:** All technical teams
**Read Time:** 25 minutes
**Key Diagrams:** 4 major sequence diagrams, event catalog, consistency patterns

---

### 71-external-integrations.md
**All external system integrations and API usage**

- ukps-domains (GitHub domain whitelist, manual sync to S3)
- AWS Cost Explorer API (rate limiting, batching, cross-account access)
- AWS Identity Center (SSO auth, permission set assignment)
- Amazon Bedrock AI (Claude 3 Sonnet, justification scoring)
- GitHub API (template fetching, CDK detection, rate limits)
- Authentication methods and security
- Failure modes and mitigations

**Audience:** Development, security
**Read Time:** 20 minutes
**Key Diagrams:** Integration dependency graph, API usage patterns

---

### 72-repo-dependencies.md
**Repository dependency analysis and package.json review**

- Dependency graph (12 repositories)
- Deployment order dependencies (5 phases)
- NPM package dependencies (AWS SDK versions, CDK versions)
- Shared code and libraries (Lambda layers, internal packages)
- EventBridge event schema contracts
- DynamoDB table read/write matrix
- Dependency issues (version mismatches, schema versioning)

**Audience:** Development, architects
**Read Time:** 15 minutes
**Key Diagrams:** Dependency graph, deployment order, cross-service dependencies

---

## Phase 10: Master Diagrams & Index

### 80-c4-architecture.md
**C4 model architecture diagrams (Context, Container, Component)**

- Level 1: System Context (NDX + ISB + external systems)
- Level 2: ISB Container Diagram (Hub account internals, satellites)
- Level 2: NDX Container Diagram (website, content platform)
- Architectural patterns (event-driven, multi-account, serverless)
- Technology stack summary
- Deployment architecture
- Security boundaries

**Audience:** All teams, especially architects and leadership
**Read Time:** 20 minutes
**Key Diagrams:** 3 C4 diagrams, trust zones, critical path

---

### 81-aws-architecture.md
**Complete AWS infrastructure architecture**

- Full organization diagram (16 accounts, all OUs)
- Hub account internal architecture
- Cross-account IAM trust relationships
- Network architecture (VPC, subnets, NAT gateways)
- SCP attachments visualization
- AWS service usage map (20+ services)
- Data residency (eu-west-2 primary, us-east-1 secondary)
- Disaster recovery strategy
- Cost breakdown by service

**Audience:** All technical teams, leadership
**Read Time:** 18 minutes
**Key Diagrams:** Organization hierarchy, Hub internals, SCP tree, service map

---

### 82-process-flows.md
**End-to-end user journeys and operational processes**

- Flow 1: Complete user journey (discovery → production)
- Flow 2: Complete lease lifecycle (request → cleanup)
- Flow 3: Complete deployment pipeline (CloudFormation/CDK)
- Flow 4: Complete cost tracking cycle (termination → chargeback)
- Flow 5: Approver scoring process (19 rules in detail)
- Flow 6: Account cleanup process (AWS Nuke execution)
- Daily/weekly/monthly operational checklists

**Audience:** All teams
**Read Time:** 25 minutes
**Key Diagrams:** Journey map, state diagram, 6 sequence diagrams, process flowcharts

---

### README.md
**Executive summary and navigation guide**

- Quick start guides for different team roles
- Documentation structure overview
- Glossary of terms and acronyms
- Diagram legend and conventions
- Recommended reading paths (5 audience-specific paths)
- System statistics and key metrics

**Audience:** Everyone
**Read Time:** 10 minutes

---

### 00-index.md (this document)
**Complete table of contents with brief descriptions**

- All 30+ documents with summaries
- Audience tags
- Estimated read times
- Key diagram callouts

**Audience:** Everyone
**Read Time:** 5 minutes

---

## Phase 11: Issues & Appendices

### 90-issues-discovered.md
**Known issues, inconsistencies, and improvement recommendations**

- Issue severity ratings (Critical, High, Medium, Low)
- Issues by phase (9 total: 4 medium, 5 low)
- Recommendations summary (immediate, short-term, long-term actions)
- Detailed issue descriptions with context

**Audience:** All teams, especially operations and architects
**Read Time:** 10 minutes

---

## Document Statistics

| Phase | Documents | Status | Diagrams |
|-------|-----------|--------|----------|
| Phase 1: Repository Discovery | 2 | ✅ Complete | 1 |
| Phase 2: AWS Organization | 4 | ✅ Complete | 5 |
| Phase 3: ISB Core | 2 | ✅ Complete | 8 |
| Phase 4: ISB Satellites | 4 | 🟡 3/4 Complete | 6 |
| Phase 5: NDX Websites | 2 | ⏳ Planned | TBD |
| Phase 6: LZA & Terraform | 3 | ⏳ Planned | TBD |
| Phase 7: CI/CD Pipelines | 3 | ⏳ Planned | TBD |
| Phase 8: Security & Compliance | 3 | ⏳ Planned | TBD |
| Phase 9: Data Flows | 3 | ✅ Complete | 12 |
| Phase 10: Master Diagrams | 5 | ✅ Complete | 15 |
| Phase 11: Issues | 1 | ✅ Complete | 0 |
| **Total** | **32** | **18 Complete** | **47+** |

---

## Quick Links by Topic

### Architecture & Design
- [C4 Architecture Diagrams](./80-c4-architecture.md)
- [AWS Infrastructure](./81-aws-architecture.md)
- [ISB Core Architecture](./10-isb-core-architecture.md)
- [Process Flows](./82-process-flows.md)

### Data & Integration
- [Data Flows](./70-data-flows.md)
- [External Integrations](./71-external-integrations.md)
- [Repository Dependencies](./72-repo-dependencies.md)
- [Lease Lifecycle](./11-lease-lifecycle.md)

### Components
- [Approver System](./20-approver-system.md)
- [Billing Separator](./21-billing-separator.md)
- [Cost Tracking](./22-cost-tracking.md)
- [Hub Account Resources](./03-hub-account-resources.md)

### Security & Governance
- [Service Control Policies](./05-service-control-policies.md)
- [Cross-Account Trust](./04-cross-account-trust.md)
- [AWS Organization](./02-aws-organization.md)

### Operations
- [Process Flows](./82-process-flows.md) (operational checklists)
- [Issues Discovered](./90-issues-discovered.md)
- [Hub Account Resources](./03-hub-account-resources.md)

### Development
- [Repository Inventory](./00-repo-inventory.md)
- [Repository Dependencies](./72-repo-dependencies.md)
- [Data Flows](./70-data-flows.md)
- [External Integrations](./71-external-integrations.md)

---

## Search Guide

### Find by Technology
- **Lambda:** [10](./10-isb-core-architecture.md), [20](./20-approver-system.md), [21](./21-billing-separator.md), [22](./22-cost-tracking.md)
- **DynamoDB:** [10](./10-isb-core-architecture.md), [11](./11-lease-lifecycle.md), [70](./70-data-flows.md)
- **EventBridge:** [10](./10-isb-core-architecture.md), [11](./11-lease-lifecycle.md), [70](./70-data-flows.md)
- **Step Functions:** [10](./10-isb-core-architecture.md), [20](./20-approver-system.md), [82](./82-process-flows.md)
- **CDK:** [00](./00-repo-inventory.md), [72](./72-repo-dependencies.md)

### Find by Process
- **Lease Creation:** [11](./11-lease-lifecycle.md), [70](./70-data-flows.md)
- **Approval:** [20](./20-approver-system.md), [82](./82-process-flows.md)
- **Deployment:** [70](./70-data-flows.md), [82](./82-process-flows.md)
- **Cost Collection:** [22](./22-cost-tracking.md), [70](./70-data-flows.md), [82](./82-process-flows.md)
- **Cleanup:** [10](./10-isb-core-architecture.md), [11](./11-lease-lifecycle.md), [82](./82-process-flows.md)

### Find by Audience
- **Leadership:** [README](./README.md), [80](./80-c4-architecture.md), [81](./81-aws-architecture.md)
- **Operations:** [03](./03-hub-account-resources.md), [82](./82-process-flows.md), [90](./90-issues-discovered.md)
- **Development:** [00](./00-repo-inventory.md), [72](./72-repo-dependencies.md), [10](./10-isb-core-architecture.md), [70](./70-data-flows.md)
- **Security:** [04](./04-cross-account-trust.md), [05](./05-service-control-policies.md), [71](./71-external-integrations.md)
- **Finance:** [22](./22-cost-tracking.md), [82](./82-process-flows.md)

---

**Last Updated:** 2026-02-03
**Maintainer:** Architecture Archaeology Project Team
**Status:** Phase 1-4 and 9-10 Complete, Phases 5-8 Planned
