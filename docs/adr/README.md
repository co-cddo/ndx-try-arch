# Architecture Decision Records

This directory holds Architecture Decision Records (ADRs) for NDX Try. An ADR captures a significant architectural decision, the context in which it was made, the alternatives considered, and the conditions under which the decision should be revisited. ADRs make reasoning durable and reviewable: a future contributor or reviewer can read the record, challenge the assumptions, and either confirm the decision or propose a successor.

Unlike the rest of the documents under `docs/`, ADRs are hand-maintained and sit outside the auto-generation pipeline described in `AGENTS.md` and `update.prompt`. They are not registered in `docs/.meta/manifest.json` and should not be regenerated.

## Format

ADRs in this repository follow a MADR-style structure with the following sections:

- **Status**: one of `Proposed`, `Accepted`, `Accepted (retrospective)`, `Superseded by NNNN`, `Deprecated`.
- **Context**: the problem, the constraints, and the user populations or systems involved.
- **Decision**: the chosen approach in one or two paragraphs.
- **Considered options**: alternatives with concise reject reasons.
- **Consequences**: what the decision gains and what it costs.
- **Trigger conditions for revisit**: the concrete conditions under which the decision should be reopened.
- **References**: source links and supporting documents.

## Conventions

- Filenames use a zero-padded four-digit number followed by a lower-case kebab-case slug: `NNNN-short-slug.md`.
- Numbers are allocated sequentially. Once an ADR has a number, the number is permanent even if the ADR is later superseded or deprecated.
- A superseding ADR sets `Superseded by NNNN` on the older record and `Supersedes NNNN` on the new one.
- Status values progress only forward (a `Deprecated` ADR is never re-Accepted; write a new ADR instead).

## Index

| ADR | Title | Status |
|---|---|---|
| [0001](./0001-aws-identity-center.md) | Use AWS IAM Identity Center for NDX Innovation Sandbox identity | Accepted (retrospective) |
