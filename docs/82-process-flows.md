# Process Flows

**Document Version:** 1.0
**Date:** 2026-02-03
**Scope:** End-to-end user journeys and operational processes

---

## Executive Summary

This document presents the complete user and operational journeys through the NDX:Try AWS platform, from initial discovery to production deployment. Each flow is documented with Mermaid diagrams showing the complete path through the system.

---

## Flow 1: Complete User Journey (Discovery → Production)

### End-to-End User Experience

```mermaid
journey
    title UK Public Sector User Journey
    section Discovery
      Browse GOV.UK: 5: User
      Find NDX website: 5: User
      Read about Try AWS: 5: User
      Review scenario catalog: 4: User
    section Signup
      Click "Request Sandbox": 5: User
      Redirected to ISB: 4: User
      Login with SSO: 3: User
      Fill lease request form: 4: User
      Submit request: 5: User
    section Approval (Auto)
      AI scoring (background): 5: System
      Score >= 80 (approved): 5: System
      Receive approval email: 5: User
    section Provisioning
      Account assigned: 5: System
      CloudFormation deployed: 4: System
      Receive access URL: 5: User
    section Usage
      Login to AWS Console: 4: User
      Explore services: 5: User
      Build proof of concept: 5: User
      Monitor budget: 4: User
    section Termination
      Lease expires: 3: User
      Account cleaned (AWS Nuke): 3: System
      Cost report emailed: 4: User
    section Adoption
      Present to leadership: 5: User
      Request production account: 5: User
      Move to production: 5: User
```

---

## Flow 2: Complete Lease Lifecycle

### From Request to Cleanup

```mermaid
stateDiagram-v2
    [*] --> Discovery: User discovers NDX
    Discovery --> SignupIntent: Clicks "Request Sandbox"

    SignupIntent --> LoginISB: Redirect to ISB frontend
    LoginISB --> SelectTemplate: SSO authentication

    SelectTemplate --> FillForm: Choose lease template
    FillForm --> SubmitRequest: Provide justification

    SubmitRequest --> PendingApproval: Create lease record

    PendingApproval --> AIScoring: Approver triggered
    AIScoring --> AutoApprove: Score >= 80
    AIScoring --> ManualReview: 50 <= Score < 80
    AIScoring --> AutoReject: Score < 50

    ManualReview --> AdminReviewUI: Escalate to admin
    AdminReviewUI --> Approved: Admin approves
    AdminReviewUI --> Rejected: Admin rejects

    AutoApprove --> Approved
    Approved --> Provisioning: LeaseApproved event

    Provisioning --> AssignAccount: Find available account
    AssignAccount --> MoveOU: Available → Active
    MoveOU --> GrantAccess: Identity Center permission set
    GrantAccess --> DeployTemplate: Deployer triggered
    DeployTemplate --> Active: CloudFormation complete

    Active --> Monitoring: Hourly budget/duration checks

    Monitoring --> BudgetAlert: Budget threshold breached
    Monitoring --> DurationAlert: Time threshold breached
    Monitoring --> Active: Within limits

    BudgetAlert --> Active: Alert sent, continue
    DurationAlert --> Active: Alert sent, continue

    Active --> FreezeRequest: User requests freeze
    FreezeRequest --> Frozen: Account frozen
    Frozen --> UnfreezeRequest: User unfreezes
    UnfreezeRequest --> Active: Resume monitoring

    Active --> Expired: Duration exceeded
    Active --> BudgetExceeded: Budget exceeded
    Active --> ManualTermination: User terminates
    Frozen --> Expired: Duration exceeded

    Expired --> CostCollection: Schedule cost query (24h)
    BudgetExceeded --> CostCollection
    ManualTermination --> CostCollection

    CostCollection --> BillingQuarantine: SQS delay (72h)
    BillingQuarantine --> CostDataCheck: After 72h

    CostDataCheck --> CostAvailable: Data found in DynamoDB
    CostDataCheck --> ExtendQuarantine: Data missing, retry 24h

    CostAvailable --> ReleaseAccount: Update status to Available
    ExtendQuarantine --> CostDataCheck: After 24h extension

    ReleaseAccount --> Cleanup: Account status = Available
    Cleanup --> AWSNuke: Step Functions → CodeBuild

    AWSNuke --> VerifyCleanup: AWS Nuke execution
    VerifyCleanup --> CleanupSuccess: Resources deleted
    VerifyCleanup --> CleanupFailed: Resources remain (retry)

    CleanupSuccess --> AvailablePool: Move to Available OU
    CleanupFailed --> RetryCleanup: Retry up to 3x
    RetryCleanup --> QuarantineAccount: Max retries exceeded

    AvailablePool --> [*]: Account ready for reuse
    QuarantineAccount --> [*]: Manual remediation required

    AutoReject --> Rejected
    Rejected --> [*]: Lease denied, TTL delete

    note right of PendingApproval
        Lease record created
        in DynamoDB
    end note

    note right of AIScoring
        19 rules + AI assessment
        (Bedrock Claude)
    end note

    note right of DeployTemplate
        Optional: Deploy CFN
        from ndx_try_aws_scenarios
    end note

    note right of CostCollection
        Query Cost Explorer API
        Write to CostReports table
    end note

    note right of BillingQuarantine
        72-hour delay ensures
        billing data propagation
    end note

    note right of AWSNuke
        Deletes all user resources
        Preserves ISB infrastructure
    end note
```

---

## Flow 3: Complete Deployment Pipeline

### CloudFormation Template Deployment

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant ISB Frontend
    participant Leases API
    participant EventBridge
    participant Approver
    participant Deployer
    participant GitHub
    participant SecretsManager
    participant Pool Account

    User->>ISB Frontend: Create lease with template
    ISB Frontend->>Leases API: POST /leases
    Leases API->>Leases API: Create PendingApproval lease
    Leases API->>EventBridge: Publish LeaseRequested

    EventBridge->>Approver: Trigger approval workflow
    Approver->>Approver: Execute 19-rule scoring
    Approver->>Approver: AI risk assessment (Bedrock)
    Approver->>Approver: Calculate composite score

    alt Score >= 80 (Auto-Approve)
        Approver->>Leases API: Update lease status=Active
        Approver->>EventBridge: Publish LeaseApproved
    else Manual Review Required
        Approver->>ISB Frontend: Escalate to admin
        Note over Approver,ISB Frontend: Admin reviews and approves
        ISB Frontend->>Leases API: POST /leases/{id}/approve
        Leases API->>EventBridge: Publish LeaseApproved
    end

    EventBridge->>Deployer: Trigger deployment (LeaseApproved)

    Deployer->>Leases API: GET /leases/{id}
    Leases API-->>Deployer: Lease details + template info

    Deployer->>Deployer: Parse template configuration
    Deployer->>SecretsManager: Get GitHub token
    SecretsManager-->>Deployer: Personal access token

    alt CDK Project
        Deployer->>GitHub: Check for cdk.json
        GitHub-->>Deployer: cdk.json found
        Deployer->>Deployer: Sparse clone repository
        Deployer->>Deployer: npm ci --ignore-scripts
        Deployer->>Deployer: cdk synth → CloudFormation
    else CloudFormation Template
        Deployer->>GitHub: GET template.yaml
        GitHub-->>Deployer: CloudFormation YAML
    end

    Deployer->>Deployer: Enrich parameters from lease data
    Deployer->>Deployer: Add tags (LeaseId, CostCentre)

    Deployer->>Pool Account: AssumeRole (OrganizationAccountAccessRole)
    Pool Account-->>Deployer: Temporary credentials

    Deployer->>Pool Account: CreateStack (CloudFormation)
    Pool Account-->>Deployer: StackId

    Deployer->>Pool Account: DescribeStacks (poll status)
    Pool Account-->>Deployer: CREATE_IN_PROGRESS

    loop Poll every 30s
        Deployer->>Pool Account: DescribeStacks
        Pool Account-->>Deployer: Status update
    end

    Pool Account-->>Deployer: CREATE_COMPLETE

    Deployer->>EventBridge: Publish DeploymentComplete
    EventBridge->>User: Email notification (stack ready)

    User->>ISB Frontend: View lease details
    ISB Frontend->>User: Display AWS Console access URL
```

---

## Flow 4: Complete Cost Tracking Cycle

### From Termination to Chargeback

```mermaid
graph TB
    subgraph "T+0: Lease Termination"
        A1[User terminates lease<br/>or duration expires]
        A2[Leases API: Update status=Terminated]
        A3[EventBridge: Publish LeaseTerminated]
    end

    subgraph "T+0: Immediate Actions"
        B1[Billing Separator: Queue SQS message<br/>Visibility: 72h]
        B2[Cost Tracker: Create EventBridge Schedule<br/>Trigger: T+24h]
        B3[Lifecycle Manager: Move account<br/>Active OU → CleanUp OU]
    end

    subgraph "T+24h: Cost Collection"
        C1[Scheduler: Trigger Cost Collector Lambda]
        C2[Cost Collector: AssumeRole in Org Mgmt Account]
        C3[Cost Collector: Query Cost Explorer API]
        C4[Cost Explorer: Return cost breakdown<br/>By service, region, daily]
        C5[Cost Collector: Analyze data<br/>Total cost, variance, top services]
        C6[Cost Collector: Write to CostReports DynamoDB]
        C7[Cost Collector: Publish CostDataCollected event]
    end

    subgraph "T+24h: Budget Compliance Check"
        D1{Cost > Budget?}
        D2[Cost Collector: Publish BudgetOverage]
        D3[Email Notification: Alert user]
        D4[Finance Team: Flagged for review]
    end

    subgraph "T+72h: Billing Quarantine Release"
        E1[SQS: Message becomes visible]
        E2[Billing Separator Lambda: Process message]
        E3[Check CostReports DynamoDB]
        E4{Cost data<br/>available?}
        E5[Update account status=Available]
        E6[Extend quarantine 24h]
        E7{96h max<br/>exceeded?}
        E8[Force release + alert ops]
    end

    subgraph "T+72h+: Account Cleanup"
        F1[Cleanup Step Function: Triggered]
        F2[Initialize Cleanup Lambda: Prepare context]
        F3[CodeBuild: Execute AWS Nuke]
        F4[AWS Nuke: Delete all user resources]
        F5{Cleanup<br/>successful?}
        F6[Move account: CleanUp → Available]
        F7[Move account: CleanUp → Quarantine]
        F8[Alert admin: Manual remediation]
    end

    subgraph "Monthly: Chargeback Reporting"
        G1[Scheduled Lambda: 1st of month]
        G2[Query CostReports: Previous month]
        G3[Generate CSV: By org unit, user, lease]
        G4[Upload to S3: chargeback/2024/02/report.csv]
        G5[Finance Team: Download report]
        G6[Finance Team: Process chargebacks]
    end

    A1 --> A2 --> A3
    A3 --> B1 & B2 & B3

    B2 --> C1 --> C2 --> C3 --> C4 --> C5 --> C6 --> C7

    C6 --> D1
    D1 -->|Yes| D2 --> D3 --> D4
    D1 -->|No| C7

    B1 --> E1 --> E2 --> E3 --> E4
    E4 -->|Yes| E5 --> F1
    E4 -->|No| E6 --> E7
    E7 -->|No| E3
    E7 -->|Yes| E8 --> F1

    F1 --> F2 --> F3 --> F4 --> F5
    F5 -->|Yes| F6
    F5 -->|No| F7 --> F8

    G1 --> G2 --> G3 --> G4 --> G5 --> G6

    style A1 fill:#ffe1e1,stroke:#333
    style C6 fill:#e1f5ff,stroke:#333
    style E5 fill:#e1ffe1,stroke:#333
    style F6 fill:#e1ffe1,stroke:#333
    style F7 fill:#ffe1e1,stroke:#333
```

---

## Flow 5: Approver Scoring Process

### 19-Rule Execution Flow

```mermaid
graph TB
    start[LeaseRequested Event] --> sfn_start[Step Functions: Start Execution]

    sfn_start --> validate[ValidateInput State]
    validate --> fetch[FetchContext State]

    fetch --> history[Query user's lease history]
    fetch --> org_policy[Query org unit policies]
    fetch --> template[Query lease template]

    history --> parallel
    org_policy --> parallel
    template --> parallel

    parallel[Parallel State: Execute All Rules]

    parallel --> cat1[Category 1: User History<br/>4 rules in parallel]
    parallel --> cat2[Category 2: Org Policy<br/>4 rules in parallel]
    parallel --> cat3[Category 3: Request Validation<br/>4 rules in parallel]
    parallel --> cat4[Category 4: Financial<br/>3 rules in parallel]
    parallel --> cat5[Category 5: Risk Assessment<br/>4 rules in parallel]

    cat1 --> r01[R01: Previous Lease Compliance]
    cat1 --> r02[R02: Cost Overrun History]
    cat1 --> r03[R03: Lease Duration Pattern]
    cat1 --> r04[R04: Account Cleanup Success]

    cat2 --> r05[R05: Budget Limit Compliance]
    cat2 --> r06[R06: Allowed Regions]
    cat2 --> r07[R07: Required Tags Present]
    cat2 --> r08[R08: Permission Set Authorization]

    cat3 --> r09[R09: Justification Quality AI]
    cat3 --> r10[R10: Template Compatibility]
    cat3 --> r11[R11: Lease Timing]
    cat3 --> r12[R12: Rate Limit Check]

    cat4 --> r13[R13: Current Spend vs Quota]
    cat4 --> r14[R14: Cost Trend Analysis]
    cat4 --> r15[R15: Budget Realism Check]

    cat5 --> r16[R16: Anomaly Detection]
    cat5 --> r17[R17: Concurrent Lease Limit]
    cat5 --> r18[R18: OU Risk Score]
    cat5 --> r19[R19: AI Holistic Risk]

    r09 --> bedrock[Amazon Bedrock<br/>Claude 3 Sonnet]
    r16 --> bedrock
    r19 --> bedrock

    bedrock --> r09
    bedrock --> r16
    bedrock --> r19

    r01 & r02 & r03 & r04 --> aggregate
    r05 & r06 & r07 & r08 --> aggregate
    r09 & r10 & r11 & r12 --> aggregate
    r13 & r14 & r15 --> aggregate
    r16 & r17 & r18 & r19 --> aggregate

    aggregate[Aggregate Scores State<br/>Weighted average calculation]

    aggregate --> decision{Composite Score}

    decision -->|>= 80| auto_approve[Auto-Approve]
    decision -->|50-79| manual_review[Manual Review<br/>Wait for admin]
    decision -->|< 50| auto_reject[Auto-Reject]

    auto_approve --> publish_approved[Publish LeaseApproved]
    manual_review --> admin_ui[Admin Dashboard]
    admin_ui --> admin_decision{Admin Decision}
    admin_decision -->|Approve| publish_approved
    admin_decision -->|Reject| publish_rejected[Publish LeaseDenied]
    auto_reject --> publish_rejected

    publish_approved --> record_success[Record to ApprovalHistory DynamoDB]
    publish_rejected --> record_success

    record_success --> sfn_end[Step Functions: End]

    style bedrock fill:#ff9,stroke:#333
    style auto_approve fill:#9f9,stroke:#333
    style auto_reject fill:#f99,stroke:#333
    style manual_review fill:#ff9,stroke:#333
```

---

## Flow 6: Account Cleanup Process

### AWS Nuke Execution

```mermaid
sequenceDiagram
    autonumber
    participant EventBridge
    participant StepFunction
    participant InitLambda
    participant DynamoDB
    participant AppConfig
    participant CodeBuild
    participant PoolAccount
    participant Organizations

    EventBridge->>StepFunction: Trigger cleanup (LeaseTerminated)

    StepFunction->>InitLambda: Initialize Cleanup
    InitLambda->>DynamoDB: Fetch lease & account details
    InitLambda->>AppConfig: Get nuke-config.yaml
    InitLambda->>AppConfig: Get global-config.yaml
    InitLambda-->>StepFunction: Return cleanup context

    StepFunction->>CodeBuild: StartBuild

    CodeBuild->>CodeBuild: Assume role in pool account
    CodeBuild->>PoolAccount: Validate IAM role

    CodeBuild->>CodeBuild: Download AWS Nuke binary (v3.63.2)
    CodeBuild->>PoolAccount: Inventory resources across regions

    loop For each region
        CodeBuild->>PoolAccount: List EC2 instances
        CodeBuild->>PoolAccount: List S3 buckets
        CodeBuild->>PoolAccount: List IAM roles
        CodeBuild->>PoolAccount: List Lambda functions
        CodeBuild->>PoolAccount: List CloudFormation stacks
    end

    CodeBuild->>CodeBuild: Apply nuke-config filters<br/>(protect ISB resources)

    CodeBuild->>PoolAccount: Delete EC2 instances
    CodeBuild->>PoolAccount: Delete S3 buckets (empty first)
    CodeBuild->>PoolAccount: Delete Lambda functions
    CodeBuild->>PoolAccount: Delete CloudFormation stacks
    CodeBuild->>PoolAccount: Delete IAM roles (non-protected)

    CodeBuild->>PoolAccount: Re-inventory resources
    PoolAccount-->>CodeBuild: Resource counts

    alt All resources deleted
        CodeBuild-->>StepFunction: SUCCESS
        StepFunction->>Organizations: Move account (CleanUp → Available)
        StepFunction->>DynamoDB: Update account status=Available
        StepFunction->>EventBridge: Publish AccountCleaned
    else Resources remain
        CodeBuild-->>StepFunction: FAILED (resource list)
        StepFunction->>StepFunction: Increment retry count

        alt Retry count < 3
            StepFunction->>StepFunction: Wait 5 minutes
            StepFunction->>CodeBuild: StartBuild (retry)
        else Max retries exceeded
            StepFunction->>Organizations: Move account (CleanUp → Quarantine)
            StepFunction->>DynamoDB: Update account status=Quarantine
            StepFunction->>EventBridge: Publish AccountQuarantined
            StepFunction->>EventBridge: Alert admin (manual remediation)
        end
    end
```

---

## Operational Processes

### Daily Operations Checklist

```
□ Monitor quarantine queue (should be < 2 accounts)
□ Review cost overages from previous day
□ Check deployer success rate (should be > 95%)
□ Verify approver scoring (80%+ auto-approval target)
□ Review manual approval queue (should be < 10 pending)
□ Check pool capacity (should have >= 5 available accounts)
□ Review CloudWatch alarms (should have 0 active)
□ Scan EventBridge DLQ (should be empty)
□ Verify Cost Explorer quota usage (should be < 80%)
```

### Weekly Operations

```
□ Update ukps-domains whitelist from GitHub
□ Review quarantined accounts (manual cleanup if needed)
□ Generate pool utilization report
□ Review Bedrock AI cost trends
□ Rotate GitHub API token (if expiring)
□ Update Slack channel with metrics summary
```

### Monthly Operations

```
□ Generate chargeback reports (1st of month)
□ Send cost reports to finance team
□ Review capacity planning (add pool accounts if needed)
□ Audit permission sets in Identity Center
□ Review and update lease templates
□ Conduct security audit (access logs, IAM policies)
□ Update documentation with operational learnings
```

---

## References

- [70-data-flows.md](./70-data-flows.md) - Detailed data transformations
- [11-lease-lifecycle.md](./11-lease-lifecycle.md) - Lease state machine
- [20-approver-system.md](./20-approver-system.md) - Scoring rules

---

**Document Version:** 1.0
**Last Updated:** 2026-02-03
**Status:** Complete - End-to-end process documentation
