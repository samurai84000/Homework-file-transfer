module fibonacci (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [15:0] din,
    output logic [15:0] dout,
    output logic        done
);

    typedef enum logic [1:0] {INIT, RUN, FINISH} state_t;
    state_t state, state_c;


    logic [15:0] a, b;      
    logic [15:0] a_c, b_c;
    logic [15:0] count, count_c;
    logic        done_c;
    logic [15:0] dout_c;


    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INIT;
            a     <= 16'd0;
            b     <= 16'd0;
            count <= 16'd0;
            done  <= 1'b0;
            dout  <= 16'd0;
        end
        else begin
            state <= state_c;
            a     <= a_c;
            b     <= b_c;
            count <= count_c;
            done  <= done_c;
            dout  <= dout_c;
        end
    end


    always_comb begin

        state_c = state;
        a_c     = a;
        b_c     = b;
        count_c = count;
        done_c  = done;
        dout_c  = dout;

        case (state)

            INIT: begin
                if (start) begin
                    a_c     = 16'd0;  
                    b_c     = 16'd1;  
                    count_c = 16'd1;
                    done_c  = 1'b0;
                    state_c = RUN;
                end
            end

            RUN: begin
                a_c     = b;
                b_c     = a + b;
                count_c = count + 16'd1;

                if (count + 16'd1 >= din) begin
                    dout_c  = a + b;   
                    done_c  = 1'b1;
                    state_c = FINISH;
                end
            end

            FINISH: begin
                done_c = 1'b1; 
            end

            default: begin
                state_c = INIT;
            end

        endcase
    end

endmodule
