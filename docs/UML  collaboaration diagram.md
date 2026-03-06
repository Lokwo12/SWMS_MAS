```mermaid
flowchart LR
    SB[SmartBin_i]
    CC[ControlCenter]
    TK[Truck_j]
    LG[Logger]

    SB -- "status(Bin,level)" --> LG
    SB -- "full(Bin)" --> CC
    CC -- "full_received(Bin)" --> LG

    CC -- "collect(Bin)" --> TK
    TK -- "agree/refuse" --> CC
    TK -- "accepted/refused" --> LG

    CC -- "assigned/refused" --> LG
    TK -- "working/ready" --> LG
    TK -- "collected(Truck,Bin)" --> CC

    CC -- "completed(...)" --> LG
    CC -- "cleared" --> SB
    SB -- "reset(Bin)" --> LG
```

### Communication Semantics

- Message performative is primarily `inform(...)`.
- Control center is not a passive relay; it transforms event streams into coordination decisions.
- Logger receives semantically rich domain events from all operational roles.