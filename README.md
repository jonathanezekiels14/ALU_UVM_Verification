# Parameterized ALU – UVM SystemVerilog Verification

A fully layered, OOP-based UVM verification environment for a parameterized Arithmetic Logic Unit (ALU) implemented in synthesizable SystemVerilog. The testbench features a dual-agent architecture separating active stimulus from passive observation, a self-checking scoreboard with an embedded reference model, functional coverage collection, and concurrent SVA assertions bound directly into the DUT.

---

## Repository Structure


```

.
├── src/
│   └── ALU_DESIGN.sv                # DUT – Parameterized ALU RTL
├── tb/
│   ├── alu_defines.svh              # Parameter definitions (DW, CW)
│   ├── alu_pkg.sv                   # Package wrapper for TB classes
│   ├── alu_interface.sv             # Clocked interface (INP_DRV, INP_MON, OUT_MON modports)
│   ├── alu_transaction.sv           # Base sequence item with randomization constraints
│   ├── alu_sequences.sv             # Sanity, corner-case, error, and constrained-random sequences
│   ├── alu_driver.sv                # Active input driver
│   ├── alu_inpmon.sv                # Input monitor (tracks operand validity)
│   ├── alu_outmon.sv                # Latency-aware passive output monitor
│   ├── alu_scoreboard.sv            # Self-checking scoreboard via predict_output()
│   ├── alu_coverage_subscriber.sv   # Functional coverage (alu_cg covergroup)
│   ├── alu_assertions.sv            # Concurrent SVA assertions (bound into DUT)
│   ├── alu_env.sv                   # Environment – builds active/passive agents and scoreboard
│   ├── alu_tests.sv                 # Base test + regression suite tests
│   └── tb_top.sv                    # Top module – DUT instantiation + bind + UVM entry
├── docs/
│   └── ALU_UVM_Project_Report.pdf   # Full verification report
├── logs/
│   └── transcript                   # Questa SIM transcript
├── coverage/
│   └── alu_coverage.ucdb            # Merged coverage database
└── README.md

```

---

## Design Overview

The DUT (`ALU_DESIGN`) is a synchronous, CE-gated ALU capable of performing arithmetic and logical operations on configurable-width operands. It uses a two-stage sequential input protocol and features a multi-cycle pipeline for multiplication.

### Parameters

| Parameter  | Value | Description            |
|---|---|---|
| `DW` | 8     | Data width (operands A and B) |
| `CW` | 4     | Command width |

### Inputs

| Signal       | Width | Description |
|---|---|---|
| `CLK`        | 1     | System clock — all updates occur on rising edge |
| `RST`        | 1     | Synchronous active-high reset |
| `CE`         | 1     | Clock enable — halts computation and latches outputs when 0 |
| `MODE`       | 1     | `1` = Arithmetic, `0` = Logical |
| `CMD`        | 4     | Operation command selector (0-10 Arithmetic, 0-13 Logical) |
| `OPA`        | 8     | Operand A |
| `OPB`        | 8     | Operand B |
| `INP_VALID`  | 2     | `01`=OPA valid, `10`=OPB valid, `11`=Both valid |
| `CIN`        | 1     | Carry-in for ADD_CIN and SUB_CIN commands |

### Outputs

| Signal       | Width | Description |
|---|---|---|
| `RES`        | 10    | Operation result (Declared `DW+2` in DUT) |
| `COUT`       | 1     | Carry-out flag |
| `OFLOW`      | 1     | Overflow flag for subtraction |
| `ERR`        | 1     | Error flag (asserts on timeout or invalid rotation) |
| `G/E/L`      | 1 ea. | Greater/Equal/Less comparator flags |

---

## Protocol Timing

| Operation Type       | Output Valid After | Monitor Wait (CE-Active) | Notes |
|---|---|---|---|
| **Standard (Most)**  | 1 CE-active clock  | 2 posedges               | Output monitor skips `CE=0` cycles |
| **Timeout / ERR**    | Wait counter >= 16 | 2 posedges               | 5-bit counter tracks stall time between operands |
| **Multi-Cycle**      | 3 CE-active clocks | 4 posedges               | CMD 9 and 10 introduce a 2-cycle pipeline lag |

> The `alu_outmon` utilizes a `spawn_capture_thread()` background task with variable latency settings to accurately sample pipelined multiplication results without deadlocking the testbench.

---

## Known DUT Bugs

Six functional and structural bugs were identified and root-caused through scoreboard mismatches and elaboration warnings:

### Bug 1 — INC/DEC Command Swap (Arithmetic CMD 4, 6, 7)
The B-operand increment/decrement logic is swapped in the case statement. Additionally, the `INC_A` command passes data directly to the result without incrementing.
- **Evidence:** Scoreboard mismatch for `CMD=7` expected `RES=123` but actual was `125`.
- **Fix:** Correct the assignment blocks in the RTL `case` statement.

### Bug 2 — High-Impedance Comparator Outputs (Arithmetic CMD 8)
When the CMP command triggers a flag, the DUT drives `1'bz` (high-Z) on the two non-triggered comparator flags rather than `1'b0`. 
- **Fix:** Replace all `1'bz` assignments with `1'b0`.

### Bug 3 — SHL_MUL Incorrect Operation (Arithmetic CMD 10)
The DUT executes subtraction (`AU_out_tmp1 - AU_out_tmp2`) instead of multiplication.
- **Fix:** Change the arithmetic operator to `*`.

### Bug 4 — Logical OR Uses Boolean Operator (Logical CMD 2)
The OR command uses the boolean reduction operator `&&` instead of the bitwise `|` operator, causing outputs of strictly 0 or 1.
- **Fix:** Change `oprd1&&oprd2` to `oprd1|oprd2`.

### Bug 5 — ROR ERR Logic Inverted (Logical CMD 13)
The command sets `ERR = 1'b0` instead of `1'b1` during an invalid rotation (when OPB[7:4] != 0), silently suppressing the error.
- **Fix:** Invert the error assignment logic.

### Bug 6 — RES Port Width Mismatch
The DUT defines `RES` as 10-bit (`DW+1:0`), but the TB/Interface declares it as 16-bit (`2*DW-1:0`). This causes `vsim-3015` warnings and X-propagation in the upper 6 bits.
- **Fix:** Standardize the port width across the DUT and testbench.

---

## Testbench Architecture

A fully layered UVM environment separating the active stimulus path from the passive observation path.


```

┌─────────────────────────────────────────────────────────────┐
│                 alu_regression_test                         │
│ (alu_sanity_test · alu_corner_test · error · rand)          │
└────────────────────────────┬────────────────────────────────┘
│
┌────────────────────────────▼────────────────────────────────┐
│                       alu_env                               │
│                                                             │
│  ┌──────────────────────┐        ┌───────────────────────┐  │
│  │   alu_input_agent    │        │   alu_output_agent    │  │
│  │       (ACTIVE)       │        │       (PASSIVE)       │  │
│  │ ┌────────┐ ┌───────┐ │        │ ┌───────────────────┐ │  │
│  │ │sequen..│ │driver │ │        │ │    alu_outmon     │ │  │
│  │ └────┬───┘ └───┬───┘ │        │ │(spawn_capture_th.)│ │  │
│  │      │         │     │        │ └─────────┬─────────┘ │  │
│  │ ┌────▼─────────▼───┐ │        │           │           │  │
│  │ │    alu_inpmon    │ │        │           │           │  │
│  │ └────────┬─────────┘ │        │           │           │  │
│  └──────────┼───────────┘        └───────────┼───────────┘  │
│             │ inp_fifo               out_fifo│              │
│  ┌──────────▼────────────────────────────────▼───────────┐  │
│  │                     alu_scoreboard                    │  │
│  │           predict_output()  →  compare_tx()           │  │
│  └──────────────────────────┬────────────────────────────┘  │
│                             │                               │
│  ┌──────────────────────────▼────────────────────────────┐  │
│  │                 alu_coverage_subscriber               │  │
│  │             (alu_cg: 7 coverpoints, 3 crosses)        │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
│
┌────────────────────────────▼────────────────────────────────┐
│                    alu_interface & DUT                      │
│        (CLK, RST, CE, INP_VALID, CMD, OPA, OPB, RES)        │
│         + bind alu_assertions (concurrent SVA)              │
└─────────────────────────────────────────────────────────────┘

```

### Sequence Classes

| Class | Constraint / Action | Purpose |
|---|---|---|
| `alu_sanity_sequence` | 1 ADD, 5 rand Arith, 5 rand Logic | Baseline functionality check |
| `alu_corner_case_sequence` | MAX values, timeout staging | Stresses bounds and wait_counter |
| `alu_error_case_sequence` | `INP_VALID=01` x 17, `OPB > 0x0F` | Explicit error injection and detection |
| `alu_rand_sequence` | Random (+NUM_TX overridable) | High-volume constrained-random |

---

## SVA Assertions

| Assertion | Check Focus | Result |
|---|---|---|
| `p_no_x_control` | X/Z Propagation on control signals | ✅ Covered |
| `p_ce_hold` | Stability of outputs while CE=0 | ✅ Covered |
| `p_flag_mutual_exclusion` | Comparator flags one-hot exclusivity | ✅ Covered |
| `p_valid_cmd_range` | CMD bounds based on current MODE | ✅ Covered |

> All four assertions achieved **100.00% coverage** during the regression suite. 

---

## Simulation Results


```

─────────────────────────────────────────────
Regression Summary
─────────────────────────────────────────────
Total Scoreboard Comparisons : 10,030
Passed                       : 2,137 (21.3%)
Failed                       : 7,893 (78.7%)
Elaboration Warnings         : 2 (vsim-3015)
*** 6 Structural/Functional Bugs Found ***
─────────────────────────────────────────────
Simulation End Time          : 100,815 ns
Functional Coverage (alu_cg) : 80.00%
Overall Code Coverage        : 86.45%
─────────────────────────────────────────────

```

| Test | Class | Notes | Transactions |
|---|---|---|---|
| t0 | `alu_sanity_test` | Basic ADD and Mode sweeps | 11 |
| t1 | `alu_corner_test` | Overflow, Carry, Pipeline lag checks | 16 |
| t2 | `alu_error_test` | Timeout and invalid rotation | 3 |
| t3 | `alu_rand_test` | 10,000 randomized transactions | 10,000 |

> Note: The high failure count (7,893) is a direct, expected result of the 6 documented RTL bugs, heavily exacerbated by the `1'bz` driver and `RES` port width mismatch propagating throughout random generation.

---

## Coverage Report

Generated from Questa SIM v10.6c.

| Coverage Type  | Bins | Hits | Misses | Coverage |
|---|---|---|---|---|
| Statements     | 117  | 97   | 20     | **82.90%** |
| Branches       | 73   | 64   | 9      | **87.67%** |
| FEC Conditions | 20   | 11   | 9      | **55.00%** |
| Toggles        | 204  | 190  | 14     | **93.13%** |
| FSM States     | 3    | 3    | 0      | **100.00%** |
| FSM Transitions| 4    | 4    | 0      | **100.00%** |
| Assertions     | 4    | 4    | 0      | **100.00%** |
| **Total (Hierarchical)** | — | — | — | **86.45%** |
| **Functional (alu_cg)**  | — | — | — | **80.00%** |

---

## How to Run

### Prerequisites
- Mentor Questa SIM (v10.6c recommended)
- SystemVerilog/UVM-1.1d compatible simulator

### Compile & Simulate

```bash
# Compile sequence (order matters)
vlog -sv tb/alu_interface.sv \
         tb/alu_pkg.sv \
         src/ALU_DESIGN.sv \
         tb/tb_top.sv

# Run comprehensive regression with coverage and assertions
vsim work.tb_top -coverage -assertdebug -c \
  -do "coverage save -onexit -assert -directive -cvg -codeAll alu_coverage.ucdb; run -all; exit"

# Generate HTML coverage report
vcover report -html alu_coverage.ucdb -htmldir covReport -details

```

### Run Specific Test (Example: Random Test with Custom TX Count)

```bash
vsim work.tb_top -coverage -c \
  +UVM_TESTNAME=alu_rand_test +NUM_TX=5000 \
  -do "run -all; exit"

```

---

## Tool Information

| Item | Details |
| --- | --- |
| Simulator | Mentor Questa SIM v10.6c |
| Methodology | UVM-1.1d |
| Language | SystemVerilog |
| Verification Target | Parameterized CE-Gated ALU |
| Total Transactions | 10,030 |
| Author | Jonathan Ezekiels (Employee ID: 6897) |

```

```
