class alu_coverage_subscriber extends uvm_subscriber #(alu_transaction);
  `uvm_component_utils(alu_coverage_subscriber)

  alu_transaction tx_item;

  // Covergroup matching your ALU coverage plan
  covergroup alu_cg;
    option.per_instance = 1;

    cp_ce: covergroup cp_ce {
      bins ce_inactive = {0};
      bins ce_active   = {1};
    }

    cp_opa: covergroup cp_opa {
      bins zero     = {32'h00000000};
      bins max_val  = {32'hFFFFFFFF};
      bins mid_val  = {[32'h00000001:32'hFFFFFFFE]};
    }

    cp_opb: covergroup cp_opb {
      bins zero     = {32'h00000000};
      bins max_val  = {32'hFFFFFFFF};
      bins mid_val  = {[32'h00000001:32'hFFFFFFFE]};
    }

    cp_mode: covergroup cp_mode {
      bins arithmetic = {0};
      bins logical    = {1};
    }

    cp_cmd: covergroup cp_cmd {
      bins cmds[] = {[0:13]};
    }

    cp_inpv: covergroup cp_inpv {
      bins val_none  = {2'b00};
      bins val_opa   = {2'b01};
      bins val_opb   = {2'b10};
      bins val_both  = {2'b11};
    }

    cp_cin: covergroup cp_cin {
      bins cin_0 = {0};
      bins cin_1 = {1};
    }

    cp_modexcmd: cross cp_mode, cp_cmd;
    cp_cmdxinpv: cross cp_inpv, cp_cmd;
    cp_cinxcmd:  cross cp_cin,  cp_cmd;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    alu_cg = new();
  endfunction

  virtual function void write(alu_transaction t);
    this.tx_item = t;
    alu_cg.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("ALU_COV", $sformatf("Functional Coverage = %0.2f%%", alu_cg.get_inst_coverage()), UVM_LOW)
  endfunction

endclass
