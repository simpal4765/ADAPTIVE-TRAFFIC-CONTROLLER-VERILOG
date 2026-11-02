# Technical Report: Adaptive Multi-Junction Traffic Grid Controller

**Module Names:** traffic_top.v (Top Level) & junction_controlled.v (Sub-module)  
**Author:** Simpal Singh  
**Target Audience:** Design and Verification Engineering Team  

---

## 1. Architectural Decisions & Design Trade-offs

### 1.1 Moore Finite State Machine (FSM) Architecture
For the core logic implementation within `junction_controlled.v`, a **Moore Finite State Machine** topology was deliberately chosen. In a Moore FSM, the output signals (traffic light states) depend strictly on the current state rather than the inputs. This strategy ensures a completely glitch-free operation on the output ports. Eliminating combinational glitches is a safety-critical requirement in traffic hardware systems to prevent dangerous or ambiguous light transitions on the road.

### 1.2 Design Trade-offs: Complexity vs. System Safety
Integrating emergency vehicle override sensors and adaptive pedestrian crosswalk requests introduces a clear trade-off between hardware area complexity and system reliability:
* **Logic Utilization:** Implementing absolute priority encoding for emergency triggers requires extra combinational routing and logic gates compared to a standard, non-adaptive cyclic timer sequence.
* **Engineering Decision:** The minor increase in silicon area and structural complexity is heavily justified. Providing real-time emergency vehicle preemption directly improves safety-critical performance, making the system viable for real-world deployments where emergency bypass is mandatory.

---

## 2. Verification Strategy & Bug Log

### 2.1 Verification Strategy & Test Scenarios
To ensure high functional coverage and design reliability, a behavioral testbench (`traffic_tb.v`) was developed. The verification architecture validates the top-level module across three critical real-world operational scenarios:
* **Normal Cycle Test:** Verifies that the system sequentially transitions through the default states (Green → Yellow → Red) within the designated time boundaries under normal traffic conditions.
* **Emergency Override Test:** Validates that asserting an emergency trigger immediately forces the active junction out of its current cycle and locks it into an emergency green state to clear the path safely.
* **Pedestrian Crossing Test:** Confirms that pedestrian crossing requests are safely arbitrated, transitioning the junction into a secure walking state without inducing structural deadlocks.

### 2.2 Functional Bug Log
The engineering process tracked, isolated, and resolved functional anomalies during the simulation phase. Below is the documentation of the verified fixes:

| Bug ID | Location | Problem Description | Resolution / Architectural Fix |
| :--- | :--- | :--- | :--- |
| **BUG_01** | `junction_controlled.v` | Upon exiting the emergency state, the internal timers failed to reset, causing a random timing offset in the subsequent normal state. | Implemented a synchronous reset force (`counter <= 0`) strictly aligned with the emergency state exit transition condition. |
| **BUG_02** | `traffic_top.v` | Tight coupling between the handshaking signals of the two junctions induced an unintended operational deadlock during concurrent crossing requests. | Decoupled the transition logic flags and introduced an explicit priority structural encoder to resolve multi-request conflicts. |

---

## 3. Future Improvements

If granted additional engineering resources and development time, the following architectural enhancements would be integrated into the system:
* **AI-Driven Density Adaptation:** Incorporating computer vision metadata inputs to dynamically compute the optimum green-light window based on actual vehicle queues rather than fixed parametric thresholds.
* **IoT Telemetry Interface:** Integrating a telemetry sub-module to stream real-time FSM state data, system health logs, and emergency override frequency metrics directly to a centralized cloud dashboard for remote infrastructure monitoring.
