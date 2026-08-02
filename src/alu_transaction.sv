class alu_transaction extends uvm_sequence_item;
        
        `uvm_object_utils(alu_transaction)

        rand bit [`DW-1:0] OPA, OPB;
        rand bit [1:0] INP_VALID;
        rand bit [`CW-1:0] CMD;
        rand bit MODE, CIN, CE;
        
        logic [(2*`DW)-1:0] RES;
        logic ERR, COUT, OFLOW, G, L, E;

        constraint set_ce { 
                soft CE dist { 1 := 9, 0 := 1 }; 
        }

        constraint set_cmd { 
                (MODE == 0) -> soft CMD < 13;
                (MODE == 1) -> soft CMD < 11;
                solve MODE before CMD;
        }

        constraint set_cin { 
                soft CIN dist { 0 := 5, 1 := 5 };
        }

        function new(string name = "alu_transaction");
                super.new(name);
        endfunction

        virtual function void do_copy(uvm_object rhs);
                alu_transaction obj;
                if (!$cast(obj, rhs)) begin
                        `uvm_fatal("do_copy", "Casting of do_copy object failed");
                end
                super.do_copy(rhs);
                this.OPA = obj.OPA;
                this.OPB = obj.OPB;
                this.INP_VALID = obj.INP_VALID;
                this.CMD = obj.CMD;
                this.MODE = obj.MODE;
                this.CIN = obj.CIN;
                this.CE = obj.CE;
                this.RES = obj.RES;
                this.ERR = obj.ERR;
                this.COUT = obj.COUT;
                this.OFLOW = obj.OFLOW;
                this.G = obj.G;
                this.L = obj.L;
                this.E = obj.E;
        endfunction

        virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
                alu_transaction obj;
                if(!$cast(obj, rhs)) begin
                        `uvm_fatal("do_compare", "Cast for Comparing object failed");
                        return 0;
                end
                return (super.do_compare(rhs, comparer) &&
                        RES == obj.RES &&
                        ERR == obj.ERR &&
                        OFLOW == obj.OFLOW &&
                        COUT == obj.COUT &&
                        G == obj.G &&
                        L == obj.L &&
                        E == obj.E);
        endfunction

        virtual function void do_print(uvm_printer printer);
                super.do_print(printer);
                
                printer.print_field_int("OPA", OPA, $bits(OPA), UVM_HEX);
                printer.print_field_int("OPB", OPB, $bits(OPB), UVM_HEX);
                printer.print_field_int("INP_VALID", INP_VALID, $bits(INP_VALID), UVM_BIN);
                printer.print_field_int("CMD", CMD, $bits(CMD), UVM_DEC);
                printer.print_field_int("MODE", MODE, 1, UVM_BIN);
                printer.print_field_int("CIN", CIN, 1, UVM_BIN);
                printer.print_field_int("CE", CE, 1, UVM_BIN);
                
                printer.print_field_int("RES", RES, $bits(RES), UVM_HEX);
                printer.print_field_int("ERR", ERR, 1, UVM_BIN);
                printer.print_field_int("COUT", COUT, 1, UVM_BIN);
                printer.print_field_int("OFLOW", OFLOW, 1, UVM_BIN);
                printer.print_field_int("G", G, 1, UVM_BIN);
                printer.print_field_int("L", L, 1, UVM_BIN);
                printer.print_field_int("E", E, 1, UVM_BIN);
        endfunction

endclass
