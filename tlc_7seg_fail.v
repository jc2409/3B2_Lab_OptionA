module tlc (
	input wire clk,
	input wire request,
	input wire reset,
	output reg [6:0] hex1,hex2,
	output reg [4:0] \output
);
 localparam G = 2'd0,
				Y = 2'd1,
				R = 2'd2,
				G1 = 2'd3;
 reg [1:0] state;
 reg request2;
 reg [28:0] count, countb;
 reg [3:0] bcd;
 reg [3:0] bcd0;
 
 //main counters and state diagram logic
 always @(posedge clk or negedge reset) begin
	if (!reset) begin
		state <= G;
		count <= 29'd0;
		bcd0 <= 4'd15; //unused state for 'off'
	end
	else begin
		case (state)
			G: begin
					if (request == 1'b0) begin
						state <= Y;
						count <= 29'd0;
						bcd0 <= 4'd5; //Initiate bcd counter for 5s
					end
				end
			Y: begin
					if (count == 29'd250000000) begin
						state <= R;
						count <= 29'd0;
						bcd0 <= 4'd10;//initiate bcd counter for 10s
					end 
					else begin
						count <= count + 29'd1;
					end
				end
			R: begin
					if (count == 29'd500000000) begin
						state <= G1;
						count <= 29'd0;
						bcd0 <= 4'd0;
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
						bcd0 <= 4'd5; //initiate bcd counter for 5s
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
					bcd0 <= 4'd15;
				end
		endcase
	end
 end
 //Define state outputs
 always @(*) begin
	case (state)
		G: \output = 5'b10001;
		Y: \output = 5'b01001;
		R: \output = 5'b00110;
		default: \output = 5'b10001;
	endcase
end

//define bcd countdown
always @(posedge clk or negedge reset) begin
	if (reset == 1'b1) begin
		bcd <= 4'd15;
		countb <= 29'd0;
	end
	else if (bcd0 != 4'd15) begin
			bcd <= bcd0;
	end
	else begin
		case(bcd)
			4'd0: begin
						if (countb == 29'd50000000) begin
							bcd <= 4'd15;
							countb <= 29'd0;
						end 
						else begin
							countb <= countb + 29'd1;
						end
					end
			4'd15: bcd <= 4'd15;
			default: begin
						if (countb == 29'd50000000) begin
							bcd <= bcd - 4'b1;
							countb <= 29'd0;
						end 
						else begin
							countb <= countb + 29'd1;
						end
					end
		endcase
	end
end

//7 seg case structure
always @(*) begin
	case(bcd)
		4'd0: begin
				hex1 = 7'b1000000;
				hex2 = 7'b1000000;
				end
		4'd1: begin
				hex1 = 7'b1000000;
				hex2 = 7'b1111001;
				end
		4'd2: begin
				hex1 = 7'b1000000;
				hex2 = 7'b0100100;
				end
		4'd3: begin
				hex1 = 7'b1000000;
				hex2 = 7'b0110000;
				end
		4'd4: begin
				hex1 = 7'b1000000;
				hex2 = 7'b0011001;
				end
		4'd5: begin
				hex1 = 7'b1000000;
				hex2 = 7'b0010010;
				end
		4'd6: begin
				hex1 = 7'b1000000;
				hex2 = 7'b0000010;
				end
		4'd7: begin
				hex1 = 7'b1000000;
				hex2 = 7'b1111000;
				end
		4'd8: begin
				hex1 = 7'b1000000;
				hex2 = 7'b0000000;
				end
		4'd9: begin
				hex1 = 7'b1000000;
				hex2 = 7'b0010000;
				end
		4'd10: begin
				hex1 = 7'b1111001;
				hex2 = 7'b1000000;
				end
		default: begin
					hex1 = 7'b1111111;
					hex2 = 7'b1111111;
					end
	endcase
end
endmodule