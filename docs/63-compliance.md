# Compliance and Security Controls

**Document Version:** 1.0
**Date:** 2026-02-03
**Scope:** NDX:Try AWS platform compliance alignment

---

## Executive Summary

This document analyzes the NDX:Try AWS platform's alignment with UK government cloud security frameworks, including NCSC Cloud Security Principles and GDS Service Standard. It provides a comprehensive summary of implemented security controls and identifies gaps for future remediation.

**Compliance Frameworks Assessed:**
1. **NCSC Cloud Security Principles** - UK government cloud security baseline
2. **GDS Service Standard** - UK government digital service requirements
3. **NIST Cybersecurity Framework** - Industry-standard security controls

**Overall Assessment:**
- **Strong Alignment:** Data protection, identity management, secure deployment
- **Partial Alignment:** Security monitoring, incident response procedures
- **Gaps Identified:** Formal penetration testing, documented DR procedures

---

## 1. NCSC Cloud Security Principles

### Overview

The National Cyber Security Centre (NCSC) defines 14 Cloud Security Principles for UK public sector organizations using cloud services.

**Source:** https://www.ncsc.gov.uk/collection/cloud/the-cloud-security-principles

---

### Principle 1: Data in Transit Protection

**Requirement:** User data transiting networks should be adequately protected against tampering and eavesdropping.

**Implementation:**

| Component | Protection | Details |
|-----------|-----------|---------|
| CloudFront | TLS 1.2+ | HTTPS redirect enforced |
| API Gateway | TLS 1.2+ | Regional endpoint with ACM certificate |
| S3 | SSL/TLS | Bucket policy denies non-HTTPS access |
| Lambda↔AWS Services | HTTPS | AWS SDK default behavior |

**Evidence:**
- CloudFront distribution: `minimumProtocolVersion: TLS_V1_2_2021`
- API Gateway: Resource policy requires `aws:SecureTransport: true`
- S3 bucket policy: Denies `s3:*` when `aws:SecureTransport: false`

**Assessment:** ✅ **Compliant**

**Reference:** [61-encryption.md](./61-encryption.md) - TLS Configuration

---

### Principle 2: Asset Protection and Resilience

**Requirement:** User data, and the assets storing or processing it, should be protected against physical tampering, loss, damage or seizure.

**Implementation:**

| Asset Type | Protection Mechanism |
|-----------|---------------------|
| DynamoDB | Multi-AZ replication, Point-in-Time Recovery |
| S3 | Cross-region replication (not enabled), Versioning |
| Lambda | Multi-AZ deployment by default |
| ECR | Container image replication |

**Resilience Features:**
- DynamoDB PITR: 35-day continuous backups
- S3 lifecycle: 3-year retention for cost reports
- Deletion protection: Enabled on production DynamoDB tables

**Gaps:**
- No cross-region disaster recovery
- No documented RTO/RPO targets

**Assessment:** ⚠️ **Partial Compliance** (single-region deployment)

**Recommendations:**
1. Implement cross-region S3 replication for critical data
2. Document disaster recovery procedures
3. Define and test RTO/RPO targets

---

### Principle 3: Separation Between Users

**Requirement:** A malicious or compromised user of the service should not be able to affect the service or data of another.

**Implementation:**

| Mechanism | Implementation |
|-----------|----------------|
| AWS Accounts | Separate pool accounts per sandbox lease |
| IAM Isolation | Account-level IAM boundaries |
| Network Isolation | No shared VPCs between sandboxes |
| Data Isolation | DynamoDB partition keys by user email |

**Multi-Tenancy Controls:**
- Each sandbox lease uses a dedicated AWS account
- No resource sharing between leases
- API authorization checks user identity (JWT claims)
- DynamoDB queries filtered by `userEmail`

**Assessment:** ✅ **Compliant**

**Reference:** [60-auth-architecture.md](./60-auth-architecture.md) - User Isolation

---

### Principle 4: Governance Framework

**Requirement:** The service provider should have a security governance framework which coordinates and directs its management of the service and information within it.

**Implementation:**

| Area | Implementation |
|------|----------------|
| Code Reviews | GitHub pull request requirements |
| Change Management | GitHub workflows with approval gates |
| Security Scanning | OpenSSF Scorecard (weekly) |
| Access Control | IAM Identity Center with MFA |

**Documented Governance:**
- Architecture Decision Records (ADRs) in ndx repository
- Deployment procedures documented in runbooks
- Manual approval required for critical infrastructure changes

**Gaps:**
- No formal information security management system (ISMS)
- No documented incident response plan

**Assessment:** ⚠️ **Partial Compliance**

**Recommendations:**
1. Document formal incident response procedures
2. Create security policy documents
3. Establish regular security reviews

---

### Principle 5: Operational Security

**Requirement:** The service needs to be operated and managed securely to impede, detect or prevent attacks.

**Implementation:**

| Control | Status |
|---------|--------|
| Vulnerability Management | Dependabot enabled |
| Patch Management | Automated via GitHub Actions |
| Security Monitoring | CloudWatch Logs, CloudTrail |
| Configuration Management | Infrastructure as Code (CDK, Terraform) |

**Operational Controls:**
- GitHub Dependabot for dependency updates
- Automated deployment pipelines reduce manual errors
- CloudTrail logs all API activity
- AWS Config for configuration compliance (LZA)

**Gaps:**
- No centralized SIEM (Security Information and Event Management)
- No automated security alerting beyond basic CloudWatch alarms

**Assessment:** ⚠️ **Partial Compliance**

**Recommendations:**
1. Implement AWS Security Hub
2. Configure GuardDuty for threat detection
3. Create security event dashboards

---

### Principle 6: Personnel Security

**Requirement:** Service provider staff should be subject to personnel security screening and security education.

**Implementation:**

**Note:** This principle applies to AWS as the cloud provider, not the NDX platform itself.

**NDX Platform Controls:**
- SSO access requires organizational credentials
- GitHub access restricted to co-cddo organization
- Multi-factor authentication required (GitHub, AWS SSO)

**Assessment:** ✅ **Compliant** (relies on AWS and organizational controls)

---

### Principle 7: Secure Development

**Requirement:** Services should be designed and developed to identify and mitigate threats to their security.

**Implementation:**

| Practice | Implementation |
|----------|----------------|
| Secure Coding | ESLint, TypeScript strict mode |
| Dependency Scanning | Dependabot, npm audit |
| Code Review | Required for all PRs |
| SAST | ESLint security rules |
| Security Testing | Unit tests, E2E tests |

**Security Practices:**
- Pre-commit hooks for code quality
- GitHub Actions security scanning
- OpenSSF Scorecard for supply chain security
- No hardcoded secrets (enforced by linting)

**Gaps:**
- No formal SAST tool (e.g., SonarQube, Snyk)
- No DAST (Dynamic Application Security Testing)
- No penetration testing

**Assessment:** ⚠️ **Partial Compliance**

**Recommendations:**
1. Integrate SAST tool (Snyk, SonarQube)
2. Conduct annual penetration testing
3. Implement security champions program

---

### Principle 8: Supply Chain Security

**Requirement:** The service provider should ensure that its supply chain satisfactorily supports all of the security principles that the service claims to implement.

**Implementation:**

| Component | Supply Chain Security |
|-----------|---------------------|
| AWS Services | AWS certifications (ISO 27001, SOC 2) |
| npm Packages | Dependabot, npm audit, package-lock.json |
| Docker Images | Official base images, vulnerability scanning |
| GitHub Actions | Pinned action versions (SHA hashes) |

**Supply Chain Controls:**
- OpenSSF Scorecard (supply chain risk assessment)
- npm package auditing on every build
- Docker image scanning (manual)
- GitHub Actions use official actions or pinned SHAs

**Best Practice Example (ndx repository):**
```yaml
- uses: actions/checkout@0c366fd6a839edf440554fa01a7085ccba70ac98 # v6.0.1
```

**Gaps:**
- No automated container image scanning (ECR scanning not enabled)
- No SBOM (Software Bill of Materials) generation

**Assessment:** ⚠️ **Partial Compliance**

**Recommendations:**
1. Enable ECR image scanning
2. Generate and publish SBOMs
3. Implement container signing with AWS Signer

---

### Principle 9: Secure User Management

**Requirement:** Your provider should make the tools available for you to securely manage your use of their service.

**Implementation:**

| Feature | Implementation |
|---------|----------------|
| Identity Provider | IAM Identity Center (SAML 2.0) |
| MFA | Enforced via IAM Identity Center |
| RBAC | IAM roles and policies |
| Session Management | 4-hour JWT expiry, SAML session timeout |

**User Management:**
- IAM Identity Center for centralized user management
- Group-based access control (ISB-Admins, ISB-Users, ISB-Approvers)
- Short-lived credentials (JWT 4 hours, STS 1 hour)
- Audit logging via CloudTrail

**Assessment:** ✅ **Compliant**

**Reference:** [60-auth-architecture.md](./60-auth-architecture.md)

---

### Principle 10: Identity and Authentication

**Requirement:** All access to service interfaces should be constrained to authenticated and authorised individuals.

**Implementation:**

| Interface | Authentication Method |
|-----------|---------------------|
| ISB UI | SAML 2.0 via IAM Identity Center |
| ISB API | JWT Bearer tokens (Lambda authorizer) |
| AWS Console | IAM Identity Center SSO |
| GitHub Actions | OIDC (short-lived tokens) |

**Authentication Controls:**
- SAML assertion validation (signature, timestamp, audience)
- JWT signature verification (HMAC-SHA256)
- OIDC token validation (GitHub issuer, repository scope)
- No long-lived credentials (access keys replaced with OIDC)

**Assessment:** ✅ **Compliant**

**Reference:** [60-auth-architecture.md](./60-auth-architecture.md), [51-oidc-configuration.md](./51-oidc-configuration.md)

---

### Principle 11: External Interface Protection

**Requirement:** All external or less trusted interfaces of the service should be identified and appropriately defended.

**Implementation:**

| Interface | Protection |
|-----------|-----------|
| CloudFront (UI) | WAF rules, TLS, HSTS headers |
| API Gateway | Lambda authorizer, rate limiting, resource policies |
| Public GitHub Repos | Read-only for external users |
| ECR | Private repositories |

**External Interface Security:**
- CloudFront enforces HTTPS redirect
- API Gateway requires valid JWT token
- No public S3 buckets (block public access enabled)
- GitHub OIDC roles have fork protection

**Assessment:** ✅ **Compliant**

---

### Principle 12: Secure Service Administration

**Requirement:** Systems used for administration of a cloud service will have highly privileged access to that service. Their compromise would have significant impact.

**Implementation:**

| Administrative Interface | Security Control |
|------------------------|------------------|
| AWS Console | IAM Identity Center MFA |
| AWS CLI | SSO temporary credentials |
| GitHub | MFA required, branch protection |
| Terraform/CDK | Manual approval gates |

**Administrative Controls:**
- No IAM users (SSO only)
- Time-limited SSO sessions
- Manual approval for infrastructure changes (Terraform)
- GitHub branch protection on main branches
- Audit logging via CloudTrail

**Assessment:** ✅ **Compliant**

---

### Principle 13: Audit Information for Users

**Requirement:** You should be provided with the audit records needed to monitor access to your service and the data held within it.

**Implementation:**

| Audit Source | Retention | Coverage |
|-------------|-----------|----------|
| CloudTrail | 90 days (default) | All AWS API calls |
| CloudWatch Logs | 30 days (configurable) | Lambda function logs, API Gateway logs |
| DynamoDB | N/A | Lease history stored in table |
| GitHub Actions | 90 days | Workflow execution logs |

**Audit Capabilities:**
- CloudTrail logs all IAM and service actions
- API Gateway logs all API requests
- Lambda logs include user context (email from JWT)
- Lease audit trail in DynamoDB

**Gaps:**
- CloudTrail logs not archived to S3 long-term
- No centralized log analysis tool

**Assessment:** ⚠️ **Partial Compliance**

**Recommendations:**
1. Archive CloudTrail to S3 with 7-year retention
2. Implement log aggregation (e.g., AWS CloudWatch Insights)
3. Create audit dashboards

---

### Principle 14: Secure Use of the Service

**Requirement:** The security of cloud services and the data held within them can be undermined if you use the service poorly.

**Implementation:**

| User Guidance | Status |
|--------------|--------|
| Documentation | Comprehensive READMEs in all repos |
| Security Best Practices | Documented in runbooks |
| Training Materials | Not formalized |
| Support Channels | GitHub Issues, Slack |

**User Education:**
- ISB UI provides clear guidance on sandbox usage
- Scenario documentation explains security controls
- Cost defense mechanisms protect against misuse

**Gaps:**
- No formal user training program
- No security awareness materials for sandbox users

**Assessment:** ⚠️ **Partial Compliance**

**Recommendations:**
1. Create user security awareness materials
2. Document common security pitfalls
3. Provide security training for administrators

---

## 2. GDS Service Standard

### Overview

The Government Digital Service (GDS) defines 14 Service Standard points for UK government services.

**Source:** https://www.gov.uk/service-manual/service-standard

---

### Point 1: Understand Users and Their Needs

**Implementation:**
- NDX website provides clear onboarding guidance
- Scenario descriptions explain use cases
- User feedback collected via GitHub Issues

**Assessment:** ✅ **Met**

---

### Point 2: Solve a Whole Problem for Users

**Implementation:**
- End-to-end sandbox provisioning (request → access → cleanup)
- Integrated cost reporting
- Evidence pack generation for decision-makers

**Assessment:** ✅ **Met**

---

### Point 3: Provide a Joined-Up Experience

**Implementation:**
- Consistent GOV.UK Design System across NDX website
- Single sign-on via IAM Identity Center
- Unified API for all ISB operations

**Assessment:** ✅ **Met**

---

### Point 4: Make the Service Simple to Use

**Implementation:**
- One-click scenario deployment
- Automated account provisioning
- Clear status indicators in UI

**Assessment:** ✅ **Met**

---

### Point 5: Make Sure Everyone Can Use the Service

**Accessibility:**
- WCAG 2.2 AA compliance (pa11y-ci in CI/CD)
- GOV.UK Frontend components
- Lighthouse accessibility audits

**Assessment:** ✅ **Met** (zero tolerance accessibility testing)

**Reference:** [50-github-actions-inventory.md](./50-github-actions-inventory.md) - Accessibility workflows

---

### Point 6: Have a Multidisciplinary Team

**Note:** Organizational structure, not technical implementation

---

### Point 7: Use Agile Ways of Working

**Implementation:**
- GitHub Projects for sprint planning
- Continuous deployment pipelines
- Iterative development with ADRs

**Assessment:** ✅ **Met**

---

### Point 8: Iterate and Improve Frequently

**Implementation:**
- Automated deployment on merge
- Feature flags via AppConfig
- A/B testing capabilities (not actively used)

**Assessment:** ✅ **Met**

---

### Point 9: Create a Secure Service

**Security Controls Summary:**

| Control Category | Implementation |
|-----------------|----------------|
| Authentication | SAML 2.0, JWT, OIDC |
| Authorization | Lambda authorizer, IAM policies |
| Encryption | TLS 1.2+, KMS customer-managed keys |
| Monitoring | CloudTrail, CloudWatch Logs |
| Vulnerability Management | Dependabot, OpenSSF Scorecard |

**Assessment:** ✅ **Met** (see NCSC principles above)

---

### Point 10: Define Success Metrics

**Metrics Tracked:**
- Sandbox lease requests and approvals
- Cost per sandbox lease
- User satisfaction (informal)

**Gaps:**
- No formal KPI dashboard
- Limited usage analytics

**Assessment:** ⚠️ **Partial** (metrics exist but not formalized)

---

### Point 11: Choose the Right Tools and Technology

**Technology Choices:**
- AWS CDK for infrastructure as code
- TypeScript for type safety
- Serverless architecture for cost efficiency
- Eleventy for static site generation

**Assessment:** ✅ **Met** (well-documented ADRs)

---

### Point 12: Make New Source Code Open

**Open Source Status:**
- All repositories are public on GitHub
- Apache 2.0 or similar licenses
- Contributing guidelines provided

**Assessment:** ✅ **Met**

---

### Point 13: Use and Contribute to Open Standards

**Standards Used:**
- SAML 2.0 for identity federation
- OIDC for GitHub authentication
- REST API design
- OpenAPI specifications

**Assessment:** ✅ **Met**

---

### Point 14: Operate a Reliable Service

**Reliability:**
- Multi-AZ deployments (Lambda, DynamoDB)
- Point-in-time recovery enabled
- Automated monitoring and alerting

**Gaps:**
- No documented SLA
- No uptime monitoring dashboard

**Assessment:** ⚠️ **Partial**

**Recommendations:**
1. Define and publish SLA
2. Implement uptime monitoring (e.g., AWS CloudWatch Synthetics)
3. Create public status page

---

## 3. NIST Cybersecurity Framework

### Summary Alignment

| Function | Implementation | Gaps |
|----------|----------------|------|
| **Identify (ID)** | Asset inventory, risk assessment | No formal risk register |
| **Protect (PR)** | IAM, encryption, access control | See NCSC gaps above |
| **Detect (DE)** | CloudTrail, CloudWatch | No SIEM, no GuardDuty |
| **Respond (RS)** | Incident procedures (informal) | No documented IR plan |
| **Recover (RC)** | PITR, backups | No tested DR plan |

---

## 4. Security Controls Summary

### Implemented Controls

**Identity and Access Management:**
- [x] SAML 2.0 authentication
- [x] JWT token-based API authorization
- [x] Multi-factor authentication via IAM Identity Center
- [x] Least-privilege IAM policies
- [x] GitHub OIDC (no long-lived credentials)

**Data Protection:**
- [x] TLS 1.2+ for all network traffic
- [x] Customer-managed KMS encryption for DynamoDB
- [x] S3 bucket encryption (SSE-S3 or SSE-KMS)
- [x] Secrets Manager for sensitive data
- [x] Automatic secret rotation (JWT)

**Network Security:**
- [x] CloudFront WAF (basic rules)
- [x] API Gateway resource policies
- [x] No public S3 buckets
- [x] VPC endpoints (not currently used)

**Application Security:**
- [x] Input validation
- [x] Output encoding
- [x] CSRF protection (SameSite cookies)
- [x] Content Security Policy headers

**Infrastructure Security:**
- [x] Infrastructure as Code (CDK, Terraform)
- [x] Automated deployment pipelines
- [x] Immutable infrastructure (Lambda, containers)
- [x] Deletion protection on critical resources

**Monitoring and Logging:**
- [x] CloudTrail for all AWS API calls
- [x] CloudWatch Logs for application logs
- [x] API Gateway logging
- [x] Lambda function logging

**Supply Chain Security:**
- [x] Dependency scanning (Dependabot)
- [x] OpenSSF Scorecard
- [x] Pinned GitHub Action versions
- [x] npm package lock files

---

### Security Gaps

**High Priority:**
1. **No formal incident response plan**
   - Impact: Delayed response to security incidents
   - Recommendation: Document and test IR procedures

2. **No automated security alerting**
   - Impact: Security events may go unnoticed
   - Recommendation: Implement AWS Security Hub + GuardDuty

3. **No penetration testing**
   - Impact: Unknown vulnerabilities
   - Recommendation: Annual penetration testing

**Medium Priority:**
4. **Single-region deployment**
   - Impact: No geographic redundancy
   - Recommendation: Multi-region disaster recovery

5. **No centralized log analysis**
   - Impact: Difficult to detect patterns
   - Recommendation: Implement CloudWatch Insights or third-party SIEM

6. **CloudTrail logs not archived**
   - Impact: Short retention period
   - Recommendation: Archive to S3 with 7-year retention

**Low Priority:**
7. **No SAST tool**
   - Impact: Potential code vulnerabilities
   - Recommendation: Integrate Snyk or SonarQube

8. **No container image scanning**
   - Impact: Vulnerable dependencies in containers
   - Recommendation: Enable ECR scanning

---

## 5. Compliance Roadmap

### Q1 2026

- [ ] Document incident response plan
- [ ] Enable AWS Security Hub
- [ ] Enable AWS GuardDuty
- [ ] Archive CloudTrail to S3

### Q2 2026

- [ ] Conduct penetration testing
- [ ] Implement CloudWatch Insights dashboards
- [ ] Enable ECR image scanning
- [ ] Create security event playbooks

### Q3 2026

- [ ] Multi-region disaster recovery planning
- [ ] SBOM generation and publishing
- [ ] Formal security training materials
- [ ] RTO/RPO testing

### Q4 2026

- [ ] Annual security review
- [ ] Compliance audit preparation
- [ ] Update risk assessment
- [ ] Review and update security controls

---

## 6. Compliance Assessment Summary

| Framework | Overall Compliance | Strengths | Gaps |
|-----------|-------------------|-----------|------|
| **NCSC Cloud Security Principles** | ⚠️ **Partial** (11/14 compliant) | Data protection, identity, secure development | DR planning, security monitoring, penetration testing |
| **GDS Service Standard** | ✅ **Strong** (12/14 met) | Accessibility, open source, agile development | SLA definition, formal metrics |
| **NIST CSF** | ⚠️ **Partial** | Identify, Protect functions strong | Detect, Respond, Recover need improvement |

---

## Related Documents

- [60-auth-architecture.md](./60-auth-architecture.md) - Authentication controls
- [61-encryption.md](./61-encryption.md) - Encryption controls
- [62-secrets-management.md](./62-secrets-management.md) - Secrets management
- [50-github-actions-inventory.md](./50-github-actions-inventory.md) - CI/CD security

---

**Prepared By:** Architecture Archaeology Project
**Review Date:** 2026-02-03
**Next Review:** 2026-08-03 (6 months)
