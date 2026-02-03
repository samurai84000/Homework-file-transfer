module bg_subtract 
#(
	parameter THRESHOLD = 50
)
(
	input  logic		clk,
	input  logic		rst,

	input  logic		init_fifo_empty,
	input  logic [7:0]  init_frame_data,
	input  logic		new_fifo_empty,
	input  logic [7:0]  new_frame_data,
	input  logic		fifo_full,

	output logic		comp_RE,
	output logic		RE,
	output logic		WE,
	output logic [7:0]  comp_frame
);

typedef enum logic [1:0] {s0, s1} state_t;
state_t state, state_c;

logic [7:0] diff, diff_c;

always_ff @ (posedge clk, posedge rst)
begin
	if (rst == 1'b1) begin
		state <= s0;
		diff <= 8'h0;
	end else begin
		state <= state_c;
		diff <= diff_c;
	end
end

always_comb begin
	comp_RE    = 1'b0;
	RE = 1'b0;

	WE    = 1'b0;
	comp_frame   = 'h0;
	state_c   = state;
	diff_c    = diff;

	case (state)
		s0: begin
			if ( (!init_fifo_empty) && (!new_fifo_empty) )
			begin
				diff_c = 
					init_frame_data > new_frame_data
					? init_frame_data - new_frame_data
					: new_frame_data - init_frame_data; 
				diff_c = diff_c > THRESHOLD ? 8'hff : 8'h0;

				comp_RE    = 'b1;
				RE = 'b1;

				state_c = s1;
			end
		end

		s1: begin
			if (fifo_full == 1'b0)
			begin
				comp_frame = diff;
				WE = 'b1;

				state_c = s0;
			end
		end

		default: begin
			comp_RE    = 'b0;
			RE = 'b0;
			WE      = 'b0;
			comp_frame     = 'h0;
			state_c     = s0;
			diff_c      = 'hx;
		end

	endcase
end

endmodule
