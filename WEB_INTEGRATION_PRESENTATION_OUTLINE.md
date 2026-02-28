# MAS Web Integration — Presentation Outline (10 Slides)

## Slide 1 — Title & Context
- Project title: Web Integration of SICStus + DALI Autonomous MAS
- Team / course / date
- One-line objective: move from terminal-only operation to professional web operations without changing MAS core behavior

## Slide 2 — Problem Statement
- Current system is autonomous and stable, but operation is terminal-centric
- Limited centralized visibility and control for stakeholders
- Need for auditable operations and real-time monitoring

## Slide 3 — Existing MAS (As-Is)
- Roles: Smart Bins, Control Center, Trucks, Logger
- Core cycle: full alert -> dispatch -> accept/refuse -> collected -> cleared -> reset
- Runtime stack: SICStus + DALI + Linda + tmux

## Slide 4 — Target Vision (To-Be)
- Web dashboard with Start/Stop/Restart/Healthcheck
- Real-time event stream and agent status board
- Historical queries and audit trail
- Security: authenticated and role-based access

## Slide 5 — Architecture Overview
- Frontend (dashboard)
- Backend API/orchestrator (script execution allowlist)
- Realtime gateway (WebSocket)
- Event parser/normalizer
- Storage (events, health checks, audit)
- Keep MAS logic unchanged (wrapper integration)

## Slide 6 — Data & Event Model
- Canonical event envelope: id, ts, source, type, agent, data, correlationId
- Critical lifecycle events: full_received, requesting, assigned, refused, completed, reset
- Optional debug channel separated from business-critical stream

## Slide 7 — Security & Governance
- AuthN: JWT/OIDC
- RBAC: viewer/operator/admin
- Full audit for each control action (who, what, when, outcome)
- Hardening: command allowlist, timeouts, rate limiting, TLS

## Slide 8 — Delivery Roadmap
- Phase 1: MVP wrapper (control APIs + basic UI + health)
- Phase 2: Professional visibility (WebSocket + persistence + filters)
- Phase 3: Production readiness (metrics, alerts, hardening)
- Show sprint cadence from backlog

## Slide 9 — Risks & Mitigation
- Parsing fragility -> strict normalization + contract tests
- Command abuse risk -> allowlist + RBAC + audit
- Event burst/latency -> filtering + backpressure
- Operational drift -> integration tests with real scripts

## Slide 10 — Expected Outcomes & Next Step
- Outcomes:
  - operational control from browser
  - real-time visibility
  - auditable governance
  - no regression in MAS autonomy
- Immediate next step:
  - implement Phase 1 control backend + minimal dashboard
- Call to action:
  - approve stack and start Sprint 1

---

## Speaker Notes (Short)
- Keep slides visual; use architecture and sequence diagrams from blueprint.
- For technical audience, emphasize non-invasive integration and reliability.
- For stakeholder audience, emphasize visibility, control, and auditability.
- Close with timeline confidence based on backlog estimates.
