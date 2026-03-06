```mermaid
flowchart LR
    U[Operator/User] --> FE[Web Dashboard]
    FE --> API[Backend API / Orchestrator]
    FE --> WS[Realtime Gateway]

    API --> ST[startmas.sh]
    API --> SP[stopmas.sh]
    API --> RS[restartmas.sh]
    API --> HC[healthcheck.sh]

    ST --> TMUX[tmux Session: DALI_session]
    TMUX --> LINDA[LINDA Server]
    TMUX --> CC[control_center]
    TMUX --> LG[logger]
    TMUX --> SB[smart_bin1..3]
    TMUX --> TK[truck1..3]

    SB --> CC
    CC --> TK
    TK --> CC

    SB --> LG
    TK --> LG
    CC --> LG

    LG --> PARSER[Event Parser]
    PARSER --> WS
```
## Key Operational Characteristics

- Startup script automatically prepares environment and launches expected topology.
- Healthcheck validates both process-level and signal-level liveness.
- Runtime behavior relies on asynchronous event consumption from `past(...)` memory.
- Control-center state machines prevent dispatch races and stale inflight assignments.

---