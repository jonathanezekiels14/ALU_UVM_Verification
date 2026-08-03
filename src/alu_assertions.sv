`include "alu_defines.svh"

module alu_assertions (
  input logic                  CLK,
  input logic                  RST,       // Synchronous active-high reset
  input logic                  CE,
  input logic [1:0]            INP_VALID,
  input logic                  MODE,
  input logic [`CW-1:0]        CMD,
  input logic                  CIN,
  input logic [`DW-1:0]        OPA,
  input logic [`DW-1:0]        OPB,
  input logic [(2*`DW)-1:0]    RES,
  input logic                  ERR,
  input logic                  COUT,
  input logic                  OFLOW,
  input logic                  G,
  input logic                  L,
  input logic                  E
);

  default clocking cb @(posedge CLK);
    default input #1ns output #1ns;
  endclocking

  // 1. X/Z Propagation Checks on Control Signals
  property p_no_x_control;
    disable iff (RST)
      !$isunknown({CE, INP_VALID, MODE, CMD});
  endproperty
  
  assert_no_x_control: assert property (p_no_x_control)
    else $error("SVA_ERROR: Unknown (X/Z) detected on critical ALU control signals!");

  // 2. Clock Enable (CE) Stability Check
  property p_ce_hold;
    disable iff (RST)
      (!CE) |-> ($stable(RES) && $stable(ERR) && $stable(COUT) && $stable(OFLOW) && $stable(G) && $stable(L) && $stable(E));
  endproperty

  assert_ce_hold: assert property (p_ce_hold)
    else $error("SVA_ERROR: ALU outputs changed while Clock Enable (CE) was low!");

  // 3. Comparator Flags Mutual Exclusivity Check
  property p_flag_mutual_exclusion;
    disable iff (RST)
      $onehot0({G, L, E});
  endproperty

  assert_flag_mutual_exclusion: assert property (p_flag_mutual_exclusion)
    else $error("SVA_ERROR: Comparator flags (G, L, E) violate mutual exclusivity!");

  // 4. Command Range Sanity Check
  property p_valid_cmd_range;
    disable iff (RST)
      (MODE == 0) -> (CMD <= 12) &&
      (MODE == 1) -> (CMD <= 10);
  endproperty

  assert_valid_cmd_range: assert property (p_valid_cmd_range)
    else $error("SVA_ERROR: Invalid ALU command code executed for the current MODE!");

  // 5. Functional Coverage Properties (Coverpoints for SVA)
  cover_arithmetic_mode: cover property (disable iff (RST) (MODE == 0 && CE));
  cover_logical_mode:    cover property (disable iff (RST) (MODE == 1 && CE));
  cover_overflow_event:  cover property (disable iff (RST) (OFLOW == 1));
  cover_cout_event:      cover property (disable iff (RST) (COUT == 1));
  cover_error_event:     cover property (disable iff (RST) (ERR == 1));

endmodule
