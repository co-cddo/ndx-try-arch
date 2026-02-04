# C4 Architecture Diagrams

**Document Version:** 1.0
**Date:** 2026-02-03
**C4 Model:** System Context, Container, Component views

---

## Executive Summary

This document presents the NDX:Try AWS architecture using the C4 model (Context, Containers, Components, Code). It provides hierarchical views from the system boundary down to key implementation details.

**C4 Model Levels:**
1. **System Context** - External systems and users
2. **Container** - Applications and data stores (ISB and NDX)
3. **Component** - Internal modules (future)

---

## Level 1: System Context Diagram

### NDX + ISB Ecosystem

```mermaid
C4Context
    title System Context - NDX:Try AWS Ecosystem

    Person(user, "UK Public Sector User", "Local government employee seeking AWS sandbox")
    Person(admin, "ISB Administrator", "Manages sandbox platform")
    Person(finance, "Finance Team", "Tracks costs and chargebacks")

    System_Boundary(ndx_boundary, "NDX:Try AWS") {
        System(ndx, "NDX Website", "Informational platform, scenario catalog, signup portal")
        System(isb, "Innovation Sandbox (ISB)", "Multi-account sandbox provisioning and lifecycle management")
    }

    System_Ext(ukps, "ukps-domains", "UK public sector domain whitelist (GitHub)")
    System_Ext(github, "GitHub", "CloudFormation template hosting")
    System_Ext(aws_org, "AWS Organizations", "Account management")
    System_Ext(cost_explorer, "AWS Cost Explorer", "Spend tracking")
    System_Ext(bedrock, "Amazon Bedrock", "AI risk assessment")
    System_Ext(idc, "AWS Identity Center", "SSO authentication")

    Rel(user, ndx, "Browses scenarios", "HTTPS")
    Rel(user, isb, "Requests sandbox", "HTTPS/JWT")
    Rel(admin, isb, "Manages platform", "HTTPS/JWT")
    Rel(finance, isb, "Downloads cost reports", "S3/CSV")

    Rel(isb, ukps, "Validates domains", "HTTPS/JSON")
    Rel(isb, github, "Fetches templates", "HTTPS/API")
    Rel(isb, aws_org, "Provisions accounts", "AWS API")
    Rel(isb, cost_explorer, "Queries costs", "AWS API")
    Rel(isb, bedrock, "AI scoring", "AWS API")
    Rel(isb, idc, "SSO auth", "SAML 2.0")

    Rel(ndx, isb, "Links to signup", "HTTPS")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

---

## Level 2: Container Diagram - ISB Platform

### ISB Core + Satellites

```mermaid
C4Container
    title Container Diagram - Innovation Sandbox Platform

    Person(user, "User", "Sandbox requester")
    Person(admin, "Admin", "Platform manager")

    Container_Boundary(hub_account, "Hub Account (568672915267)") {
        Container(frontend, "ISB Frontend", "React SPA", "User interface for lease management")
        Container(api_gateway, "API Gateway", "REST API", "HTTP API with JWT auth")

        ContainerDb(lease_db, "LeaseTable", "DynamoDB", "Active and pending leases")
        ContainerDb(account_db, "SandboxAccountTable", "DynamoDB", "Pool account inventory")
        ContainerDb(template_db, "LeaseTemplateTable", "DynamoDB", "Reusable configurations")

        Container(lease_lambda, "Leases Lambda", "Node.js 20", "CRUD operations on leases")
        Container(account_lambda, "Accounts Lambda", "Node.js 20", "Account management")
        Container(lifecycle_lambda, "Lifecycle Manager", "Node.js 20", "OU management, provisioning")
        Container(monitoring_lambda, "Lease Monitoring", "Python 3.12", "Budget/duration checks")

        Container(cleanup_sfn, "Cleanup State Machine", "Step Functions", "AWS Nuke orchestration")
        Container(cleanup_codebuild, "Account Cleaner", "CodeBuild", "Executes AWS Nuke")

        Container(event_bus, "ISBEventBus", "EventBridge", "Event-driven integration")

        Container(approver, "Approver", "Lambda + SFN", "19-rule scoring engine + AI")
        Container(deployer, "Deployer", "Lambda", "CloudFormation/CDK deployment")
        Container(costs, "Cost Tracker", "Lambda + Scheduler", "Cost Explorer integration")
        Container(billing_sep, "Billing Separator", "Lambda + SQS", "72h quarantine")

        ContainerDb(cost_db, "CostReports", "DynamoDB", "Historical spend")
        ContainerDb(approval_db, "ApprovalHistory", "DynamoDB", "Scoring audit trail")
    }

    Container_Boundary(pool_accounts, "Pool Accounts (x9)") {
        Container(pool_account, "Sandbox Account", "AWS Account", "User workload environment")
    }

    System_Ext(bedrock_ext, "Amazon Bedrock", "AI service")
    System_Ext(ce_ext, "Cost Explorer", "AWS billing API")
    System_Ext(idc_ext, "Identity Center", "SSO provider")

    Rel(user, frontend, "Uses", "HTTPS")
    Rel(frontend, api_gateway, "API calls", "HTTPS/JWT")
    Rel(api_gateway, lease_lambda, "Routes requests", "Invoke")

    Rel(lease_lambda, lease_db, "Read/Write", "AWS SDK")
    Rel(lease_lambda, event_bus, "Publish events", "PutEvents")
    Rel(account_lambda, account_db, "Read/Write", "AWS SDK")
    Rel(lifecycle_lambda, account_db, "Update status", "AWS SDK")

    Rel(event_bus, approver, "LeaseRequested", "Event pattern")
    Rel(event_bus, deployer, "LeaseApproved", "Event pattern")
    Rel(event_bus, costs, "LeaseTerminated", "Event pattern")
    Rel(event_bus, billing_sep, "LeaseTerminated", "Event pattern")

    Rel(approver, bedrock_ext, "AI assessment", "InvokeModel")
    Rel(approver, approval_db, "Write scores", "PutItem")
    Rel(approver, event_bus, "ApprovalComplete", "PutEvents")

    Rel(deployer, pool_account, "Deploy CFN", "AssumeRole")
    Rel(costs, ce_ext, "Query costs", "GetCostAndUsage")
    Rel(costs, cost_db, "Write data", "PutItem")

    Rel(billing_sep, cost_db, "Check availability", "GetItem")
    Rel(billing_sep, account_db, "Release quarantine", "UpdateItem")

    Rel(cleanup_sfn, cleanup_codebuild, "Trigger", "StartBuild")
    Rel(cleanup_codebuild, pool_account, "AWS Nuke", "AssumeRole")

    Rel(admin, frontend, "Manages", "HTTPS")
    Rel(lifecycle_lambda, idc_ext, "Permission sets", "CreateAccountAssignment")

    UpdateLayoutConfig($c4ShapeInRow="4", $c4BoundaryInRow="2")
```

---

## Level 2: Container Diagram - NDX Website

### Content Platform

```mermaid
C4Container
    title Container Diagram - NDX Website Platform

    Person(visitor, "Visitor", "Public sector employee")

    Container_Boundary(ndx_infra, "NDX Infrastructure") {
        Container(cloudfront, "CloudFront", "CDN", "Global content delivery")
        Container(s3_website, "Website Bucket", "S3", "Static HTML/CSS/JS")
        Container(s3_screenshots, "Screenshots Bucket", "S3 (us-east-1)", "Scenario evidence packs")

        Container(eleventy, "Eleventy Build", "Node.js (CI)", "Static site generation")
        Container(screenshot_lambda, "Screenshot Generator", "Lambda + Playwright", "Automated evidence capture")
    }

    Container_Boundary(try_content, "Try AWS Content") {
        Container(scenarios_repo, "ndx_try_aws_scenarios", "GitHub", "275+ CloudFormation templates")
        Container(catalogue, "Scenario Catalogue", "Static pages", "7 pre-built scenarios")
    }

    System_Ext(isb_link, "ISB Platform", "Signup target")
    System_Ext(github_actions, "GitHub Actions", "CI/CD")

    Rel(visitor, cloudfront, "Browses", "HTTPS")
    Rel(cloudfront, s3_website, "Serves", "S3 GetObject")
    Rel(cloudfront, s3_screenshots, "Serves evidence packs", "S3 GetObject")

    Rel(eleventy, scenarios_repo, "Reads templates", "GitHub API")
    Rel(eleventy, catalogue, "Generates pages", "Markdown → HTML")
    Rel(eleventy, s3_website, "Uploads", "S3 PutObject")

    Rel(screenshot_lambda, scenarios_repo, "Deploys scenarios", "CloudFormation")
    Rel(screenshot_lambda, s3_screenshots, "Stores screenshots", "S3 PutObject")

    Rel(catalogue, isb_link, "Signup button", "HTTPS redirect")

    Rel(github_actions, eleventy, "Triggers build", "Workflow dispatch")
    Rel(github_actions, screenshot_lambda, "Invokes", "Lambda invoke")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

---

## Key Architectural Patterns

### 1. Event-Driven Satellite Architecture

**Pattern:**
- ISB Core publishes lifecycle events to EventBridge
- Satellites subscribe to relevant event patterns
- Loose coupling enables independent deployment

**Benefits:**
- Satellites can be added/removed without ISB Core changes
- Fault isolation (satellite failure doesn't break core)
- Scalability (EventBridge handles fan-out)

**Drawbacks:**
- Eventual consistency
- Distributed tracing complexity
- Event schema versioning required

---

### 2. Multi-Account Isolation

**Pattern:**
- Hub Account (568672915267): Control plane
- Pool Accounts (x9): Workload isolation
- Management Account (955063685555): Organization root

**Benefits:**
- Security isolation (blast radius limited)
- Billing separation
- Policy enforcement via SCPs

**Drawbacks:**
- Cross-account networking complexity
- IAM role chaining overhead
- Cost Explorer queries span accounts

---

### 3. Serverless-First

**Pattern:**
- Lambda for all compute (except AWS Nuke)
- DynamoDB for data persistence
- S3 for object storage
- No EC2 instances

**Benefits:**
- Auto-scaling
- Pay-per-use cost model
- Zero server management

**Drawbacks:**
- Cold start latency
- 15-minute Lambda timeout (State machines for long tasks)
- Vendor lock-in

---

### 4. API Gateway + Lambda

**Pattern:**
- REST API Gateway fronts all HTTP endpoints
- JWT authorization via Cognito
- Lambda functions per resource type

**Benefits:**
- Standard HTTP interface
- Built-in throttling and caching
- WAF integration

**Drawbacks:**
- API Gateway cost at scale
- 29-second timeout
- Limited WebSocket support

---

## Technology Stack Summary

### ISB Core

| Layer | Technology | Version |
|-------|------------|---------|
| Frontend | React + Vite | React 18 |
| API | API Gateway REST | v1 |
| Compute | Lambda (Node.js) | Node 20.x |
| Orchestration | Step Functions | - |
| Data | DynamoDB | - |
| Events | EventBridge | - |
| Auth | Cognito + Identity Center | - |
| IaC | AWS CDK | v2.170.0 |

### ISB Satellites

| Component | Technology | Runtime |
|-----------|------------|---------|
| Approver | Lambda + Step Functions | Node 20.x |
| Deployer | Lambda | Node 22.x |
| Costs | Lambda + EventBridge Scheduler | TypeScript |
| Billing Separator | Lambda + SQS | Python 3.12 |

### NDX Website

| Component | Technology | Version |
|-----------|------------|---------|
| Static Site Generator | Eleventy | v3.1.2 |
| Design System | GOV.UK Frontend | v8.3.0 |
| Hosting | S3 + CloudFront | - |
| Package Manager | Yarn | v4.5.0 |

---

## Deployment Architecture

### ISB Deployment Model

```
Organization Root (955063685555)
  └── Workloads OU
        └── Prod OU
              └── InnovationSandboxHub (568672915267)
                    ├── AccountPool Stack (DynamoDB, EventBridge)
                    ├── IDC Stack (Identity Center integration)
                    ├── Data Stack (API Gateway, Lambdas)
                    ├── Compute Stack (Step Functions, monitoring)
                    ├── Approver CDK Stack
                    ├── Costs CDK Stack
                    ├── Deployer CDK Stack
                    └── Billing Separator CDK Stack
```

### Pool Account Distribution

```
InnovationSandbox OU
  └── ndx_InnovationSandboxAccountPool OU
        ├── Available OU (pool-003, 004, 005, 006, 009)
        ├── Active OU (none currently)
        ├── CleanUp OU (none currently)
        ├── Frozen OU (none currently)
        └── Quarantine OU (pool-001, 002, 007, 008)
```

---

## Security Boundaries

### Trust Zones

```mermaid
graph TB
    subgraph internet["Internet Zone"]
        user_browser["User Browser"]
    end

    subgraph dmz["DMZ"]
        cloudfront["CloudFront CDN"]
        api_gateway["API Gateway + WAF"]
    end

    subgraph hub["Hub Account (Trusted Zone)"]
        lambdas["Lambda Functions"]
        ddb["DynamoDB"]
        eventbridge["EventBridge"]
    end

    subgraph pool["Pool Accounts (Sandboxed Zone)"]
        user_resources["User Workloads"]
    end

    user_browser -->|HTTPS| cloudfront
    user_browser -->|HTTPS + JWT| api_gateway
    api_gateway -->|Invoke| lambdas
    lambdas -->|Read/Write| ddb
    lambdas -->|Publish| eventbridge
    lambdas -->|AssumeRole| user_resources

    style internet fill:#f99,stroke:#333
    style dmz fill:#ff9,stroke:#333
    style hub fill:#9f9,stroke:#333
    style pool fill:#99f,stroke:#333
```

---

## Data Flow Highlights

### Critical Path: Lease Request to Active Sandbox

1. **User** → Frontend (React)
2. **Frontend** → API Gateway (POST /leases)
3. **API Gateway** → Leases Lambda
4. **Leases Lambda** → DynamoDB (create lease)
5. **Leases Lambda** → EventBridge (publish LeaseRequested)
6. **EventBridge** → Approver (trigger scoring)
7. **Approver** → Bedrock (AI assessment)
8. **Approver** → EventBridge (publish LeaseApproved)
9. **EventBridge** → Lifecycle Manager (provision access)
10. **Lifecycle Manager** → Identity Center (grant permissions)
11. **Lifecycle Manager** → Organizations (move OU)
12. **EventBridge** → Deployer (deploy template)
13. **Deployer** → CloudFormation (in pool account)
14. **User** receives access URL

**Total Time:** ~30-90 seconds (auto-approve) or 1-24 hours (manual review)

---

## References

- [70-data-flows.md](./70-data-flows.md) - Detailed data flow diagrams
- [10-isb-core-architecture.md](./10-isb-core-architecture.md) - ISB internals
- [C4 Model](https://c4model.com/) - Architecture visualization framework

---

**Document Version:** 1.0
**Last Updated:** 2026-02-03
**Status:** Complete - C4 Level 1 & 2 diagrams
