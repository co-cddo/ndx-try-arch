# NDX:Try AWS Architecture Documentation

**Last Updated:** 2026-02-03
**Total Documents:** 30+
**Status:** Comprehensive architecture archaeology project

---

## Executive Summary

This documentation suite represents a comprehensive "architecture archaeology" exercise for the National Digital Exchange (NDX) Try AWS platform and Innovation Sandbox on AWS (ISB) ecosystem. The NDX:Try platform enables UK local government employees to experiment with AWS services in temporary, governed sandbox accounts at zero cost.

**Key Components:**
- **Innovation Sandbox on AWS (ISB):** Multi-account sandbox provisioning platform (forked from AWS Solutions)
- **NDX Website:** Informational platform and scenario catalog
- **ISB Satellites:** Approver (AI scoring), Deployer (auto-provisioning), Costs (tracking), Billing Separator (quarantine)
- **AWS Infrastructure:** 16 accounts across Landing Zone Accelerator managed organization

---

## Quick Start

### For New Team Members

**Read First:**
1. [00-index.md](./00-index.md) - Complete table of contents
2. [00-repo-inventory.md](./00-repo-inventory.md) - All 12 repositories
3. [02-aws-organization.md](./02-aws-organization.md) - Account structure
4. [10-isb-core-architecture.md](./10-isb-core-architecture.md) - ISB platform deep dive

### For Operations Team

**Essential Reading:**
1. [03-hub-account-resources.md](./03-hub-account-resources.md) - Hub account inventory
2. [90-issues-discovered.md](./90-issues-discovered.md) - Known issues
3. [82-process-flows.md](./82-process-flows.md) - Operational processes

### For Developers

**Key Documents:**
1. [72-repo-dependencies.md](./72-repo-dependencies.md) - Repository dependencies
2. [70-data-flows.md](./70-data-flows.md) - Data flow diagrams
3. [71-external-integrations.md](./71-external-integrations.md) - External APIs

### For Architects

**High-Level Views:**
1. [80-c4-architecture.md](./80-c4-architecture.md) - C4 model diagrams
2. [81-aws-architecture.md](./81-aws-architecture.md) - AWS infrastructure
3. [82-process-flows.md](./82-process-flows.md) - End-to-end flows

---

## Documentation Structure

The documentation is organized into 10 phases:

### Phase 1: Repository Discovery (00-01)
- Repository inventory and upstream analysis
- Deployment patterns and IaC types

### Phase 2: AWS Organization Structure (02-05)
- Account hierarchy and OUs
- Cross-account trust relationships
- Service Control Policies

### Phase 3: ISB Core Architecture (10-11)
- ISB platform internals
- Lease lifecycle state machine

### Phase 4: ISB Satellite Components (20-23)
- Approver (AI-powered scoring)
- Billing Separator (quarantine)
- Cost Tracking (Cost Explorer integration)
- Deployer (auto-provisioning)

### Phase 5: NDX Websites (30-31)
- NDX informational website
- Try AWS scenario catalog

### Phase 6: LZA & Terraform (40-42)
- Landing Zone Accelerator configuration
- Terraform SCP management
- IaC conflicts and consolidation

### Phase 7: CI/CD Pipelines (50-52)
- GitHub Actions workflows
- OIDC configuration
- Deployment flows

### Phase 8: Security & Compliance (60-62)
- IAM policies and roles
- Data protection
- Compliance mappings

### Phase 9: Data Flows & Integration (70-72)
- Complete data flow diagrams
- External integrations (ukps-domains, GitHub, Bedrock)
- Repository dependencies

### Phase 10: Master Diagrams & Index (80-82, README, 00-index)
- C4 architecture diagrams
- AWS infrastructure map
- Process flows
- Navigation indexes

---

## Key Architectural Patterns

### Event-Driven Architecture
- EventBridge as central event bus
- ISB Core publishes lifecycle events
- Satellites subscribe to event patterns
- Loose coupling enables independent deployment

### Multi-Account Isolation
- Hub Account (568672915267): Control plane
- Pool Accounts (x9): Sandboxed user workloads
- Management Account (955063685555): Organization root
- Cross-account IAM roles for orchestration

### Serverless-First
- AWS Lambda for all compute (19+ functions)
- DynamoDB for data persistence (6 tables)
- Step Functions for orchestration
- EventBridge Scheduler for delayed tasks

### Cost Defense in Depth
- 5 layers: SCPs, Service Quotas, Budgets, Anomaly Detection, Billing Enforcer
- Budget limits ($50/day, $1000/month)
- Real-time monitoring and alerting
- Automated account quarantine on breach

---

## System Statistics

### Infrastructure
- **AWS Organization:** 1 (o-4g8nrlnr9s)
- **Accounts:** 16 total (7 infrastructure, 9 pool)
- **Regions:** Primary eu-west-2, Secondary us-east-1
- **Repositories:** 12 (5 ISB, 2 NDX, 3 infrastructure, 2 utilities)

### ISB Platform
- **Lambda Functions:** 19+ (Node.js 20/22, Python 3.12)
- **DynamoDB Tables:** 6 (LeaseTable, SandboxAccountTable, CostReports, etc.)
- **EventBridge Rules:** 10+
- **Step Functions:** 2 (Cleanup, Approval)
- **CloudFormation Templates:** 275+ (in ndx_try_aws_scenarios)

### Satellite Services
- **Approver:** 19-rule scoring engine + Amazon Bedrock AI
- **Deployer:** CloudFormation + CDK auto-deployment
- **Costs:** AWS Cost Explorer integration (24h delay)
- **Billing Separator:** 72-hour quarantine (SQS delay queue)

### NDX Website
- **Static Site Generator:** Eleventy v3.1.2
- **Design System:** GOV.UK Frontend v8.3.0
- **Scenarios:** 7 pre-built (Council Chatbot, Planning AI, FOI Redaction, etc.)
- **Hosting:** S3 + CloudFront

---

## Glossary

| Term | Definition |
|------|------------|
| **ISB** | Innovation Sandbox on AWS - core platform for sandbox account provisioning |
| **NDX** | National Digital Exchange - informational website and Try AWS platform |
| **LZA** | AWS Landing Zone Accelerator - multi-account baseline configuration |
| **SCP** | Service Control Policy - AWS Organizations policy for permission guardrails |
| **Hub Account** | Central account (568672915267) hosting ISB control plane |
| **Pool Account** | Temporary AWS account leased to users for experimentation |
| **Lease** | Time-limited grant of access to a pool account with budget/duration limits |
| **Satellite** | Independent service that integrates with ISB Core via EventBridge |
| **CDDO** | Central Digital & Data Office - UK government organization managing NDX |
| **ukps-domains** | UK Public Sector domains whitelist (GitHub repo) |
| **Bedrock** | Amazon Bedrock - AWS AI service used for lease approval scoring |
| **AWS Nuke** | Open-source tool for deleting all resources in an AWS account |
| **PITR** | Point-in-Time Recovery - DynamoDB backup feature (35-day retention) |

---

## Diagram Legend

### Mermaid Diagram Colors

| Color | Meaning |
|-------|---------|
| Green fill (#9f9, #e1ffe1) | Active, available, or healthy state |
| Yellow fill (#ff9, #fff3cd) | Warning, pending, or manual review required |
| Red fill (#f99, #ffe1e1) | Error, quarantine, or terminated state |
| Blue fill (#bbf, #e1f5ff) | AWS managed service or external system |
| Purple fill (#f9f) | External repository or third-party system |

### C4 Diagram Notation

- **System:** High-level software system
- **Container:** Application, data store, or microservice
- **Component:** Module or class (used sparingly)
- **Person:** User type or actor
- **External System:** Third-party system
- **Boundary:** Organizational or security boundary

### Common Icons/Symbols

- `→` : Data flow direction
- `()` : Database or data store
- `[]` : Service or component
- `{}` : Decision point
- `<>` : External integration point

---

## Document Conventions

### Cross-References
- Internal links use relative paths: `[Document](./file.md)`
- Section links use anchors: `[Section](#anchor-name)`
- External links use full URLs with titles

### Code Blocks
- TypeScript/JavaScript for ISB Core and satellites
- Python for Costs and Billing Separator
- Bash for deployment scripts
- YAML for LZA configuration
- JSON for event schemas and API contracts

### Diagrams
- Mermaid syntax (rendered by GitHub)
- Flowcharts for processes
- Sequence diagrams for interactions
- State diagrams for lifecycles
- C4 diagrams for architecture views
- Journey maps for user experiences

### Status Indicators
- ✅ Complete/Working
- ⏳ In Progress
- ❌ Not Started
- ⚠️ Issue/Warning
- 🔴 Critical
- 🟠 High Priority
- 🟡 Medium Priority
- 🟢 Low Priority

---

## Recommended Reading Paths

### Path 1: Executive/Leadership
1. README.md (this file)
2. [80-c4-architecture.md](./80-c4-architecture.md) - System context
3. [82-process-flows.md](./82-process-flows.md) - User journeys
4. [22-cost-tracking.md](./22-cost-tracking.md) - Cost management

### Path 2: Operations Team
1. [00-repo-inventory.md](./00-repo-inventory.md) - Repository overview
2. [02-aws-organization.md](./02-aws-organization.md) - Account structure
3. [03-hub-account-resources.md](./03-hub-account-resources.md) - Hub resources
4. [90-issues-discovered.md](./90-issues-discovered.md) - Known issues
5. [82-process-flows.md](./82-process-flows.md) - Operational processes

### Path 3: Development Team
1. [00-repo-inventory.md](./00-repo-inventory.md) - Repository inventory
2. [72-repo-dependencies.md](./72-repo-dependencies.md) - Dependencies
3. [10-isb-core-architecture.md](./10-isb-core-architecture.md) - ISB architecture
4. [70-data-flows.md](./70-data-flows.md) - Data flows
5. [71-external-integrations.md](./71-external-integrations.md) - External APIs
6. [Component-specific docs](./00-index.md) (20-23 for satellites)

### Path 4: Security/Compliance Team
1. [02-aws-organization.md](./02-aws-organization.md) - Organization structure
2. [04-cross-account-trust.md](./04-cross-account-trust.md) - IAM roles
3. [05-service-control-policies.md](./05-service-control-policies.md) - SCPs
4. Security & Compliance section (60-62 when created)

### Path 5: Platform Architect
1. [80-c4-architecture.md](./80-c4-architecture.md) - C4 diagrams
2. [81-aws-architecture.md](./81-aws-architecture.md) - AWS infrastructure
3. [10-isb-core-architecture.md](./10-isb-core-architecture.md) - ISB deep dive
4. [11-lease-lifecycle.md](./11-lease-lifecycle.md) - State machine
5. [20-approver-system.md](./20-approver-system.md) - AI scoring
6. [82-process-flows.md](./82-process-flows.md) - End-to-end flows

---

## Contributing to Documentation

This documentation was created through an architecture archaeology process and should be maintained as a living artifact.

### Updating Documentation

1. **Small Changes:** Edit Markdown files directly
2. **New Sections:** Follow existing naming convention (NN-topic-name.md)
3. **Diagrams:** Use Mermaid syntax for version control and rendering
4. **Cross-References:** Update 00-index.md when adding new files

### Documentation Standards

- Use present tense ("The system does..." not "The system will do...")
- Prefer active voice ("Lambda invokes..." not "Lambda is invoked...")
- Include code examples with syntax highlighting
- Reference specific file paths and line numbers when relevant
- Add glossary entries for new acronyms
- Keep diagrams simple and focused (one concept per diagram)

---

## Support & Contacts

### Repository Owners
- **NDX Platform:** GDS (Government Digital Service)
- **ISB Fork:** co-cddo (Central Digital & Data Office)

### Key Repositories
- innovation-sandbox-on-aws: https://github.com/co-cddo/innovation-sandbox-on-aws
- ndx: https://github.com/co-cddo/ndx
- ndx_try_aws_scenarios: https://github.com/co-cddo/ndx_try_aws_scenarios

### External Dependencies
- Upstream ISB: https://github.com/aws-solutions/innovation-sandbox-on-aws
- ukps-domains: https://github.com/govuk-digital-backbone/ukps-domains (assumed)

---

## Document History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-03 | 1.0 | Initial comprehensive documentation release (Phase 1-10) |

---

**🚀 Start exploring:** [Complete Document Index](./00-index.md)

**❓ Questions?** Check [Issues Discovered](./90-issues-discovered.md) for known limitations and troubleshooting.

**📊 Quick Reference:** Jump to [C4 Diagrams](./80-c4-architecture.md) for visual overview.
