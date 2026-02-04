# Terraform Resources (Organization Management)

## Executive Summary

The `ndx-try-aws-terraform` repository contains minimal Terraform configuration for NDX organization-level resources that don't fit into LZA or ISB. Currently provisions S3 bucket for Terraform state and billing IAM role.

**Key Resources:**
- S3 bucket for remote Terraform state (encrypted, versioned)
- IAM role for billing access (MFA-required, IP-restricted)
- Organization read-only access for specific GDS users

**Technology:** Terraform

**Status:** Production (minimal scope)

---

## Architecture

```mermaid
graph TB
    subgraph "Terraform State"
        S3[S3 Bucket<br/>ndx-try-tf-state<br/>KMS encrypted]
        KMS[KMS Key]
    end

    subgraph "Billing Access"
        ROLE[IAM Role<br/>billing-access]
        POLICY[IAM Policy<br/>billing-readonly]
    end

    subgraph "GDS Users"
        USER1[david.heath@digital.cabinet-office.gov.uk]
        USER2[stephen.grier@digital.cabinet-office.gov.uk]
        USER3[thomas.vaughan@digital.cabinet-office.gov.uk]
    end

    USER1 -->|STS AssumeRole<br/>MFA required<br/>IP restricted| ROLE
    USER2 -->|STS AssumeRole<br/>MFA required<br/>IP restricted| ROLE
    USER3 -->|STS AssumeRole<br/>MFA required<br/>IP restricted| ROLE
    
    ROLE --> POLICY
    POLICY -->|Read| BILLING[AWS Billing Console]
    POLICY -->|Read| CE[Cost Explorer]
    POLICY -->|Read| ORGS[Organizations]
```

---

## Resources Managed

### 1. Terraform State S3 Bucket

**Resource:** `aws_s3_bucket.ndx_try_tf_state`

**Configuration:**
```hcl
resource "aws_s3_bucket" "ndx_try_tf_state" {
  bucket = "ndx-try-tf-state"
}

resource "aws_s3_bucket_versioning" "ndx_try_tf_state_versioning" {
  bucket = aws_s3_bucket.ndx_try_tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ndx_try_tf_state_encryption" {
  bucket = aws_s3_bucket.ndx_try_tf_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.ndx_try_tf_state_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
```

**Security Features:**
- KMS encryption with dedicated key
- Versioning enabled (rollback capability)
- Private ACL (no public access)
- Object ownership controls

### 2. Billing IAM Role

**Resource:** `aws_iam_role.billing`

**Assume Role Policy:**
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": [
      "arn:aws:iam::622626885786:user/david.heath@digital.cabinet-office.gov.uk",
      "arn:aws:iam::622626885786:user/stephen.grier@digital.cabinet-office.gov.uk",
      "arn:aws:iam::622626885786:user/thomas.vaughan@digital.cabinet-office.gov.uk"
    ]
  },
  "Action": "sts:AssumeRole",
  "Condition": {
    "Bool": {
      "aws:MultiFactorAuthPresent": "true"
    },
    "IpAddress": {
      "aws:SourceIp": [
        "217.196.229.77/32",  # GovWifi
        "217.196.229.79/32",  # Brattain
        "217.196.229.80/32",  # GDS BYOD VPN
        "217.196.229.81/32",  # GDS VPN
        "51.149.8.0/25",      # GDS/CO VPN
        "51.149.8.128/29"     # GDS BYOD VPN
      ]
    }
  }
}
```

**Attached Policies:**
- `billing-readonly` (custom policy)
- `AWSOrganizationsReadOnlyAccess` (AWS managed)
- `AWSBillingReadOnlyAccess` (AWS managed)

**Permissions:**
- View billing console
- View payment methods
- View usage reports
- List Cost Explorer data
- Describe Cost and Usage Report (CUR)
- List organization tags

---

## Relationship to Other IaC

### vs. LZA (ndx-try-aws-lza)

**LZA Manages:**
- Organizational structure (OUs)
- Accounts (mandatory and workload)
- SCPs (security guardrails)
- Control Tower configuration
- Baseline security (Config, GuardDuty, Security Hub)

**Terraform Manages:**
- Org-level resources not in LZA scope
- Billing access delegation
- Terraform state storage

**No Overlap:** LZA and this Terraform repo are complementary.

### vs. Terraform SCP (ndx-try-aws-scp)

**ndx-try-aws-scp Manages:**
- Cost defense SCPs
- Service quotas
- AWS Budgets
- DynamoDB billing enforcer

**ndx-try-aws-terraform Manages:**
- Organization-level utilities
- Billing access

**No Overlap:** Different purposes, no resource conflicts.

### vs. ISB CDK Stacks

**ISB Manages:**
- Innovation Sandbox application (Lambda, DynamoDB, Step Functions)
- Satellite services (Approver, Deployer, Costs, Billing Separator)

**Terraform Manages:**
- Organization-level resources

**No Overlap:** Different accounts, different scopes.

---

## Deployment

```bash
cd /path/to/ndx-try-aws-terraform

terraform init
terraform plan
terraform apply
```

**State Backend:** Local (chicken-and-egg problem)

**Future:** Migrate to S3 backend once bucket exists:
```hcl
terraform {
  backend "s3" {
    bucket = "ndx-try-tf-state"
    key    = "org/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
    kms_key_id = "alias/ndx-try-tf-state"
  }
}
```

---

## Usage: Billing Access

### Assume Role

```bash
# Configure AWS CLI with GDS user credentials
export AWS_PROFILE=gds-user

# Assume billing role (requires MFA)
aws sts assume-role \
  --role-arn arn:aws:iam::MANAGEMENT_ACCOUNT:role/billing-access \
  --role-session-name billing-session \
  --serial-number arn:aws:iam::622626885786:mfa/david.heath \
  --token-code 123456

# Set environment variables from assume-role output
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

# Access billing console
aws ce get-cost-and-usage \
  --time-period Start=2026-02-01,End=2026-02-03 \
  --granularity DAILY \
  --metrics BlendedCost
```

---

## Related Documentation

- [40-lza-configuration.md](40-lza-configuration.md) - LZA organization structure
- [41-terraform-scp.md](41-terraform-scp.md) - Cost defense Terraform
- [00-repo-inventory.md](00-repo-inventory.md) - Repository overview

---

## Source Files Referenced

| File Path | Purpose |
|-----------|---------|
| `/repos/ndx-try-aws-terraform/main.tf` | Main Terraform configuration |
| `/repos/ndx-try-aws-terraform/terraform.tf` | Provider and backend config |

---

**Document Version:** 1.0
**Last Updated:** 2026-02-03
**Status:** Production (minimal scope)
