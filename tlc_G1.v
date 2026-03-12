module tlc (
	input wire clk,
	input wire request,
	input wire reset,
	output reg [4:0] \output
);
 localparam G = 2'd0,
				Y = 2'd1,
				R = 2'd2,
				G1 = 2'd3;
 reg [1:0] state;
 reg request2;
 reg [28:0] count;
 always @(posedge clk or negedge reset) begin
	if (!reset) begin
		state <= G;
		count <= 29'd0;
	end
	else begin
		case (state)
			G: begin
					if (request == 1'b0) begin
						state <= Y;
						count <= 29'd0;
					end
				end
			Y: begin
					if (count == 29'd250000000) begin
						state <= R;
						count <= 29'd0;
					end 
					else begin
						count <= count + 29'd1;
					end
				end
			R: begin
					if (count == 29'd500000000) begin
						state <= G1;
						count <= 29'd0;
					end 
					else begin
						count <= count + 29'd1;
					end
				end
			G1:begin
					if (count == 29'd5000000000 && request2 == 1'b0) begin
						state <= G;
						count <= 29'd0;
					end
					else if (count == 29'd500000000 && request2 == 1'b1) begin
						state <= Y;
						count <= 29'd0;
						request2 <= 1'b0;
					end
					else if (request == 1'b0) begin
						request2 <= 1'b1;
						count <= count + 29'd1;
					end
					else begin
						count <= count + 29'd1;
					end
				end
			default: begin
					state <= G;
					count <= 29'd0;
					request2 <= 1'b0;
				end
		endcase
	end
 end
 always @(*) begin
	case (state)
		G: \output = 5'b10001;
		Y: \output = 5'b01001;
		R: \output = 5'b00110;
		default: \output = 5'b10001;
	endcase
end
endmodule