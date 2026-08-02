`include "alu_defines.svh"
`include "alu_interface.sv"
`include "alu_assertions.sv"
`include "alu_pkg.sv"

module tb_top;
  import uvm_pkg::*;
  import alu_pkg::*;

  // 1. Clock Signal
  logic CLK;

  // 2. Clock Generation (10ns period -> 100 MHz)
  initial begin
    CLK = 1'b0;
    forever #5 CLK = ~CLK;
  end

  // 3. Interface Instantiation
  alu_interface vif (CLK);

  // 4. DUT Instantiation
  ALU_DESIGN #(.DW(`DW), .CW(`CW)) u_dut (
    .CLK       (vif.CLK),
    .RST       (vif.RST),
    .CE        (vif.CE),
    .INP_VALID (vif.INP_VALID),
    .MODE      (vif.MODE),
    .CMD       (vif.CMD),
    .CIN       (vif.CIN),
    .OPA       (vif.OPA),
    .OPB       (vif.OPB),
    .RES       (vif.RES),
    .ERR       (vif.ERR),
    .COUT      (vif.COUT),
    .OFLOW     (vif.OFLOW),
    .G         (vif.G),
    .L         (vif.L),
    .E         (vif.E)
  );

  // 5. Initial Reset & Signal Initialization Driver
  initial begin
    vif.CE        = 1'b0;
    vif.INP_VALID = 2'b00;
    vif.MODE      = 1'b0;
    vif.CMD       = '0;
    vif.CIN       = 1'b0;
    vif.OPA       = '0;
    vif.OPB       = '0;

    vif.RST       = 1'b1;
    repeat (2) @(posedge CLK);
    vif.RST       = 1'b0;
    `uvm_info("TB_TOP", "Initial Reset Released.", UVM_LOW)
  end

  // 6. UVM Startup Block (Calls run_test() immediately at time 0)
  initial begin
    uvm_config_db#(virtual alu_interface)::set(null, "*", "vif", vif);
    run_test();
  end

  // 7. Safety Timeout Guard
  initial begin
    #5000000;
    `uvm_fatal("TB_TOP", "Simulation timeout reached! Deadlock detected.")
    $finish;
  end

  // 8. Bind Assertions to the DUT
  bind ALU_DESIGN alu_assertions u_alu_sva (
    .CLK       (vif.CLK),
    .RST       (vif.RST),
    .CE        (vif.CE),
    .INP_VALID (vif.INP_VALID),
    .MODE      (vif.MODE),
    .CMD       (vif.CMD),
    .CIN       (vif.CIN),
    .OPA       (vif.OPA),
    .OPB       (vif.OPB),
    .RES       (vif.RES),
    .ERR       (vif.ERR),
    .COUT      (vif.COUT),
    .OFLOW     (vif.OFLOW),
    .G         (vif.G),
    .L         (vif.L),
    .E         (vif.E)
  );

endmodule
