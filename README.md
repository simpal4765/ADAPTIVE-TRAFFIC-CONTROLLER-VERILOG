
Top-Level Block Diagram

The text-based block diagram below details the structural connectivity between the top-level ports, the independent junction controllers, the shared pedestrian arbiter, and the green-wave coordination logic under a unified single-clock domain.
+-------------------------------------------------------------------------------------------------------------------------+

| SYSTEM_TOP (Top-Level Module)                                                                                           |
|                                                                                                                         |
|                        +------------------------------------------------------------------------+                       |
|                        | GREEN-WAVE COORDINATION REGISTRY / DELAY COUNTER                       |                       |
|                        |                                                                        |                       |
|                        |   j1_ns_green_start (internal pulse)                                   |                       |
|                        |   ======> [ Delay Counter (Configurable Cycles) ] ======> j2_sync_trigger  |                       |
|                        +---|-----------------------------------------------------|--------------+                       |
|                            ^                                                     v                                      |
|                            |                                                     |                                      |
|    clk ----+---------------+-----------------------------------------------------+-----------------+                    |
|    rst_n --+---------------+-----------------------------------------------------+-----------------+                    |
|            |               |                                                     |                 |                    |
|            v               |                                                     v                 v                    |
|      +---------------------+---+                                           +-----+-------------------+                  |
|      | JUNCTION_CONTROLLER_A   |                                           | JUNCTION_CONTROLLER_B   |                  |
|      | (Junction A - Master)   |                                           | (Junction B - Slave)    |                  |
|      |                         |                                           |                         |                  |
|      | Inputs:                 |                                           | Inputs:                 |                  |
|      | - emerg_override        |                                           | - emerg_override        |                  |
|      | - ped_grant_a           |                                           | - ped_grant_b           |                  |
|      |                         |                                           | - sync_trigger_in       |                  |
|      | Outputs:                |                                           |                         |                  |
|      | - lights_a [5:0]        |                                           | Outputs:                |                  |
|      | - ped_active_a          |                                           | - lights_b [5:0]        |                  |
|      |                         |                                           | - ped_active_b          |                  |
|      +---|-----------------|---+                                           +---|-----------------|---+                  |
|          |                 ^                                                   |                 ^                      |
|          | ped_req_a       | ped_grant_a                                       | ped_req_b       | ped_grant_b          |
|          v                 |                                                   v                 |                      |
|      +---|-----------------|---------------------------------------------------|-----------------|---+                  |
|      |   +-----------------+                                                   +-----------------+   |                  |
|      |   |                                                                                       |   |                  |
|      |   v                                                                                       v   |                  |
|      | +-------------------------------------------------------------------------------------------+ |                  |
|      | | SHARED_PEDESTRIAN_ARBITER                                                                 | |                  |
|      | |                                                                                           | |                  |
|      | | Logic: Round-Robin / Age-Based Fairness FSM                                               | |                  |
|      | +-------------------------------------------------------------------------------------------+ |                  |
|      |                                                                                               |                  |
|      +-----------------------------------------------------------------------------------------------+                  |
|                                                                                                                         |
+-------------------------------------------------------------------------------------------------------------------------+

2. Module Interface Definitions


2.1 Top-Level Module (system_top)

• Purpose: Encloses the entire dual-junction infrastructure, instantiates sub-modules, handles synchronization logic, and routes global control signals.

Signal Name	Direction	Width	Purpose
clk	Input	1	Global system clock component (Single clock domain).
rst_n	Input	1	Active-low system reset.
emerg_override	Input	1	Active-high global emergency override signal. Forces all-red safety configuration.
ped_req_a_ns / _ew	Input	2	Pedestrian push-button requests for Junction A (North-South, East-West).
ped_req_b_ns / _ew	Input	2	Pedestrian push-button requests for Junction B (North-South, East-West).
lights_a	Output	6	6-bit vector for Junction A signals: [5:3] North-South (R,Y,G), [2:0] East-West (R,Y,G).
lights_b	Output	6	6-bit vector for Junction B signals: [5:3] North-South (R,Y,G), [2:0] East-West (R,Y,G).
ped_walk_a	Output	2	Pedestrian crossing signals for Junction A: [1] North-South Walk, [0] East-West Walk.
ped_walk_b	Output	2	Pedestrian crossing signals for Junction B: [1] North-South Walk, [0] East-West Walk.


2.2 Junction Controller Module (junction_controller)

• Purpose: Implements individual 4-way traffic FSM sequencing (Green \(\rightarrow \) Yellow \(\rightarrow \) Red) and directly responds to localized pedestrian grants and the emergency override.

Signal Name	Direction	Width	Purpose
clk	Input	1	System clock.
rst_n	Input	1	System reset.
emerg_override	Input	1	Monitors global emergency override status. Intercepts state logic instantly.
sync_trigger_in	Input	1	Active-high pulse triggering an early transition into North-South Green (Used in Junction B).
ped_grant_ns / _ew	Input	2	Active-high flags from the arbiter giving permission to enter pedestrian walk states.
sync_trigger_out	Output	1	Emits an active-high single-cycle pulse when North-South Green sequence initializes (Used by Junction A).
ped_req_out_ns / _ew	Output	2	Forwarded/latched pedestrian requests sent to the arbiter.
lights	Output	6	6-bit individual vector: [5:3] North-South (R,Y,G), [2:0] East-West (R,Y,G).


2.3 Shared Pedestrian Arbiter (pedestrian_arbiter)

• Purpose: Evaluates conflicting crossing requests from both junctions and selectively asserts grant flags based on a fair scheduling mechanism.

Signal Name	Direction	Width	Purpose
clk	Input	1	System clock.
rst_n	Input	1	System reset.
ped_req_a_ns / _ew	Input	2	Latched pedestrian request inputs originating from Junction A.
ped_req_b_ns / _ew	Input	2	Latched pedestrian request inputs originating from Junction B.
emerg_override	Input	1	Disables active pedestrian grants during an emergency condition.
ped_grant_a_ns / _ew	Output	2	Permission handshake flags routed back to Junction A.
ped_grant_b_ns / _ew	Output	2	Permission handshake flags routed back to Junction B.


3. Architectural Design Rationale


3.1 Separation of Modules

• Maintainability and Readability: Decoupling junction_controller from coordination and arbitration logic avoids creating a chaotic, monolith FSM.
• Reusability: The identical junction_controller logic can be instantiated multiple times (junc_a, junc_b). Structural adjustments are configured entirely via parameters or input ports (e.g., ignoring sync_trigger_in on the master junction).

3.2 Shared Pedestrian Controller vs. Duplication

• Global Structural Constraints: If individual intersections acted independently, pedestrian windows at adjacent junctions could open simultaneously, disrupting cross-junction arterial vehicular flows.
• Resource Efficiency & Centralized Control: A shared arbiter guarantees that crosswalk deployment can be scheduled safely against overall traffic state metrics, ensuring a predictable vehicle throughput while saving gate area by eliminating redundant timer counters.

3.3 Starvation and Simultaneous Request Handling

To handle simultaneous pedestrian requests without starvation, the system implements a Round-Robin with History Tracking arbitration scheme:
1. Request Capture: Pedestrian button inputs instantly latch into internal registers within the arbiter.
2. Stateful Token: A microscopic priority pointer keeps track of which junction was served last.
3. Fair Selection: If simultaneous requests arrive from Junction A and Junction B, the arbiter grants access to the intersection that does not currently hold the priority token. Once that crosswalk sequence finishes, the token switches to the alternative junction, ensuring that no request is bypassed twice.

4. Clocking and Reset Strategy


4.1 Clocking Strategy: Single Clock Domain

The complete design operates entirely within a Single Synchronous Clock Domain. All registers share a single clk net distributed via a low-skew clock tree.
• Justification: Eliminates CDC (Clock Domain Crossing) synchronization vulnerabilities, prevents metastability risks across module paths, and simplifies static timing analysis (STA). Internal slow counters are used to manage multi-second intervals rather than deriving divided sub-clocks.

4.2 Reset Strategy: Synchronous Reset

The design uses an Active-Low Synchronous Reset (rst_n).
• Justification: Synchronous resets are filtered by the logic synthesis tools into the data input D-lines of the flip-flops. This prevents glitches on reset lines from causing accidental system resets. It also guarantees that the system enters and exits its initialization states precisely aligned with a clock edge, avoiding timing violations during startup.

5. Verification Plan (15 Test Scenarios)

The testbench must execute the following 15 distinct functional scenarios to prove design compliance before signing off on the RTL:

Normal Sequencing & Green-Wave Scenarios

1. Power-On Initialization: Assert rst_n low for 5 cycles; verify both junctions initialize safely to All-Red, and all internal registers/counters clear to zero.
2. Junction A Nominal Cycle: Run uninterrupted traffic loops to verify Junction A cycles flawlessly through North-South Green \(\rightarrow \) Yellow \(\rightarrow \) Red and East-West Green \(\rightarrow \) Yellow \(\rightarrow \) Red according to programmed counter durations.
3. Junction B Nominal Cycle: Run independent checks to ensure Junction B cycles through normal operations smoothly when no external coordination triggers are applied.
4. Green-Wave Delay Trigger: Verify that when Junction A transitions to North-South Green, an internal pulse initiates the delay counter, and Junction B subsequently receives its sync_trigger_in exactly \(N\) clock cycles later.
5. Green-Wave Early Transition: Verify that if Junction B is currently in an East-West state, receiving a green-wave sync_trigger_in forces it to shorten its current window cleanly through a proper Yellow cycle to bring its North-South Green online early.

Pedestrian Arbitration Scenarios

6. Isolated Request Junction A: Assert ped_req_a_ns during traffic flow. Verify that the arbiter issues a grant, Junction A transitions to a pedestrian safe state, and the walk signal displays correctly.
7. Isolated Request Junction B: Assert ped_req_b_ns during traffic flow. Verify that Junction B safely transitions to its pedestrian phase independent of Junction A.
8. Simultaneous Balanced Requests: Assert ped_req_a_ns and ped_req_b_ns at the exact same clock edge. Verify that the arbiter grants priority to the default channel without stalling or entering an invalid state.
9. Starvation Prevention (Round-Robin): Trigger simultaneous requests multiple times sequentially. Verify that the arbiter alternates priority between Junction A and Junction B, preventing either intersection from being locked out.
10. Latching Integrity: Assert a pedestrian request pulse for only a single clock cycle. Verify that the arbiter successfully latches the request and holds it until the state machine processes and satisfies the request.

Emergency Override & Corner-Case Scenarios

11. Emergency Override Assertion: Assert emerg_override while both junctions are in active Green cycles. Verify that both systems cleanly transition through Yellow to an All-Red safety state within the specified number of clock cycles.
12. Emergency Override Maintenance: Hold emerg_override high for an extended duration. Verify that both junctions remain locked in an All-Red state, ignoring all ongoing traffic counters and pedestrian requests.
13. Emergency Override Release: De-assert emerg_override. Verify that both junctions resume operational sequencing safely from a predefined starting configuration (e.g., initiating North-South Green simultaneously).
14. Pedestrian Interruption by Emergency: Trigger an active pedestrian walk state so that pedestrian grants are high, then assert emerg_override. Verify that walk grants terminate immediately and both intersections pull all vehicle signals to Red.
15. Maximum Stress Concurrency: Drive emerg_override, multiple asynchronous pedestrian buttons, and green-wave synchronization pulses simultaneously. Verify that the emergency state overrides all other inputs, preventing any dangerous states or simulator deadlocks.
