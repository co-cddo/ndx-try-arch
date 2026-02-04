# Issues Discovered

**Document Version:** 1.0
**Date:** 2026-02-03
**Status:** Living document - updated throughout analysis phases

---

## Executive Summary

This document catalogs all issues, inconsistencies, potential problems, and improvement recommendations discovered during the NDX:Try AWS architecture archaeology project. Issues are documented but NOT fixed - this is a read-only discovery exercise.

---

## Issue Severity Ratings

| Severity | Description |
|----------|-------------|
| 🔴 Critical | Security vulnerability, data loss risk, or system outage potential |
| 🟠 High | Significant operational impact or compliance concern |
| 🟡 Medium | Technical debt, inconsistency, or moderate risk |
| 🟢 Low | Documentation gap, naming inconsistency, or minor improvement |

---

## Issues by Phase

### Phase 1: Repository Discovery

| ID | Severity | Issue | Affected Repo(s) | Details |
|----|----------|-------|------------------|---------|
| P1-001 | 🟡 Medium | Empty placeholder repository | ndx-try-aws-isb | Contains only .gitignore and LICENSE. Should be archived or repurposed. |
| P1-002 | 🟡 Medium | Deprecated component still deployed | innovation-sandbox-on-aws-billing-seperator | Marked as temporary workaround, awaiting archival per ISB issue #70. |
| P1-003 | 🟢 Low | Inconsistent repository naming | All | Mix of hyphens and underscores (ndx-try-aws-* vs ndx_try_aws_scenarios) |
| P1-004 | 🟢 Low | Fork version lag | innovation-sandbox-on-aws | 3 versions behind upstream (v1.1.4 vs v1.1.7), missing security patches |

### Phase 2: AWS Organization Structure

| ID | Severity | Issue | Affected Resource | Details |
|----|----------|-------|-------------------|---------|
| P2-001 | 🟡 Medium | High quarantine count | Pool accounts | 4 of 9 pool accounts (44%) in Quarantine OU - indicates cleanup failures or extended cooldown |
| P2-002 | 🟢 Low | Empty environment OUs | Workloads/Dev, Test, Sandbox | These OUs exist but are unused - all workloads in Prod |
| P2-003 | 🟡 Medium | Dual SCP management | Organization SCPs | Both LZA and Terraform manage SCPs - potential for conflicts and drift |
| P2-004 | 🟢 Low | Role naming inconsistency | IAM Roles | Mix of github-actions-* and GitHubActions-* patterns |
| P2-005 | 🟢 Low | Missing GitHub OIDC roles | Multiple repos | billing-seperator, costs, utils, scenarios, lza, scp, terraform don't have visible OIDC roles in Hub |

### Phase 3: Innovation Sandbox Core

*(To be populated as Phase 3 agent completes)*

| ID | Severity | Issue | Affected Resource | Details |
|----|----------|-------|-------------------|---------|

### Phase 4: ISB Satellite Components

*(To be populated as Phase 4 agent completes)*

| ID | Severity | Issue | Affected Resource | Details |
|----|----------|-------|-------------------|---------|

### Phase 5: NDX Websites

*(To be populated as Phase 5 agent completes)*

| ID | Severity | Issue | Affected Resource | Details |
|----|----------|-------|-------------------|---------|

### Phase 6: LZA & Terraform

*(To be populated as Phase 6 agent completes)*

| ID | Severity | Issue | Affected Resource | Details |
|----|----------|-------|-------------------|---------|

### Phase 7: CI/CD Pipelines

*(To be populated)*

| ID | Severity | Issue | Affected Resource | Details |
|----|----------|-------|-------------------|---------|

### Phase 8: Security & Compliance

*(To be populated)*

| ID | Severity | Issue | Affected Resource | Details |
|----|----------|-------|-------------------|---------|

### Phase 9: Data Flows

*(To be populated)*

| ID | Severity | Issue | Affected Resource | Details |
|----|----------|-------|-------------------|---------|

---

## Summary Statistics

| Severity | Count |
|----------|-------|
| 🔴 Critical | 0 |
| 🟠 High | 0 |
| 🟡 Medium | 4 |
| 🟢 Low | 5 |
| **Total** | **9** |

---

## Recommendations Summary

### Immediate Actions (Critical/High)

*(None identified yet)*

### Short-Term Actions (Medium)

1. **Archive ndx-try-aws-isb** - Empty repo serving no purpose
2. **Archive billing-separator** - Temporary workaround that should be replaced
3. **Upgrade ISB fork** - Update to v1.1.7 for security patches
4. **Consolidate SCP management** - Move all SCPs to single IaC source (LZA or Terraform)
5. **Investigate quarantine backlog** - 44% of pool accounts in quarantine is unusually high

### Long-Term Actions (Low)

1. **Standardize naming conventions** - Consistent use of hyphens vs underscores
2. **Standardize role naming** - Consistent GitHub Actions role naming pattern
3. **Clean up empty OUs** - Remove or document purpose of empty environment OUs

---

## Issue Details

### P1-001: Empty placeholder repository

**Repository:** ndx-try-aws-isb
**Discovery Phase:** 1

The repository contains only:
- `.gitignore`
- `LICENSE`

No source code, no documentation beyond the license. The README in ndx-try-aws-terraform references that ISB files are in separate repositories.

**Recommendation:** Archive this repository or document its intended purpose.

---

### P1-002: Deprecated component still deployed

**Repository:** innovation-sandbox-on-aws-billing-seperator
**Discovery Phase:** 1

The README explicitly states:
> "This is a temporary workaround... This workaround should be deleted once the cooldown is natively supported."

The component enforces a 72-hour billing quarantine that should eventually be handled by the core ISB solution (tracking issue #70).

**Recommendation:** Track ISB issue #70 and archive when resolved.

---

### P2-001: High quarantine count

**Resource:** Pool accounts
**Discovery Phase:** 2

Current state:
- Available: 5 accounts (pool-003, 004, 005, 006, 009)
- Quarantine: 4 accounts (pool-001, 002, 007, 008)
- Active: 0 accounts

44% of pool accounts in quarantine suggests either:
1. Cleanup failures requiring manual remediation
2. Extended billing cooldown periods
3. Issues with the unquarantine automation

**Recommendation:** Investigate root cause and remediate quarantined accounts.

---

### P2-003: Dual SCP management

**Resource:** AWS Organizations SCPs
**Discovery Phase:** 2

SCPs are managed by two different IaC sources:
1. **LZA** (ndx-try-aws-lza): Core guardrails, security baselines
2. **Terraform** (ndx-try-aws-scp): Innovation Sandbox cost controls

This creates risks:
- Conflicting policies
- Configuration drift
- Unclear ownership
- Difficult auditing

**Recommendation:** Consolidate to single IaC source or clearly document ownership boundaries.

---

## Appendix: Issue Tracking

| Phase | Expected Issues | Discovered | Documented |
|-------|-----------------|------------|------------|
| Phase 1 | - | 4 | ✅ |
| Phase 2 | - | 5 | ✅ |
| Phase 3 | - | TBD | ⏳ |
| Phase 4 | - | TBD | ⏳ |
| Phase 5 | - | TBD | ⏳ |
| Phase 6 | - | TBD | ⏳ |
| Phase 7 | - | TBD | ⏳ |
| Phase 8 | - | TBD | ⏳ |
| Phase 9 | - | TBD | ⏳ |
| Phase 10 | - | TBD | ⏳ |

---

**Document End - This is a living document updated throughout the archaeology process**
