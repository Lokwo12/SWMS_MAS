```mermaid
classDiagram
    class Agent {
      +id
      +sendMessage()
      +receiveMessage()
      +heartbeat()
    }

    class SmartBin {
      +fill_level
      +fill_tick
      +reset_pause
      +auto_fillI()
      +handle_cleared_message()
      +tick_reset_cooldown()
    }

    class Truck {
      +busy_cycles
      +decision_countdown
      +active_collection
      +process_collect_orders()
      +process_pending_decisions()
      +start_collectionI()
      +complete_collectionI()
    }

    class ControlCenter {
      +awaiting
      +assigned_bin
      +tried_trucks
      +inflight_countdown
      +retry_countdown
      +process_full_events()
      +dispatch_request()
      +process_truck_events()
      +process_waiting_bins()
      +tick_inflight_watchdog()
    }

    class Logger {
      +log_seen
      +last_logged_data
      +process_logs()
      +heartbeatI()
    }

    Agent <|-- SmartBin
    Agent <|-- Truck
    Agent <|-- ControlCenter
    Agent <|-- Logger

    SmartBin --> ControlCenter : full(BinID)
    ControlCenter --> Truck : collect(BinID)
    Truck --> ControlCenter : agree/refuse/collected
    ControlCenter --> SmartBin : cleared

    SmartBin --> Logger : status/reset
    Truck --> Logger : accepted/refused/working/ready
    ControlCenter --> Logger : full_received/requesting/assigned/completed
```

### Class Model Notes

This class diagram is an abstraction layer over logic predicates. It highlights stateful properties and functional services, enabling conceptual transfer from implementation-level predicates to software architecture notation.
