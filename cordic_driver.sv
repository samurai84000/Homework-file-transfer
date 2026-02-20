class cordic_driver extends uvm_driver#(cordic_item);
    `uvm_component_utils(cordic_driver)
    virtual cordic_if vif;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_resource_db#(virtual cordic_if)::read_by_name("ifs", "vif", vif)) begin
            $display("CRITICAL: Driver cannot find Virtual Interface!");
            $fatal(1);
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.theta_wr_en <= 1'b0;
        wait(vif.reset == 1'b0);
        @(posedge vif.clk);

        forever begin
            cordic_item tx;
            seq_item_port.get_next_item(tx);
            vif.theta_din   <= tx.theta_q214;
            vif.theta_wr_en <= 1'b1;
            do begin
                @(posedge vif.clk);
            end while (vif.theta_full === 1'b1);
            vif.theta_wr_en <= 1'b0;
            seq_item_port.item_done();
        end
    endtask
endclass