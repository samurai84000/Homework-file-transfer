module Sobel(
	input  logic clk;
	input  logic rst;
	input  logic[7:0] pixel_in;
	
	output logic[7:0] sobel_pixel;
);

typedef enum logic [1:0] {init, reading, sobel_process} states;
states curr_state, next_state;

//Internal Logic
logic [7:0] prev_pixel_row[0:719];
logic [7:0] curr_pixel_row[0:719];
logic [7:0] next_pixel_row[0:2];

logic [9:0] counter;
logic [1:0]counter_looparound;
logic [2:0] next_counter;
always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		counter <= 0;
		curr_state <=init;
		counter_looparound <=0;
		
	end else begin
		curr_state <= next_state;
	end
end

always_comb begin
	counter = 9'b0;
	counter_looparound = 2'b0;
	case (state)
		init:
		next_state = reading;
		end
		
		reading:	
		begin
			if(counter_looparound == 1)begin //second runthrough
				if(counter < 719)begin
					curr_pixel_row[counter] <= pixel_in;
					counter +=1;
				end else begin
					curr_pixel_row[counter] <= pixel_in;
					counter_looparound += 1;
					counter = 0;
				end
			else if(counter_looparound == 2)begin//final runthrough
				if(next_counter < 1)begin
					next_pixel_row[next_counter] <= pixel_in;
					next_counter += 1
					next_state = sobel_process;
				end
			end else begin //first runthrough
				if(counter <= 718)begin
					prev_pixel_row[counter] <= pixel_in;
					counter+=1;
				end else begin
					prev_pixel_row[counter] <= pixel_in;
					counter = 0;
					counter_looparound+=1;
				end
			end
		end

		sobel_process:
			begin
				if(counter < 719)begin
					if(counter == 0) begin
						sobel_pixel <= 8'b255;
					else if(counter < 719)begin
						next_pixel_row[next_counter] <= pixel_in;//should be locked in at indes 3for first ru
				
				end
				
			end
		end
		endcase
end
endmodule
