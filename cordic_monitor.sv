class cordic_monitor extends uvm_monitor;
    `uvm_component_utils(cordic_monitor)
    virtual cordic_if vif;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_resource_db#(virtual cordic_if)::read_by_name("ifs", "vif", vif))
            `uvm_fatal("MON", "No_VIF")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            // Logic to capture output
            if (!vif.sin_empty && !vif.cos_empty) begin
                vif.sin_rd_en <= 1'b1;
                vif.cos_rd_en <= 1'b1;
                @(posedge vif.clk);
                `uvm_info("MON", $sformatf("Captured Sin: %0d, Cos: %0d", vif.sin_dout, vif.cos_dout), UVM_LOW)
                vif.sin_rd_en <= 1'b0;
                vif.cos_rd_en <= 1'b0;
            end
        end
    endtask
endclass