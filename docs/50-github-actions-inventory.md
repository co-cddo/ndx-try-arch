# GitHub Actions Workflow Inventory

**Document Version:** 1.0
**Date:** 2026-02-03
**Scope:** Complete catalog of CI/CD workflows across 12 NDX:Try AWS repositories

---

## Executive Summary

The NDX:Try AWS ecosystem uses GitHub Actions for automated CI/CD across 7 of 12 repositories, with 14 distinct workflow files implementing continuous integration, deployment, testing, and security scanning. The workflows leverage GitHub OIDC (OpenID Connect) for secure, credential-less AWS deployments, replacing traditional IAM access keys.

**Key Findings:**
- 14 total workflow files across 7 repositories
- 5 repositories lack CI/CD automation (manual deployment)
- OIDC authentication used in 100% of deployment workflows
- Mixed deployment strategies: auto-deploy on merge, manual approval gates, and PR-based validation
- Strong security posture with OpenSSF Scorecard, dependency scanning, and fork protection

---

## Workflow Catalog

### Repository: innovation-sandbox-on-aws-approver

#### 1. deploy.yml - Approver Deployment Pipeline

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/deploy.yml` |
| **Purpose** | Build, test, and deploy the ISB Approver Lambda function |
| **Triggers** | `push` (main), `pull_request` (main), `merge_group` |
| **Region** | us-west-2 |
| **Node Version** | 20 |

**Workflow Steps:**
1. Checkout code
2. Setup Node.js 20
3. Install dependencies (with Rollup Linux platform workaround)
4. Build TypeScript
5. Run linting
6. Run typecheck
7. Run tests with coverage
8. **[Push only]** Configure AWS credentials via OIDC
9. **[Push only]** Deploy CDK stacks with `--require-approval never`

**OIDC Configuration:**
```yaml
role-to-assume: arn:aws:iam::568672915267:role/GitHubActions-Approver-InfraDeploy
aws-region: us-west-2
```

**Permissions:**
- `id-token: write` - Required for OIDC authentication
- `contents: read` - Repository checkout

**Special Notes:**
- Workaround for Rollup platform-specific dependency issue (npm issue #4828)
- Auto-deploys to production on merge to main (no manual approval)

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/innovation-sandbox-on-aws-approver/.github/workflows/deploy.yml`

---

### Repository: innovation-sandbox-on-aws-billing-seperator

#### 2. deploy.yml - Billing Separator Manual Deployment

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/deploy.yml` |
| **Purpose** | Deploy ISB Billing Separator CDK stacks (TEMPORARY WORKAROUND) |
| **Triggers** | `workflow_dispatch` (manual only), `push` (main, validation only) |
| **Region** | eu-west-2 (configurable) |
| **Node Version** | 22 |

**Job Structure:**

**Job 1: validate** (always runs on push to main)
- Checkout with submodules
- Install dependencies
- Lint
- Tests (CI mode)
- Build
- CDK synth (dry-run validation with test context)

**Job 2: deploy** (manual trigger only)
- Requires manual workflow_dispatch
- Supports dev/prod environments
- Requires GitHub environment protection
- Secrets: `AWS_ROLE_ARN`, Variables: `AWS_REGION`

**OIDC Configuration:**
```yaml
role-to-assume: ${{ secrets.AWS_ROLE_ARN }}  # Per-environment secret
aws-region: ${{ vars.AWS_REGION || 'eu-west-2' }}
```

**CDK Context (Test Synth):**
```bash
-c environment=test
-c hubAccountId=123456789012
-c orgMgmtAccountId=098765432109
-c accountTableName=isb-sandbox-accounts
-c sandboxOuId=ou-test-sandbox
-c availableOuId=ou-test-available
-c quarantineOuId=ou-test-quarantine
-c cleanupOuId=ou-test-cleanup
-c intermediateRoleArn=arn:aws:iam::123456789012:role/isb-hub-role
-c orgMgtRoleArn=arn:aws:iam::098765432109:role/isb-org-mgt-role
```

**Deployment Summary:**
- Creates GitHub Actions summary with outputs
- Uploads CDK outputs as artifacts (30-day retention)

**Special Notes:**
- **This repository is marked for archival** (see issue #70 in ISB)
- Manual-only deployment prevents accidental production changes
- Comprehensive test context for CDK synth validation

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/innovation-sandbox-on-aws-billing-seperator/.github/workflows/deploy.yml`

---

#### 3. pr-check.yml - Billing Separator PR Validation

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/pr-check.yml` |
| **Purpose** | Validate pull requests before merge |
| **Triggers** | `pull_request` (main), `merge_group` |
| **Node Version** | 22 |

**Validation Steps:**
1. Checkout with submodules (ISB submodule required)
2. Install dependencies
3. Lint
4. Tests (CI mode)
5. Build
6. CDK synth with test context (same as deploy.yml)

**Permissions:** `contents: read` only (no AWS access)

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/innovation-sandbox-on-aws-billing-seperator/.github/workflows/pr-check.yml`

---

### Repository: innovation-sandbox-on-aws-costs

#### 4. ci.yml - Cost Collection CI Pipeline

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/ci.yml` |
| **Purpose** | Continuous integration for cost collection service |
| **Triggers** | `push` (all branches), `pull_request` (main) |
| **Node Version** | 22 |

**CI Steps:**
1. Checkout
2. Install dependencies
3. Lint
4. Tests (CI mode)
5. Build
6. CDK Synth validation (with test context)
7. **[PR only]** Upload coverage to Codecov

**Test CDK Context:**
```bash
--context eventBusName=test-bus
--context costExplorerRoleArn=arn:aws:iam::123456789012:role/test
--context isbLeasesLambdaArn=arn:aws:lambda:us-west-2:123456789012:function:test
```

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/innovation-sandbox-on-aws-costs/.github/workflows/ci.yml`

---

#### 5. deploy.yml - Cost Collection Manual Deployment

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/deploy.yml` |
| **Purpose** | Deploy cost collection Lambda to production |
| **Triggers** | `workflow_dispatch` (manual only) |
| **Region** | us-west-2 |
| **Node Version** | 22 |
| **Environment** | production (GitHub environment) |

**Deployment Workflow:**
1. Branch check (main only)
2. Lint + Tests
3. Build
4. Configure AWS credentials (OIDC)
5. CDK Deploy with runtime context

**OIDC Configuration:**
```yaml
role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
aws-region: us-west-2
```

**CDK Context (Production):**
```bash
--context eventBusName=${{ vars.EVENT_BUS_NAME }}
--context costExplorerRoleArn=${{ secrets.COST_EXPLORER_ROLE_ARN }}
--context isbLeasesLambdaArn=${{ secrets.ISB_LEASES_LAMBDA_ARN }}
--context alertEmail=${{ vars.ALERT_EMAIL }}
```

**Secrets & Variables:**
- Secrets: `AWS_ROLE_ARN`, `COST_EXPLORER_ROLE_ARN`, `ISB_LEASES_LAMBDA_ARN`
- Variables: `EVENT_BUS_NAME`, `ALERT_EMAIL`

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/innovation-sandbox-on-aws-costs/.github/workflows/deploy.yml`

---

### Repository: innovation-sandbox-on-aws-deployer

#### 6. ci.yml - Deployer CI/CD Pipeline

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/ci.yml` |
| **Purpose** | Complete CI/CD for ISB Deployer Lambda (container-based) |
| **Triggers** | `push` (main), `pull_request`, `merge_group`, `workflow_dispatch` |
| **Region** | us-west-2 |
| **Node Version** | 22 |

**Job Structure:**

**Job 1: lint** - ESLint and formatting checks
**Job 2: typecheck** - TypeScript type validation
**Job 3: test** - Unit tests with Codecov coverage upload
**Job 4: build** - Multi-platform Docker build (ARM64)
- Builds Lambda container image
- Uses GitHub Actions cache
- Uploads image as artifact (1-day retention)

**Job 5: deploy** (main branch only)
- Requires: production environment approval
- Loads Docker image from artifact
- Configures AWS credentials (OIDC)
- Pushes to ECR with SHA and latest tags
- Deploys CDK stack with image tag
- Waits for Lambda update completion

**Container Build:**
```yaml
Platforms: linux/arm64
Context: .
Dockerfile: infrastructure/docker/Dockerfile
Cache: GitHub Actions cache
Tags:
  - isb-deployer:${github.sha}
  - isb-deployer:latest
```

**ECR Push:**
```yaml
Registry: ${{ steps.login-ecr.outputs.registry }}
Repository: isb-deployer-prod
Tags:
  - ${IMAGE_TAG}
  - latest
```

**OIDC Configuration:**
```yaml
role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
aws-region: us-west-2
```

**CDK Deployment:**
```bash
npx cdk deploy DeployerStack \
  --require-approval never \
  -c imageTag=${{ github.sha }}
```

**Special Features:**
- ARM64 Lambda for cost optimization
- Container-based deployment (not ZIP)
- Image tag tracking with Git SHA
- Lambda update wait to ensure deployment completion

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/innovation-sandbox-on-aws-deployer/.github/workflows/ci.yml`

---

### Repository: ndx_try_aws_scenarios

#### 7. build-deploy.yml - Scenarios Website Build & Deploy

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/build-deploy.yml` |
| **Purpose** | Build Eleventy static site and deploy to GitHub Pages |
| **Triggers** | `push` (main), `pull_request`, `merge_group`, `workflow_dispatch` |
| **Node Version** | 20 |
| **Deployment Target** | GitHub Pages |

**Job Structure:**

**Job 1: validate-schema**
- Validates scenarios.yaml schema
- Ensures scenario definitions are valid

**Job 2: build**
- Builds Eleventy site with production URL
- Uploads build artifact
- Uploads Pages artifact (main branch only)

**Job 3: accessibility**
- Downloads build artifact
- Runs pa11y-ci accessibility tests
- Reports issues as warnings (non-blocking)

**Job 4: lighthouse**
- Runs Lighthouse CI for performance auditing

**Job 5: deploy** (main branch only)
- Deploys to GitHub Pages
- Uses GitHub Pages deployment action

**GitHub Pages URL:**
```
https://aws.try.ndx.digital.cabinet-office.gov.uk
```

**Accessibility Testing:**
```bash
pa11y-ci --config .pa11yci.json
```

**Permissions:**
- `contents: read`
- `pages: write` (deployment job)
- `id-token: write` (OIDC for Pages)

**Concurrency:** Single deployment at a time (cancel-in-progress: false)

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/ndx_try_aws_scenarios/.github/workflows/build-deploy.yml`

---

#### 8. docker-build.yml - LocalGov Drupal Container Build

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/docker-build.yml` |
| **Purpose** | Build and publish LocalGov Drupal container to GHCR |
| **Triggers** | `push` (main, path filters), `pull_request`, `workflow_dispatch` |
| **Registry** | ghcr.io |
| **Image** | co-cddo/ndx_try_aws_scenarios-localgov_drupal |

**Path Filters (main branch only):**
```yaml
- 'cloudformation/scenarios/localgov-drupal/docker/**'
- 'cloudformation/scenarios/localgov-drupal/drupal/**'
- 'cloudformation/scenarios/localgov-drupal/.dockerignore'
- '.github/workflows/docker-build.yml'
```

**Job Structure:**

**Job 1: changes** (PR only)
- Detects if Docker-related files changed
- Skips build if no relevant changes

**Job 2: build**
- Runs on: push to main, PR with Docker changes, or manual dispatch
- Builds multi-platform image (linux/amd64)
- Pushes to GHCR on main branch

**Docker Tags:**
```yaml
- type=sha,prefix=sha-         # sha-abc123
- type=raw,value=latest        # latest (main only)
- type=ref,event=branch        # branch name (non-main)
```

**Docker Build Context:**
```yaml
Context: cloudformation/scenarios/localgov-drupal
Dockerfile: cloudformation/scenarios/localgov-drupal/docker/Dockerfile
Platforms: linux/amd64
Cache: GitHub Actions cache
```

**Permissions:**
- `contents: read`
- `packages: write` (for GHCR push)

**Special Notes:**
- Conditional push based on branch and workflow input
- Uses GitHub Actions cache for layer caching
- Outputs build summary to GitHub Actions UI

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/ndx_try_aws_scenarios/.github/workflows/docker-build.yml`

---

### Repository: ndx-try-aws-scp

#### 9. terraform.yaml - Terraform SCP Management

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/terraform.yaml` |
| **Purpose** | Manage 5-layer cost defense system with Terraform |
| **Triggers** | `push` (main), `pull_request`, `merge_group`, `workflow_dispatch` |
| **Terraform Version** | 1.7.0 |
| **Region** | eu-west-2 |
| **Working Directory** | environments/ndx-production |

**Job Structure:**

**Job 1: test** - Python tests for validation scripts
- Python 3.11
- pytest for infrastructure tests

**Job 2: plan** - Terraform plan (PRs and pushes)
- Fork protection: `pull_request.head.repo.fork == false`
- Terraform format check
- Init, validate, plan
- Comments plan on PR (truncated to 60k chars)
- Uploads plan artifact (5-day retention)

**Job 3: apply** - Terraform apply (manual only)
- **MANUAL ONLY** - `workflow_dispatch` with action='apply'
- Requires production environment approval
- Downloads plan artifact
- Applies with `-auto-approve`

**Environment Variables (Cost Defense Layers):**

**Layer 1: Service Control Policies**
```yaml
TF_VAR_sandbox_ou_id: ou-2laj-4dyae1oa
TF_VAR_namespace: ndx
TF_VAR_managed_regions: '["us-east-1", "us-west-2"]'
TF_VAR_enable_cost_avoidance: "true"
TF_VAR_cost_avoidance_ou_id: ou-2laj-sre4rnjs
```

**Layer 2: Service Quotas**
```yaml
TF_VAR_enable_service_quotas: "true"
TF_VAR_ec2_vcpu_quota: "64"
TF_VAR_ebs_storage_quota_tib: "1"
TF_VAR_lambda_concurrency_quota: "100"
TF_VAR_rds_instance_quota: "5"
TF_VAR_rds_storage_quota_gb: "500"
```

**Layer 3: AWS Budgets**
```yaml
TF_VAR_enable_budgets: "true"
TF_VAR_sandbox_pool_ou_id: ou-2laj-sre4rnjs
TF_VAR_daily_budget_limit: "50"
TF_VAR_monthly_budget_limit: "1000"
TF_VAR_enable_service_budgets: "true"
```

**OIDC Configuration:**
```yaml
role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
aws-region: eu-west-2
```

**Security Features:**
- Harden Runner (Step Security)
- Egress policy: audit
- Fork blocking at workflow and IAM level
- Manual apply only (prevents auto-deployment)

**Special Notes:**
- Manages cost defense for 24-hour sandbox leases
- Region restriction: Only US regions allowed (eu-west-2 forbidden)
- Budget emails sent to Slack webhook
- Plan output saved to file to avoid "argument list too long" errors

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/ndx-try-aws-scp/.github/workflows/terraform.yaml`

---

### Repository: ndx

#### 10. accessibility.yml - WCAG 2.2 AA Compliance Testing

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/accessibility.yml` |
| **Purpose** | Mandatory accessibility testing gate (ADR-037) |
| **Triggers** | `push` (main), `pull_request`, `merge_group` |
| **Node Version** | 22 |
| **Timeout** | 10 minutes |

**Job 1: accessibility** - WCAG 2.2 AA Compliance
- Build site with Yarn
- Start local HTTP server (port 8080)
- Run pa11y-ci with zero tolerance
- Upload accessibility report on failure (30-day retention)

**Job 2: lighthouse** - Lighthouse Accessibility Audit
- Separate Lighthouse CI run
- Performance and accessibility metrics
- Temporary public storage for reports

**Zero Tolerance Policy:**
- PR blocked if ANY WCAG 2.2 AA violations detected
- No accessibility regressions allowed

**Permissions:** `read-all`

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/ndx/.github/workflows/accessibility.yml`

---

#### 11. ci.yaml - NDX Frontend CI/CD Pipeline

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/ci.yaml` |
| **Purpose** | Build, test, and deploy NDX website to S3/CloudFront |
| **Triggers** | `push` (main, tags), `pull_request`, `merge_group`, `workflow_dispatch` |
| **Region** | us-west-2 |
| **S3 Bucket** | ndx-static-prod |
| **CloudFront ID** | E3THG4UHYDHVWP |

**Job Structure:**

**Job 1: build**
- Path filter: Skip if only `infra/**` or `docs/**` changed
- Lint + Build
- Upload site artifact

**Job 2: test-unit** - Jest unit tests

**Job 3: test-e2e** - Playwright E2E tests
- Sharded across 2 runners
- Parallel execution
- Upload reports on failure

**Job 4: test-a11y** - Playwright accessibility tests
- Sharded across 2 runners
- Separate from E2E for granularity

**Job 5: deploy-s3** (main branch only)
- Requires: build, test-unit, test-e2e, test-a11y
- Environment: production
- OIDC authentication

**S3 Deployment:**
```bash
aws s3 sync ./_site/ s3://ndx-static-prod/ \
  --delete \
  --exact-timestamps \
  --cache-control "public, max-age=3600" \
  --exclude ".DS_Store"
```

**CloudFront Invalidation:**
```bash
aws cloudfront create-invalidation \
  --distribution-id E3THG4UHYDHVWP \
  --paths "/*"
```

**OIDC Configuration:**
```yaml
role-to-assume: arn:aws:iam::568672915267:role/GitHubActions-NDX-ContentDeploy
aws-region: us-west-2
```

**Job 6: semver** - Semantic version generation
- Uses lukaszraczylo/semver-generator
- Config: `.github/semver.yaml`

**Security:**
- Harden Runner on all jobs
- Pinned action SHAs
- Path-based deployment filtering

**Production URL:**
```
https://ndx.digital.cabinet-office.gov.uk
```

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/ndx/.github/workflows/ci.yaml`

---

#### 12. infra.yaml - NDX Infrastructure Deployment

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/infra.yaml` |
| **Purpose** | Deploy NDX CDK infrastructure and signup Lambda |
| **Triggers** | `push` (main), `pull_request`, `merge_group`, `workflow_dispatch` |
| **Region** | us-west-2 |
| **Node Version** | 20.17.0 |

**Job Structure:**

**Section 1: Main Infrastructure (infra/)**

**Job 1: infra-unit-tests**
- Path filter: `infra/**` or workflow file
- Lint + Unit tests
- Outputs: infra-changed

**Job 2: infra-e2e-tests** (DISABLED)
- Temporarily disabled due to AWS SDK compatibility issue
- Would run GOV.UK Notify E2E tests

**Job 3: cdk-diff** (PR only, non-forks)
- Fork protection: Explicit check + IAM-level enforcement
- Uses readonly diff role: `GitHubActions-NDX-InfraDiff`
- Comments PR with CDK diff
- Filters out expected warnings from readonly role

**Job 4: cdk-deploy** (main branch only)
- Environment: infrastructure
- Uses deploy role: `GitHubActions-NDX-InfraDeploy`
- Pre-deploy validation (build, test, lint, synth)
- Deploy all stacks
- Upload CDK outputs (30-day retention)

**Section 2: Signup Infrastructure (infra-signup/)**

**Job 5: signup-infra-unit-tests**
- Path filter: `infra-signup/**`
- Lint + Unit tests

**Job 6: signup-cdk-deploy** (main branch only)
- Deploys signup Lambda to NDX account (568672915267)
- Uses same InfraDeploy role

**Job 7: isb-cross-account-role-deploy** (main branch only)
- Deploys to ISB account (955063685555)
- Environment: isb-infrastructure
- Uses CloudFormation directly (not CDK)

**Cross-Account CloudFormation Deploy:**
```bash
aws cloudformation deploy \
  --template-file infra-signup/isb-cross-account-role.yaml \
  --stack-name ndx-signup-cross-account-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides GroupId=${{ secrets.ISB_NDX_USERS_GROUP_ID }}
```

**OIDC Roles:**
- NDX Account: `arn:aws:iam::568672915267:role/GitHubActions-NDX-InfraDeploy`
- ISB Account: `arn:aws:iam::955063685555:role/GitHubActions-ISB-InfraDeploy`
- Readonly (diff): `arn:aws:iam::568672915267:role/GitHubActions-NDX-InfraDiff`

**Fork Protection:**
```yaml
if: github.event.pull_request.head.repo.fork == false
```

**Security:**
- Harden Runner
- Fork blocking (workflow + IAM)
- Separate readonly role for diffs
- Environment protection on deployments

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/ndx/.github/workflows/infra.yaml`

---

#### 13. scorecard.yml - OpenSSF Scorecard Security Scan

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/scorecard.yml` |
| **Purpose** | Supply-chain security scanning |
| **Triggers** | `branch_protection_rule`, `schedule` (weekly), `push` (main) |
| **Schedule** | Sunday 04:23 UTC |

**Security Checks:**
- Branch protection
- Dependency scanning
- Code review enforcement
- Security policy presence
- Dangerous workflow patterns

**Outputs:**
- SARIF file uploaded to Code Scanning dashboard
- Results published to OpenSSF REST API
- Artifact uploaded (5-day retention)

**Permissions:**
- `security-events: write` (Code Scanning upload)
- `id-token: write` (OpenSSF publishing)

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/ndx/.github/workflows/scorecard.yml`

---

#### 14. test.yml - NDX Frontend Tests

| Property | Value |
|----------|-------|
| **File** | `.github/workflows/test.yml` |
| **Purpose** | Frontend and signup Lambda unit tests |
| **Triggers** | `push` (main), `pull_request`, `merge_group` |
| **Node Version** | 20.17.0 |

**Test Coverage:**

**Frontend Tests:**
- Path filter: Excludes `infra/**`, `infra-signup/**`, `docs/**`
- Unit tests with Yarn
- Playwright browser installation
- mitmproxy setup for E2E (currently disabled)

**Signup Tests:**
- Path filter: `infra-signup/**`
- Separate test run in infra-signup directory

**Disabled Tests:**
- E2E tests (proxy configuration issues)
- Accessibility E2E tests

**Artifact Upload:**
- Playwright reports on failure (7-day retention)

**Source File:** `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/ndx/.github/workflows/test.yml`

---

## Summary Tables

### Workflow Distribution by Repository

| Repository | Workflow Count | Purpose |
|-----------|----------------|---------|
| ndx | 5 | CI, infra, accessibility, scorecard, tests |
| innovation-sandbox-on-aws-approver | 1 | Deploy |
| innovation-sandbox-on-aws-billing-seperator | 2 | Deploy, PR check |
| innovation-sandbox-on-aws-costs | 2 | CI, deploy |
| innovation-sandbox-on-aws-deployer | 1 | CI/CD |
| ndx_try_aws_scenarios | 2 | Build/deploy, Docker |
| ndx-try-aws-scp | 1 | Terraform |
| **Total** | **14** | |

### Repositories Without Workflows

| Repository | Deployment Method |
|-----------|-------------------|
| innovation-sandbox-on-aws | Manual CDK deployment |
| innovation-sandbox-on-aws-utils | Manual Python script execution |
| ndx-try-aws-isb | Empty placeholder |
| ndx-try-aws-lza | Manual LZA updates via AWS Console |
| ndx-try-aws-terraform | Manual Terraform apply |

### Trigger Types

| Trigger | Count | Workflows |
|---------|-------|-----------|
| `push` (main) | 12 | All except manual-only |
| `pull_request` | 11 | Most workflows |
| `merge_group` | 9 | Modern merge queue support |
| `workflow_dispatch` | 6 | Manual triggers |
| `schedule` | 1 | Scorecard (weekly) |
| `branch_protection_rule` | 1 | Scorecard |

### Deployment Strategies

| Strategy | Count | Repositories |
|----------|-------|-------------|
| Auto-deploy on merge | 5 | approver, deployer, ndx (content), ndx (infra), scenarios |
| Manual approval required | 3 | billing-separator, costs, scp |
| No automation | 5 | isb, utils, lza, terraform, isb-empty |

### Authentication Methods

| Method | Count | Workflows |
|--------|-------|-----------|
| GitHub OIDC | 8 | All deployment workflows |
| GitHub Token | 2 | Docker (GHCR), Scorecard |
| None (no AWS) | 4 | PR checks, tests |

---

## OIDC Role Mapping

```mermaid
flowchart TB
    subgraph "GitHub Repositories"
        approver[innovation-sandbox-on-aws-approver]
        billing[innovation-sandbox-on-aws-billing-seperator]
        costs[innovation-sandbox-on-aws-costs]
        deployer[innovation-sandbox-on-aws-deployer]
        ndx_repo[ndx]
        scp[ndx-try-aws-scp]
    end

    subgraph "AWS Account: 568672915267 (Hub)"
        role1[GitHubActions-Approver-InfraDeploy]
        role2[GitHubActions-NDX-ContentDeploy]
        role3[GitHubActions-NDX-InfraDeploy]
        role4[GitHubActions-NDX-InfraDiff]
    end

    subgraph "AWS Account: 955063685555 (ISB/Org)"
        role5[GitHubActions-ISB-InfraDeploy]
        role6[Cost Defense Role]
    end

    approver -->|OIDC| role1
    deployer -->|OIDC| role1
    costs -->|OIDC| role1
    billing -->|OIDC| role1

    ndx_repo -->|Content Deploy| role2
    ndx_repo -->|Infra Deploy| role3
    ndx_repo -->|Infra Diff (PR)| role4
    ndx_repo -->|ISB Cross-Account| role5

    scp -->|OIDC| role6
```

---

## Environment Variables & Secrets Catalog

### GitHub Secrets (per repository)

**innovation-sandbox-on-aws-billing-seperator:**
- `AWS_ROLE_ARN` - IAM role for deployment

**innovation-sandbox-on-aws-costs:**
- `AWS_ROLE_ARN` - IAM role for deployment
- `COST_EXPLORER_ROLE_ARN` - Cross-account Cost Explorer access
- `ISB_LEASES_LAMBDA_ARN` - ISB Leases Lambda for JWT auth

**innovation-sandbox-on-aws-deployer:**
- `AWS_DEPLOY_ROLE_ARN` - IAM role for ECR/Lambda deployment

**ndx:**
- `ISB_NDX_USERS_GROUP_ID` - Identity Center group ID for signup

**ndx-try-aws-scp:**
- `AWS_ROLE_ARN` - IAM role for Terraform
- `SLACK_BUDGET_ALERT_EMAIL` - Budget alert notification email

### GitHub Variables (per repository)

**innovation-sandbox-on-aws-billing-seperator:**
- `AWS_REGION` - Target region (default: eu-west-2)

**innovation-sandbox-on-aws-costs:**
- `EVENT_BUS_NAME` - EventBridge bus name
- `ALERT_EMAIL` - Alert notification email

---

## Workflow Best Practices Observed

### Security

1. **OIDC Over Access Keys** - 100% of AWS deployments use temporary credentials
2. **Fork Protection** - Explicit checks preventing fork PRs from accessing AWS
3. **Pinned Action Versions** - SHA-pinned actions in ndx repository
4. **Harden Runner** - Step Security hardening on critical workflows
5. **Least Privilege** - Separate roles for diff (readonly) vs deploy
6. **Secret Scoping** - Per-environment secrets with GitHub Environments

### Performance

1. **Path Filtering** - Skip builds when irrelevant files change
2. **Test Sharding** - Playwright tests split across 2 runners
3. **GitHub Actions Cache** - Docker layer and dependency caching
4. **Artifact Reuse** - Build once, test/deploy from artifacts

### Reliability

1. **Manual Approval Gates** - Critical infrastructure changes require workflow_dispatch
2. **Dry-Run Validation** - CDK synth before deployment
3. **Wait for Completion** - Lambda update waits ensure deployment success
4. **Deployment Summaries** - GitHub Actions summaries for visibility

### Testing

1. **Multi-Layer Testing** - Lint, typecheck, unit, E2E, accessibility
2. **Coverage Tracking** - Codecov integration on multiple repos
3. **Accessibility First** - Zero tolerance WCAG 2.2 AA policy
4. **Pre-Commit Checks** - Format, lint, test before merge

---

## Related Documents

- [04-cross-account-trust.md](./04-cross-account-trust.md) - IAM roles and OIDC provider
- [51-oidc-configuration.md](./51-oidc-configuration.md) - Detailed OIDC architecture
- [52-deployment-flows.md](./52-deployment-flows.md) - Per-repo deployment flows
- [53-manual-operations.md](./53-manual-operations.md) - Non-automated operations

---

**Source Files:**
- All workflow files: `/Users/cns/httpdocs/cddo/ndx-try-arch/repos/*/github/workflows/*.yml`
- Repository inventory: `/Users/cns/httpdocs/cddo/ndx-try-arch/docs/00-repo-inventory.md`
