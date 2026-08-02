class alu_env extends uvm_env;
  `uvm_component_utils(alu_env)

  alu_input_agent         in_agent;
  alu_output_agent        out_agent;
  alu_scoreboard          scbd;
  alu_coverage_subscriber cov_sub;
  alu_config              cfg;

  function new(string name = "alu_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
      `uvm_fatal("ALU_ENV", "Failed to get alu_config from database");

    in_agent  = alu_input_agent::type_id::create("in_agent", this);
    out_agent = alu_output_agent::type_id::create("out_agent", this);
    scbd      = alu_scoreboard::type_id::create("scbd", this);
    cov_sub   = alu_coverage_subscriber::type_id::create("cov_sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // 1. Connect Input Agent to Scoreboard Input Port
    in_agent.agent_inp_port.connect(scbd.inp_imp);

    // 2. Connect Output Agent to Scoreboard Output Port
    out_agent.agent_out_port.connect(scbd.out_imp);

    // 3. Connect Input Agent to Coverage Subscriber (or connect output agent depending on preference)
    in_agent.agent_inp_port.connect(cov_sub.analysis_export);
  endfunction

endclass
