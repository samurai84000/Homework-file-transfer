class cordic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cordic_scoreboard)
    
    // Uses a queue to store expected results calculated from inputs
    real expected_sin_q[$];
    real expected_cos_q[$];

    virtual function void write_input(cordic_item item);
        expected_sin_q.push_back($sin((real'(item.degree) * 3.1415926535) / 180.0));
        expected_cos_q.push_back($cos((real'(item.degree) * 3.1415926535) / 180.0));
    endfunction

    virtual function void write_output(cordic_item item);
        real hw_sin = real'($signed(item.sin_out)) / 16384.0;
        real gold_sin = expected_sin_q.pop_front();
        
        if (abs(hw_sin - gold_sin) > 0.001) 
            `uvm_error("SCBD", $sformatf("Mismatch! HW: %f, Gold: %f", hw_sin, gold_sin))
        else
            `uvm_info("SCBD", "Match!", UVM_LOW)
    endfunction
endclass