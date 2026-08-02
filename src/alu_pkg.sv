`ifndef ALU_PKG_SV
`define ALU_PKG_SV

package alu_pkg;
  // Import UVM standard library and macros
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Include global defines
  `include "alu_defines.svh"

  // 1. Transaction Item
  `include "alu_transaction.sv"
  `include "alu_env_config.sv" 
  // 2. Sequences
  `include "alu_base_sequence.sv"
  `include "alu_sanity_sequence.sv"
  `include "alu_rand_sequence.sv"
  `include "alu_corner_case_sequence.sv"
  `include "alu_error_case_sequence.sv"

  // 3. Sequencer
  `include "alu_sequencer.sv"

  // 4. Driver & Monitors
  `include "alu_driver.sv"
  `include "alu_inmonitor.sv"
  `include "alu_outmonitor.sv"

  // 5. Agents
  `include "alu_input_agent.sv"
  `include "alu_output_agent.sv"

  // 6. Scoreboard & Coverage Subscriber
  `include "alu_scoreboard.sv"
  `include "alu_coverage_subscriber.sv"

  // 7. Environment
  `include "alu_environment.sv"

  // 8. Tests
  `include "alu_base_test.sv"
  `include "alu_sanity_test.sv"
  `include "alu_rand_test.sv"
  `include "alu_corner_test.sv"
  `include "alu_error_test.sv"
  `include "alu_regression_test.sv"

endpackage

`endif
