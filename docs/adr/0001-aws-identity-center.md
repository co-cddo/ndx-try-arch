# ADR-0001: Use AWS IAM Identity Center for NDX Innovation Sandbox identity

- **Status**: Accepted (retrospective)
- **Date**: 2026-04-28
- **Authors**: Chris Nesbitt-Smith, NDX
- **Supersedes**: n/a
- **Superseded by**: n/a

## Context

NDX runs the AWS Innovation Sandbox (ISB) solution to provide time-boxed AWS sandbox accounts to UK public sector and supplier users via NDX Try. ISB is an AWS-published reference solution whose architecture assumes AWS IAM Identity Center as the identity provider for both end users (people leasing a sandbox account) and operators (the NDX team running the service).

Two user populations need to authenticate:

1. **End users** drawn from UK central government, local government, NHS and other public-sector bodies, plus suppliers and collaborators who do not hold a UK `gov.uk` identity (for example AWS staff, vendor consultants).
2. **Operators**: the NDX team managing accounts, leases, and infrastructure. Operators hold admin access to the underlying isolated AWS organisation in addition to ISB-level operator rights. An unauthorised user provisioned into this group could incur significant cost or take actions that lock NDX out of its own estate. To this end, the NDX programme runs inside an isolated AWS organisation, deliberately separated from the rest of the GDS AWS estate to contain blast radius. That isolation also means there is no neighbouring privileged path to recover from if NDX administrators cannot authenticate; recovery would require break-glass via the management-account root.

Two identity routes are realistically available today:

- **AWS IAM Identity Center's built-in directory** (the route ISB documents and AWS supports).
- **GDS / CDDO Internal Access** (the OIDC identity broker at `co-cddo/sso-service`), federated into AWS IAM Identity Center via the `govuk-digital-backbone/saml2oauth` Terraform module. AWS IAM Identity Center accepts a single external IdP at a time, so any Digital Backbone SSO route requires a shim that presents itself as that single IdP.

This decision has been in effect since NDX Try launched. It has not previously been documented as an ADR, so its reasoning has lived in conversations rather than in a defendable written record. This ADR captures the reasoning and, more importantly, the conditions under which the decision should be revisited.

## Decision

Use AWS IAM Identity Center's built-in directory as the identity store for NDX Try, following the standard Innovation Sandbox configuration. Maintain operator and end-user separation via distinct IC groups mapped to distinct permission sets, as configured during initial ISB provisioning with AWS TAM support.

## Considered options

### Option 1: AWS IAM Identity Center built-in directory (chosen)

The configuration NDX runs today. ISB's documented identity model. NDX provisions users directly into IC and assigns them to groups that map to the appropriate permission sets.

### Option 2: Internal Access as upstream IdP, all users provisioned in Internal Access

Replace IC's built-in directory with a single SAML IdP backed by Internal Access (via the `saml2oauth` shim). Suppliers and ad-hoc users would be added inside Internal Access rather than IC.

Rejected for two reasons. First, Internal Access does not currently expose tenant-delegated user management. Adding a non-gov supplier, or a council not yet listed in `ukps-domains`, requires a config change in the central `co-cddo/sso-service` deployment, controlled by sso-service operators rather than NDX. NDX's day-to-day need to onboard users ahead of `ukps-domains` updates, and to add non-gov suppliers without external dependencies, is incompatible with this model today. Second, AWS IAM Identity Center supports a single identity source per instance, so federating end users to Internal Access necessarily federates operators as well. An Internal Access outage would then prevent operators from administering the isolated NDX AWS organisation, and recovery would require break-glass via the management-account root. Given operators hold full admin over the organisation, this is not an acceptable failure mode.

### Option 3: Broker in front of IC unifying multiple identity sources

A single broker (Cognito, Auth0, or bespoke) presents itself to IC as one IdP and federates Internal Access for gov users alongside an NDX-controlled local store for suppliers. This is the most literal reading of "shim with a custom user store".

Rejected on multiple grounds. Structurally, this option puts an authentication-path component inside NDX's boundary and makes NDX operationally responsible for it, which NDX has explicitly decided not to take on (see trigger condition 3). It also adds an operational component NDX must build, run, and patch, with no reference architecture to follow and no AWS support pathway. It inherits the same operator-authentication availability concern as Option 2: the broker becomes a single point of failure on the path to administering the isolated AWS organisation. The branding and AuthN UX gains do not outweigh any of these, individually or together.

### Option 4: Two IC instances or two AWS Organizations split by population

Operators in one IC instance backed by Internal Access; end users in another with a mixed source.

Rejected as out of scope for this ADR. It is a much larger change than a shim and would be considered only if the operator and end-user separation problem could not be solved within a single IC, which it can.

### Option 5: Per-supplier external federation

Each supplier brings their own IdP (for example Amazon Federate for AWS staff). Rejected because it does not fit IC's one-IdP-per-instance constraint, and collapses into Option 3 once a unifying broker is added.

### Option 6: Third-party IdP operated outside NDX's boundary (Okta, Auth0, Microsoft Entra External ID, AWS Cognito or similar)

An IdP federated into AWS IAM Identity Center as the single external identity source. Includes vendor-managed SaaS products (Okta, Auth0, Entra External ID), which are mature and contractually backed (Okta and Entra publish 99.99% SLAs), and self-hosted broker products such as AWS Cognito *if and only if* they are deployed and operated by a team outside NDX (for example a shared platform team or upstream provider). All have first-class SAML/OIDC and SCIM into AWS IC, custom branding, and tenant-controlled user provisioning matching the capability NDX uses in IC's built-in directory today.

The qualifying test for this option is operational ownership, not product category. A Cognito instance deployed into NDX's own AWS estate is not acceptable, on the same structural grounds that rule out the current `saml2oauth` Terraform module: NDX has decided not to take operational ownership of an authentication-path component for NDX Try. The same Cognito product run for NDX by a separate team is acceptable.

This option meaningfully clears the maturity bar that `saml2oauth` does not. It does not, however, address the operator-authentication-availability concern: AWS IAM Identity Center supports one identity source per instance, so routing end users through a commercial IdP also routes operators. A vendor outage would still gate operator administration of the isolated NDX AWS organisation, falling back to management-account root break-glass. Vendor SLAs reduce the probability of that outage but do not change the failure mode.

Rejected on a cost-and-justification balance rather than on principle:

- **No operational must-have today.** The capabilities a commercial IdP would add (custom branding, multi-cloud SSO, automated lifecycle from a gov HR source) are valuable but none has crossed the threshold from "nice-to-have" to "blocker" in user research or operations to date.
- **Cost.** Okta and Auth0 are priced per active user or per MAU; for NDX's mixed B2B/B2C population this is material. Entra External ID is cheaper but couples NDX more tightly to Microsoft. Cognito is cheap but operationally equivalent to running a bespoke IdP component.
- **Procurement and assurance.** Introducing a new commercial supplier on the authentication path of a live public-sector service requires DSIT-side procurement and assurance work that is not justified by the current capability gap.
- **Operator-authn availability not addressed.** As above, this option carries the same single-source-of-failure concern as Options 2 and 3; the only structural fix is splitting operators into a separate IC instance or AWS Organization (Option 4 territory).

This option is the most likely candidate to be reconsidered if the trigger conditions below begin to be met. Specifically, a commercial IdP would clear conditions 1, 3 and 4 by construction; the remaining gating questions would then be cost-versus-value (currently insufficient) and a credible answer for operator authn availability (condition 5).

## Detailed evaluation of the leading alternative

The serious challenger to today's setup is some combination of Internal Access and `saml2oauth`. The maturity of each component matters.

### `co-cddo/sso-service` (Internal Access)

- OIDC identity broker for the UK public sector, AuthN-only (clients do AuthZ).
- Currently in private beta at `sso.service.security.gov.uk`.
- Allowed users gated by `SIGN_IN_DOMAINS_ALLOWED` (consuming `ukps-domains`), plus per-email `SIGN_IN_EMAILS_ALLOWED` and `SUPERUSERS` lists, all controlled at the service level rather than per-tenant.
- Documents Google and Microsoft as upstream authentication providers, but Microsoft authentication is not currently functional in the deployed instance. In practice anyone not signing in with Google falls through to the email TOTP path. This matters because DSIT itself moved from Google Workspace to Microsoft 365 in March 2026, so the population NDX would most expect to benefit from SSO with the gov mainline currently does not.
- No published SLA appropriate to a live service.

### `govuk-digital-backbone/ukps-domains`

- The JSON list of UK public-sector domains that Internal Access uses for affiliation checks.
- Self-described as "a work in progress" that "may not contain a complete or accurate list".
- Council list auto-crawled from `localgov.co.uk`. NDX has hit cases where councils have been onboarded faster than the list updates.
- New domains require a PR to the central repo, not a tenant-side action.

### `govuk-digital-backbone/saml2oauth` (the shim)

State as of 2026-04-28:

| Dimension | State |
|---|---|
| Repo created | 2025-11-27 (5 months ago) |
| Commits on `main` | 1 ("Init"), single maintainer |
| Releases or tags | None |
| License | None (PR #2 to add MIT open since 2025-12-08) |
| README | 481 bytes, Terraform usage block only; no architecture, threat model, or operations docs |
| Tests | None on `main` (PR #5 adds 53 tests, open since 2025-12-08) |
| CI | None on `main` |
| `main` branch protection | Off |
| Distribution | Pre-built `dist/lambda.zip` (14 MB) committed to git and consumed directly by the Terraform module (PR #4 to move to GitHub Releases open since 2025-12-08) |
| Lambda exposure | `aws_lambda_function_url` with `authorization_type = "NONE"` (publicly callable) |
| Open security findings | PR #1 ("Add security fixes, comprehensive tests, CI/CD, and infrastructure improvements") cited XML injection, XSS, SCIM filter injection, and predictable IDs. The PR was closed on 2025-12-08 at maintainer request to be split into smaller PRs. The split PRs (#2, #4, #5) have been open without further review for over four months. |

For a component sitting on the authentication path of every user of a live AWS-touching service, this falls below the bar NDX requires. The shim is the load-bearing piece: even if Internal Access reached GA tomorrow, NDX's adoption is gated on the shim reaching production maturity.

There is a separate concern about `saml2oauth` in its current form, independent of code maturity: the Terraform module is designed to be deployed into the consumer's AWS account, which would put a security-critical authentication bridge inside NDX's boundary and make NDX operationally responsible for it. NDX has decided not to take on operational ownership of an authentication bridge for NDX Try. The acceptable shapes are either Internal Access exposing a native SAML interface that AWS IAM Identity Center can consume directly, or any required bridge being operated as a managed service by CDDO, Digital Backbone, or another upstream team.

NDX has no objection to `saml2oauth` as a piece of code. If it were brought to a maintained, first-class state (the maturity findings above closed) and operated outside NDX's boundary by an upstream team that had taken on its ownership, it would be a viable candidate. The objections are to NDX's operational ownership of it and to its current maintenance posture, not to the module's existence.

## Consequences

### What this decision gains

- **Alignment with the AWS-published ISB reference architecture.** Identity is configured as ISB's documentation expects, rather than diverging from the supported pattern.
- **AWS TAM and GDS enterprise support cover the configuration.** If something breaks, there is a vendor-supported escalation path. NDX has not had to invoke this beyond initial LZA and ISB provisioning, but it remains available.
- **NDX-team-controlled provisioning.** Suppliers, non-gov collaborators, and councils not yet in `ukps-domains` can be added the same day. This is a frequent operational need.
- **Operator and end-user separation is enforced via standard IC groups and permission sets.** The mapping was configured during ISB provisioning with AWS TAM input. Any future shim-based design would need to replicate this with a SCIM group mapping that has no equivalent vendor-supported reference.
- **Operator authentication does not depend on an external service.** Operators authenticate against IC's built-in directory, with no upstream IdP in the path. Because NDX runs as an isolated AWS organisation with no neighbouring privileged path, an outage of an external IdP under any federated design would force recovery via management-account root break-glass. Keeping operator authn local removes that coupling.

### What this decision costs

- **AWS-branded login page.** End users land on an AWS Identity Center login screen that NDX cannot brand. Tolerable while NDX is AWS-only; will become a meaningful UX issue as NDX onboards non-AWS suppliers (Google, Azure, Snowflake) where landing on an AWS-branded login page to access a non-AWS service is jarring. The "username is an email address" prompt is an additional UX wart that NDX has worked around in service prompts.
- **Identity is separate from the gov mainline.** End users authenticate against IC's directory rather than via their `gov.uk` identity. In practice the difference is small today: Internal Access's Microsoft authentication path is not currently functional, so any user not signing in with Google falls through to email TOTP, and IC also issues an email verification code. For DSIT-side users post-Microsoft migration, the practical user experience is the same email-code flow either way.
- **Single sign-on with other DSIT services is not available.** Not observed as a pain point in user research to date, but worth tracking.
- **Users maintain an additional password.** End users authenticate to IC's built-in directory with a password that is distinct from their employer-side credentials. This is recognised as a UX cost. Removing this in favour of a passwordless flow (for example WebAuthn/passkeys, or external IdP federation once the other concerns in this ADR are addressed) would be desirable.
- **No automated joiner or leaver lifecycle from a gov HR or identity source.** Manual offboarding is required, which raises a legitimate concern that a user who has left their public-sector employer might retain access to NDX Try. This is mitigated by NDX Try requiring an email TOTP code on every login: a departed user who has lost access to their work email cannot complete the authentication challenge, so practical access is gated on continued control of the user's organisational mailbox even without HR-driven deprovisioning. The mitigation is acknowledged as ugly, not elegant, and the additional password noted above is the visible cost of relying on a local directory rather than an upstream identity source.

## Trigger conditions for revisit

This decision should be reviewed when the following conditions are met. Any single condition is not sufficient on its own, but together they describe the bar at which the alternative becomes the better option.

1. **Internal Access reaches public beta or GA** with a published SLA appropriate to NDX Try's service level.
2. **Tenant-delegated user provisioning exists in Internal Access**, allowing NDX to add suppliers and ad-hoc public-sector users without service-operator involvement, OR `ukps-domains` reaches sufficient coverage that the ad-hoc need disappears in practice.
3. **The bridging component, if any, does not run within NDX's boundary.** Either Internal Access (or its successor) speaks AWS IAM Identity Center's expected SAML protocol directly with no intermediary, or any required bridge is operated as a managed service by CDDO, Digital Backbone, or another upstream provider in the same posture as Internal Access itself. NDX will not take operational ownership of an authentication bridge component on the authentication path of NDX Try, regardless of the maturity of its code. This rules out the current `saml2oauth` Terraform module by deployment model, independent of the maturity findings recorded above.
4. **A documented, reviewed SCIM-group to IC-permission-set pattern exists** for separating operator and end-user populations under a federated model, ideally as a CDDO or Digital Backbone-published pattern rather than bespoke NDX work.
5. **A credible answer exists for operator authentication availability under a federated model**, given AWS IAM Identity Center's single-identity-source constraint and NDX's isolated-organisation design. Acceptable answers might be: a documented operator break-glass path that does not rely on management-account root, an architecture that keeps operator authn local while federating end users (for example a separate IC instance for operators), or sufficient confidence in the upstream IdP's availability to accept the dependency.
6. **Multi-cloud expansion of NDX makes the AWS-branded login page a measured pain point** in user research.

Conditions 1 to 3 are the minimum technical bar. Conditions 4 and 5 are required to keep operator administration safe under a federated design. Condition 6 sharpens the case for action.

## What NDX has done to engage

NDX has actively engaged with `saml2oauth` to try to close the maturity gap rather than treating it as an external blocker.

- **PR #1** (closed 2025-12-08): "Add security fixes, comprehensive tests, CI/CD, and infrastructure improvements", including fixes for XML injection, XSS, SCIM filter injection, and predictable IDs, plus a 53-test suite and a CI workflow. Closed at maintainer request to be split into smaller PRs.
- **PR #2** (open since 2025-12-08): Add MIT LICENSE.
- **PR #4** (open since 2025-12-08): Move `lambda.zip` from git to GitHub Releases.
- **PR #5** (open since 2025-12-08): Add test suite and CI workflow.

PRs #2, #4, and #5 have been open without further maintainer review for over four months. This is recorded as evidence about the component's current sustained-engineering posture, not as criticism of any individual. Engagement remains open and NDX would welcome the opportunity to support a maturity uplift.

## References

- AWS Solutions Library: Innovation Sandbox on AWS
- `co-cddo/sso-service` (Internal Access): https://github.com/co-cddo/sso-service
- `govuk-digital-backbone/saml2oauth`: https://github.com/govuk-digital-backbone/saml2oauth
- `govuk-digital-backbone/ukps-domains`: https://github.com/govuk-digital-backbone/ukps-domains
- AWS IAM Identity Center external IdP support documentation
