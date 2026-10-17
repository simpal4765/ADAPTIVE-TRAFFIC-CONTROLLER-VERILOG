# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)
**A Production-Grade Parameterized Digital Design & Automated Verification Suite**

---

## 🛠️ Repository Directory Architecture & File Index
To mirror corporate semiconductor IP delivery standards, the project files are organized as follows:

* **Task-2_Parameterized_Design/** -> Core Parameterized RTL Modules & Testbenches (`generic_timer.v`, `junction_controller.v`).
* **Task-5_Full_Verification/** -> Automated Assertion-Based Self-Checking Scoreboard Suite (`tb_amtgc_self_checking.v`).
* **Root Directory (Task 3 & 4 Core Integration Cache):**
  * `amtgc_top.v` -> Core Top-Level Integration Wrapper (Task 3).
  * `ped_arbiter.v` -> Pure Handshake-Based Fair Token Pedestrian Arbiter (Task 3).
  * `junction_controller_adaptive.v` -> Clamped Traffic-Density FSM Timing Layer (Task 4).
  * `sys_ctrl_unit.v`, `junction_fsm.v`, `peripheral_output_decoder.v` -> Baseline Control Elements.
  * `tb_top_traffic_system.v`, `tb_traffic_adaptive.v` -> Integration & Advanced Feature Unit Testbenches.

---

## 🚀 Step-by-Step Compilation & Simulation Commands

### Prerequisites
Ensure an IEEE-1364 standard-compliant simulator is installed (**ModelSim, Questa Sim, or Icarus Verilog**).

### Compilation Flow (Example via Icarus Verilog)
```bash
# 1. Compile the Unified System Hierarchy
iverilog -o amtgc_sim.vvp Task-5_Full_Verification/tb_amtgc_self_checking.v amtgc_top.v junction_controller_adaptive.v generic_timer.v ped_arbiter.v

# 2. Execute the Automated Testbench Core
vvp amtgc_sim.vvp
```
*Note: The terminal console will instantly parse data packets and print out the absolute scoreboarding report showing `>>> STATUS: SIMULATION PASSED COMPLETELY <<<` without needing manual wave parsing.*

---

## 🎯 Key Structural Features
* **Zero-Timer Modification (0% Mod):** Seamless support for dynamic traffic timing sweeps without introducing structural modifications to the standalone timer core.
* **Deterministic Emergency Bounding:** Guarantees absolute intersection gridlock prevention, forcing all conflicting nodes into an All-Red safety state within a hard cap of 2 clock cycles.
* **Anti-Starvation Protocol:** Implements a token-based alternate-turn handshake policy to balance concurrent demands fairly without structural state lockouts.
