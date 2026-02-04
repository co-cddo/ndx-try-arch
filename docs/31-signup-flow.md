# NDX Signup Flow

## Executive Summary

The NDX Signup Flow is an end-to-end user registration system that enables UK public sector employees to self-service create accounts for accessing the NDX Try Before You Buy platform. The system integrates domain validation using the `ukps-domains` allowlist, cross-account IAM Identity Center user provisioning, and an approval workflow for unlisted domains.

**Key Capabilities:**
- Self-service account creation with email validation
- Automated domain verification against UK public sector domain allowlist
- Cross-account user provisioning in IAM Identity Center (ISB account)
- Manual approval workflow for unlisted domains
- GOV.UK Notify email notifications
- Slack alerting for operators
- CSRF protection and rate limiting

**Technology Stack:** TypeScript, Node.js 20, AWS Lambda Function URLs, IAM Identity Center, EventBridge, GOV.UK Notify

**Integration Points:** ukps-domains (GitHub), ISB IAM Identity Center, GOV.UK Notify, Slack (AWS Chatbot)

**Status:** Production (Alpha phase)

---

## Architecture Overview

### End-to-End Flow Diagram

```mermaid
sequenceDiagram
    participant User as User Browser
    participant Website as NDX Website<br/>(Static HTML)
    participant CF as CloudFront
    participant Lambda as Signup Lambda<br/>(Function URL)
    participant DomainSvc as Domain Service<br/>(GitHub API)
    participant ISB as ISB Account<br/>IAM Identity Center
    participant Notify as GOV.UK Notify
    participant Slack as Slack<br/>(AWS Chatbot)

    User->>Website: Visit /signup
    Website->>User: Display signup form

    User->>User: Fill form (name, email, org)
    User->>Website: Submit form

    Website->>Website: Validate client-side
    Website->>CF: POST /signup-api/signup<br/>X-Requested-With: XMLHttpRequest

    CF->>Lambda: Forward request (OAC signed)

    Lambda->>Lambda: Validate CSRF header
    Lambda->>Lambda: Validate input schema

    Lambda->>DomainSvc: Check email domain
    DomainSvc->>DomainSvc: Fetch ukps-domains (cached 5min)

    alt Domain in allowlist
        DomainSvc-->>Lambda: Domain approved

        Lambda->>ISB: STS AssumeRole<br/>(cross-account)
        ISB-->>Lambda: Temporary credentials

        Lambda->>ISB: Check if user exists<br/>identitystore:ListUsers

        alt User already exists
            ISB-->>Lambda: User found
            Lambda-->>Website: 409 Conflict<br/>"Account already exists"
            Website->>User: Show error
        else User does not exist
            ISB-->>Lambda: User not found

            Lambda->>ISB: CreateUser<br/>identitystore:CreateUser
            ISB-->>Lambda: User created (userId)

            Lambda->>ISB: Add to group<br/>identitystore:CreateGroupMembership
            ISB-->>Lambda: Membership created

            Lambda->>Notify: Send welcome email<br/>(via API)
            Lambda->>Slack: Post alert

            Lambda-->>Website: 200 OK<br/>{"status": "approved"}
            Website->>User: Redirect to /signup/success
            User->>User: Check email for next steps
        end

    else Domain not in allowlist
        DomainSvc-->>Lambda: Domain unlisted

        Lambda->>Slack: Post alert: Manual review
        Lambda-->>Website: 202 Accepted<br/>{"status": "pending_approval"}
        Website->>User: Show message: Request submitted

    else Invalid domain
        DomainSvc-->>Lambda: Invalid domain
        Lambda-->>Website: 400 Bad Request
        Website->>User: Show error
    end
```

---

## Related Documentation

- [30-ndx-website.md](30-ndx-website.md) - Main website architecture
- [00-repo-inventory.md](00-repo-inventory.md) - Repository overview
- [10-isb-core-architecture.md](10-isb-core-architecture.md) - ISB integration

---

## Source Files Referenced

| File Path | Purpose |
|-----------|---------|
| `/repos/ndx/src/signup/main.ts` | Frontend entry point |
| `/repos/ndx/infra-signup/lib/lambda/signup/handler.ts` | Lambda handler |
| `/repos/ndx/infra-signup/lib/lambda/signup/domain-service.ts` | Domain validation |
| `/repos/ndx/infra-signup/lib/signup-stack.ts` | CDK stack |

---

**Document Version:** 1.0
**Last Updated:** 2026-02-03
**Status:** Production (Alpha Phase)
