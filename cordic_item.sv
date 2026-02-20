class cordic_item extends uvm_sequence_item;
    `uvm_object_utils(cordic_item)

    rand int degree;
    logic [31:0] theta_q214;

    function new(string name = ""); 
        super.new(name); 
    endfunction

    constraint c_deg { degree >= -180; degree <= 180; }

    function void post_randomize();
        real rad = (real'(degree) * 3.14159) / 180.0;
        theta_q214 = $rtoi(rad * 16384.0);
    endfunction
endclass