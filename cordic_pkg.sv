package cordic_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class cordic_item extends uvm_sequence_item;
        `uvm_object_utils(cordic_item)
        
        int degree;
        logic [31:0] theta_q214;

        function new(string name = ""); super.new(name); endfunction

        function void convert_to_q();
            real rad;
            int wrapped_deg; 
            
            wrapped_deg = degree;
            // Normalize angles to [-180, 180]
            while (wrapped_deg > 180)  wrapped_deg -= 360;
            while (wrapped_deg < -180) wrapped_deg += 360;
            
            rad = (real'(wrapped_deg) * 3.1415926535) / 180.0;
            theta_q214 = $rtoi(rad * 16384.0);
        endfunction
    endclass

    `include "cordic_driver.sv"

    class cordic_sequence extends uvm_sequence#(cordic_item);
        `uvm_object_utils(cordic_sequence)
        function new(string name = ""); super.new(name); endfunction

        task body();
            cordic_item it;
            int fd, status, degree_val;
            
            fd = $fopen("degrees.txt", "r");
            if (!fd) begin
                $display("FATAL: Could not open degrees.txt");
                $finish;
            end
            
            while (!$feof(fd)) begin
                status = $fscanf(fd, "%d\n", degree_val);
                if (status == 1) begin
                    it = cordic_item::type_id::create("it");
                    start_item(it);
                    it.degree = degree_val;
                    it.convert_to_q();
                    finish_item(it);
                end
            end
            $fclose(fd);
        endtask
    endclass

    class cordic_base_test extends uvm_test;
        `uvm_component_utils(cordic_base_test)
        cordic_driver drv;
        uvm_sequencer#(cordic_item) seqr;

        function new(string name, uvm_component parent); super.new(name, parent); endfunction

        function void build_phase(uvm_phase phase);
            drv  = cordic_driver::type_id::create("drv", this);
            seqr = uvm_sequencer#(cordic_item)::type_id::create("seqr", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            drv.seq_item_port.connect(seqr.seq_item_export);
        endfunction

        task run_phase(uvm_phase phase);
            cordic_sequence seq = cordic_sequence::type_id::create("seq");
            phase.raise_objection(this);
            seq.start(seqr);
            #2000ns; // Wait for pipeline to empty
            phase.drop_objection(this);
        endtask
    endclass
endpackage