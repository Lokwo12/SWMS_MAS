# MAS Web Integration Backlog

This backlog translates the integration blueprint into actionable work items for delivery.

## 1) Planning Assumptions

- Team size: 2–4 engineers
- Sprint length: 1 week
- Priority scale: P0 (critical), P1 (high), P2 (medium)
- Estimation scale: Story Points (SP)

---

## 2) Epic Overview

- **EPIC A (P0): Control Plane API & Process Orchestration**
- **EPIC B (P0): Realtime Event Streaming**
- **EPIC C (P1): Web Dashboard UX**
- **EPIC D (P0): Security, Auth, and Audit**
- **EPIC E (P1): Persistence and Query APIs**
- **EPIC F (P1): Health, Observability, and Alerting**
- **EPIC G (P2): Hardening and Production Readiness**

---

## 3) Detailed Backlog

## EPIC A — Control Plane API & Process Orchestration (P0)

### A1. Backend service skeleton (FastAPI/Nest/Fastify)
- Priority: P0
- Estimate: 3 SP
- Dependencies: none
- Deliverables:
  - project bootstrap
  - `/api/v1/system/status` health endpoint
- Acceptance Criteria:
  - service starts with env config
  - status endpoint returns service + MAS process metadata

### A2. Script execution wrapper with allowlist
- Priority: P0
- Estimate: 5 SP
- Dependencies: A1
- Deliverables:
  - safe command executor for `startmas.sh`, `stopmas.sh`, `restartmas.sh`, `healthcheck.sh`
  - timeout + exit code capture
- Acceptance Criteria:
  - no arbitrary command execution
  - operation response includes requestId, status, exitCode

### A3. Control endpoints
- Priority: P0
- Estimate: 5 SP
- Dependencies: A2
- Deliverables:
  - `POST /system/start`
  - `POST /system/stop`
  - `POST /system/restart`
  - `POST /system/healthcheck`
- Acceptance Criteria:
  - endpoints trigger correct scripts
  - concurrent conflicting operations are rejected cleanly

### A4. Process/state machine
- Priority: P0
- Estimate: 3 SP
- Dependencies: A3
- Deliverables:
  - operation lock (`idle|starting|running|stopping|failed`)
- Acceptance Criteria:
  - no double-start race
  - valid transitions only

---

## EPIC B — Realtime Event Streaming (P0)

### B1. WebSocket gateway
- Priority: P0
- Estimate: 5 SP
- Dependencies: A1
- Deliverables:
  - `/ws/events`
  - connection heartbeat + reconnect guidance
- Acceptance Criteria:
  - clients receive server heartbeats
  - disconnect/reconnect does not crash gateway

### B2. Logger stream ingestion
- Priority: P0
- Estimate: 5 SP
- Dependencies: B1, A3
- Deliverables:
  - tail/capture logger pane output
  - parse key lifecycle lines
- Acceptance Criteria:
  - emits events for `full_received`, `assigned`, `completed`, `reset`

### B3. Event normalization schema
- Priority: P0
- Estimate: 3 SP
- Dependencies: B2
- Deliverables:
  - canonical JSON event envelope
  - event type registry
- Acceptance Criteria:
  - all outgoing events include `id`, `ts`, `type`, `agent`, `data`

---

## EPIC C — Web Dashboard UX (P1)

### C1. Dashboard shell + routing
- Priority: P1
- Estimate: 3 SP
- Dependencies: A1
- Deliverables:
  - app shell, nav, responsive layout
- Acceptance Criteria:
  - pages load with protected routing scaffold

### C2. System control panel
- Priority: P1
- Estimate: 5 SP
- Dependencies: A3
- Deliverables:
  - start/stop/restart buttons
  - in-progress and result states
- Acceptance Criteria:
  - button actions map to API operations
  - disabled states during in-flight ops

### C3. Live event console
- Priority: P1
- Estimate: 5 SP
- Dependencies: B1, B3
- Deliverables:
  - websocket event stream UI
  - filter by agent/type
- Acceptance Criteria:
  - updates in near real time
  - filters apply without reload

### C4. Agent status board
- Priority: P1
- Estimate: 5 SP
- Dependencies: A1, B2
- Deliverables:
  - cards for bins, trucks, control_center, logger
- Acceptance Criteria:
  - current state visible per role
  - stale states marked automatically

---

## EPIC D — Security, Auth, and Audit (P0)

### D1. AuthN integration (JWT/OIDC)
- Priority: P0
- Estimate: 5 SP
- Dependencies: A1
- Deliverables:
  - login/session middleware
- Acceptance Criteria:
  - unauthenticated users cannot access control APIs

### D2. RBAC policy
- Priority: P0
- Estimate: 3 SP
- Dependencies: D1
- Deliverables:
  - roles: viewer/operator/admin
  - endpoint guards
- Acceptance Criteria:
  - only authorized roles can start/stop/restart

### D3. Audit trail
- Priority: P0
- Estimate: 5 SP
- Dependencies: A3, D2
- Deliverables:
  - persist each control action with actor, time, result
- Acceptance Criteria:
  - every control action is traceable in audit endpoint

---

## EPIC E — Persistence and Query APIs (P1)

### E1. Database schema migrations
- Priority: P1
- Estimate: 5 SP
- Dependencies: A1
- Deliverables:
  - tables: operations, events, health_checks, audit
- Acceptance Criteria:
  - schema migration reproducible in CI/local

### E2. Event persistence pipeline
- Priority: P1
- Estimate: 5 SP
- Dependencies: B3, E1
- Deliverables:
  - persist normalized event stream
- Acceptance Criteria:
  - no crash on malformed lines
  - failed inserts are retried/logged

### E3. Query APIs
- Priority: P1
- Estimate: 5 SP
- Dependencies: E2
- Deliverables:
  - `GET /events`, `GET /audit`, `GET /healthchecks`
- Acceptance Criteria:
  - supports time range and type filters

---

## EPIC F — Health, Observability, and Alerting (P1)

### F1. Healthcheck API integration
- Priority: P1
- Estimate: 3 SP
- Dependencies: A3
- Deliverables:
  - parse `healthcheck.sh` result and expose structured response
- Acceptance Criteria:
  - pane-missing and lifecycle-signal states visible in UI/API

### F2. Metrics instrumentation
- Priority: P1
- Estimate: 5 SP
- Dependencies: A1
- Deliverables:
  - Prometheus/OpenTelemetry counters and histograms
- Acceptance Criteria:
  - startup success, op latency, ws clients, events/sec emitted

### F3. Alert rules
- Priority: P1
- Estimate: 5 SP
- Dependencies: F2
- Deliverables:
  - rules for missing session, repeated restart failure, inactivity
- Acceptance Criteria:
  - alert triggers tested on simulated failures

---

## EPIC G — Hardening and Production Readiness (P2)

### G1. Reverse proxy + TLS
- Priority: P2
- Estimate: 5 SP
- Dependencies: A1, C1
- Deliverables:
  - Nginx/Caddy config for API + WS + frontend
- Acceptance Criteria:
  - HTTPS enabled, websocket upgrade works

### G2. Containerization and deployment scripts
- Priority: P2
- Estimate: 8 SP
- Dependencies: A1, C1
- Deliverables:
  - Dockerfiles / compose / env templates
- Acceptance Criteria:
  - reproducible deployment in staging

### G3. Backup and retention policy
- Priority: P2
- Estimate: 3 SP
- Dependencies: E1
- Deliverables:
  - event/audit backup job, retention settings
- Acceptance Criteria:
  - restore drill documented

---

## 4) Suggested Sprint Plan

## Sprint 1 (P0 foundation)
- A1, A2, A3, A4
- B1
- D1

Goal: secure API can control MAS lifecycle safely.

## Sprint 2 (visibility MVP)
- B2, B3
- C2, C3
- D2, D3

Goal: web UI controls + live events + audit trail.

## Sprint 3 (operational maturity)
- C4
- E1, E2, E3
- F1

Goal: persistent observability and status board.

## Sprint 4 (production posture)
- F2, F3
- G1, G2, G3

Goal: hardened deployable platform with metrics and alerts.

---

## 5) Risks and Mitigations

- **Risk:** fragile parsing from pane text output.
  - Mitigation: normalized parser with strict fallback + contract tests.
- **Risk:** command execution abuse.
  - Mitigation: hard allowlist, no shell passthrough, RBAC.
- **Risk:** event bursts overload websocket clients.
  - Mitigation: backpressure, batching, server-side filters.
- **Risk:** divergence between script behavior and API expectations.
  - Mitigation: integration tests that execute real scripts in staging.

---

## 6) Definition of Done (Global)

A backlog item is done when:

- code is merged with tests,
- API/UI behavior matches acceptance criteria,
- audit/metrics hooks (where relevant) are included,
- documentation is updated,
- no regression in existing MAS run scripts.

---

## 7) Immediate Next Actions (Execution Start)

1. Choose backend stack (FastAPI vs Node Fastify/Nest).
2. Implement A1/A2 skeleton with command allowlist.
3. Expose start/stop/restart + status endpoints.
4. Connect minimal UI control panel to these endpoints.
