# Smart Waste Management MAS – Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    participant SB as SmartBin_i
    participant CC as ControlCenter
    participant Tk as Truck_j
    participant LG as Logger

    Note over SB,LG: Phase 1 - Monitoring and Alert Generation

    loop Periodic fill update
        SB->>SB: update fill_level {0,20,60,80,100}
        SB->>LG: status(Bin_i, level)
    end

    SB->>CC: inform(full(Bin_i), Bin_i)
    CC->>LG: full_received(Bin_i)

    Note over SB,LG: Phase 2 - Dispatch and Negotiation

    loop Until collection is assigned
        CC->>CC: choose truck from pool
        CC->>LG: inform(requesting(Truck_j, Bin_i, mode), CC)
        CC->>Tk: inform(collect(Bin_i), CC)

        alt Truck_j accepts
            Tk->>LG: inform(accepted(Truck_j, Bin_i), Truck_j)
            Tk->>CC: inform(agree(Truck_j, Bin_i), Truck_j)
            CC->>LG: inform(assigned(Truck_j, Bin_i), CC)

        else Truck_j refuses
            Tk->>LG: inform(refused(Truck_j, Bin_i), Truck_j)
            Tk->>CC: inform(refuse(Truck_j, Bin_i), Truck_j)
            CC->>LG: inform(refused(Truck_j, Bin_i), CC)
            CC->>CC: add Truck_j to tried set and retry later

        else Inflight timeout
            CC->>LG: timeout watchdog event
            CC->>CC: release inflight and schedule retry
        end
    end

    Note over SB,LG: Phase 3 - Service Execution and Closure

    Tk->>LG: inform(working(Truck_j, Bin_i), Truck_j)
    Tk->>CC: inform(collected(Truck_j, Bin_i), Truck_j)
    Tk->>LG: inform(ready(Truck_j), Truck_j)
    CC->>LG: inform(completed(Truck_j, Bin_i), CC)
    CC->>SB: inform(cleared, CC)

    Note over SB,LG: Phase 4 - Recovery to Baseline State

    SB->>SB: reset fill_level to 0
    SB->>LG: inform(reset(Bin_i), Bin_i)

    opt Max timeout fallback reached
        CC->>LG: inform(completed(timeout, Bin_i), CC)
        CC->>SB: inform(cleared, CC)
        SB->>LG: inform(reset(Bin_i), Bin_i)
    end
```
