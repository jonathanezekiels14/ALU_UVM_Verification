class alu_env extends uvm_env;
	`uvm_component_utils(alu_env)

	// declare components and config
	alu_input_agent in_agent;
	alu_output_agent out_agent;
	alu_scoreboard scbd;
	alu_coverage_subscriber cov_sub;
	alu_config cfg;

	// constructor
	function new(string name = "alu_env", uvm_component parent);
		super.new(name, parent);
	endfunction

	// build phase
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
			`uvm_fatal("ALU_ENV", "Failed to get alu_config from database");

		// apply config setting to the input agent state
		uvm_config_db#(uvm_active_passive_enum)::set(this, "in_agent", "is_active", cfg.is_active);

		in_agent = alu_input_agent::type_id::create("in_agent", this);
		out_agent = alu_output_agent::type_id::create("out_agent", this);
		scbd = alu_scoreboard::type_id::create("scbd", this);
		cov_sub = alu_coverage_subscriber::type_id::create("cov_sub", this);
	endfunction

	// connect phase
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		// connect input agent to scoreboard
		in_agent.agent_inp_port.connect(scbd.inp_export);
		// connect output agent to scoreboard
		out_agent.agent_out_port.connect(scbd.out_export);
		// connect input agent to coverage subscriber
		in_agent.agent_inp_port.connect(cov_sub.analysis_export);
	endfunction

endclass
