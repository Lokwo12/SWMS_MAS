# MAS Web Integration — Executive Summary

## Project Purpose

This project transitions the current SICStus + DALI Multi-Agent System (MAS) from terminal-centric operation to a professional web-based operational platform. The goal is to preserve existing autonomous behavior while adding enterprise-grade control, visibility, and governance.

## Current State

The MAS is functionally stable and autonomous:

- smart bins detect fullness and trigger service requests,
- control center dispatches trucks with retry logic,
- trucks accept/refuse based on availability and complete collection,
- logger provides lifecycle traceability.

Operations are currently script-driven and pane-based (`startmas.sh`, `stopmas.sh`, `restartmas.sh`, `healthcheck.sh`).

## Target Outcome

A web system where authorized users can:

- start/stop/restart the MAS,
- monitor health and agent states,
- observe real-time lifecycle events,
- query historical events and audit actions,
- operate with clear security and accountability.

## Proposed Solution (High-Level)

The integration uses a non-invasive wrapper architecture:

1. **Web Frontend** for control and monitoring.
2. **Backend API/Orchestrator** to execute approved scripts safely.
3. **Realtime Gateway** (WebSocket) for live MAS events.
4. **Event Parser/Normalizer** to transform runtime outputs into structured JSON.
5. **Persistence Layer** for events, healthchecks, and audit logs.

This approach avoids modifying core MAS coordination logic and minimizes risk.

## Business and Academic Value

- **Operational efficiency:** one-click control and centralized visibility.
- **Reliability:** standardized health checks and failure detection.
- **Traceability:** complete audit records for operations and events.
- **Scalability:** supports future expansion (more bins/trucks, analytics).
- **Reportability:** architecture and behavior are documented in formal, reproducible artifacts.

## Delivery Plan

Implementation is organized into phased increments:

- **Phase 1 (MVP Wrapper):** control APIs + minimal dashboard + health integration.
- **Phase 2 (Professional Visibility):** realtime streaming + event schema + persistence.
- **Phase 3 (Production Readiness):** security hardening, metrics, alerting, deployment maturity.

Detailed tasks, estimates, and acceptance criteria are captured in:

- `WEB_INTEGRATION_BLUEPRINT.md`
- `WEB_INTEGRATION_BACKLOG.md`

## Key Risks and Mitigations

- **Parsing fragility from pane output** → strict normalization layer + contract tests.
- **Control-plane abuse risk** → command allowlist + RBAC + audit trail.
- **Event burst/latency** → WebSocket backpressure and server-side filtering.
- **Operational drift** → integration tests against real scripts in staging.

## Success Criteria

The initiative is successful when:

- MAS lifecycle operations are fully manageable from the web UI,
- real-time lifecycle events are visible and accurate,
- all actions are authenticated, authorized, and auditable,
- no regression occurs in existing autonomous MAS behavior.

## Recommended Immediate Next Step

Start **Phase 1** with a backend orchestration service and a minimal control dashboard. This delivers immediate operational value while preserving the current stable MAS core.
