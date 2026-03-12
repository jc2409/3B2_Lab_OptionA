module tlc_timer (
input wire CLOCK_50,
input wire [1:0] KEY,
output wire [5:0] LEDS,
output wire [6:0] HEX0,
output wire [6:0] HEX1
);
module FSM (
input wire clock, reset, request,
input wire tick,
input wire [3:0] timer1, timer0, //4 bit per digit
output wire req_status, state_event,
output wire [7:0] state_time, //combined digits
output wire [1:0] state
);
module counter #(
parameter integer n = 4, //4 bit for (0 to 9)
parameter integer k = 15 //set start_time
) (
input wire clock, reset, enable, load,
input wire [n-1:0] start_time,
output wire rollover,
output reg [n-1:0] count
);
module bcd7seg (
input wire [3:0] BCD, //4 bit for (0 to 9)
input wire [1:0] state, //2 bit for 4 states
output wire [6:0] HEX //7-segment
);
module light (
input wire status,
input wire [1:0] state, //2 bit for 4 states
output wire [5:0] LED //6 lights
);
wire one_second;
wire state_event;
wire req_status;
wire [1:0] state;
wire [7:0] state_time; // 8 bits for 2 digits
wire [3:0] BCD1, BCD0;
wire [1:0] roll; // one each digit
// State machine
FSM states (
.clock (CLOCK_50),
.reset (KEY[0]),
.request (KEY[1]),
.tick (one_second)
.timer1 (BCD1),
.timer0 (BCD0),
.req_status (req_status),
.state_event (state_event),
.state_time (state_time),
.state (state)
);
//Generate a 1 second clock signal by dividing CLOCK_50
counter #(.n(26), .k(50000000)) slow_clock (
.clock (CLOCK_50),
.reset (KEY[0]),
.enable (1'b1),
.load (1'b0),
.start_time (26'd0),
.count (),
.rollover (one_second)
);
// Ones digit counter
counter #(.n(4), .k(10)) ones (
.clock (CLOCK_50),
.reset (KEY[0]),
.enable (one_second),
.load (state_event),
.start_time (state_time[3:0]),
.count (BCD0),
.rollover ()
);
// Tens digit counter
counter #(.n(4), .k(10)) tens (
.clock (CLOCK_50),
.reset (KEY[0]),
.enable (one_second & (BCD0 == 4'd0)),
.load (state_event),
.start_time (state_time[7:4]),
.count (BCD1),
.rollover ()
);
// Convert BCD to seven segment
bcd7seg digit0 (
.BCD (BCD0),
.state (state),
.HEX (HEX0)
);
bcd7seg digit1 (
.BCD (BCD1),
.state (state),
.HEX (HEX1)
);
// Drive the LEDs
light lights (
.status (req_status),
.state (state),
.LED (LEDS)
);
endmodule
module FSM (
input wire clock, reset, request,
input wire tick,
input wire [3:0] timer1, timer0,
output wire state_event,
output wire req_status,
output wire [1:0] state,
output wire [7:0] state_time
);
-- encode states G-"00", Y-"01", R-"10", G1-"11"
reg st_event;
reg status;
reg [1:0] state_s;
reg [7:0] st_time;
reg second_req; //“remembered” when in G1: ‘0’ – no memory
always @(posedge clock or negedge reset) begin
if (!reset) begin
state_s <= 2'b00; //reset machine to initial values
second_req <= 1'b0;
status <= 1'b0;
st_event <= 1'b1;
st_time <= 8'b00000000;
end else begin
st_event <= 1'b0;
case (state_s)
2'b00: begin // G
if (request == 1'b0 || second_req) begin
state_s <= 2'b01; // Y
st_time <= 8'b00000101; // 5
st_event <= 1'b1;
second_req <= 1'b0;
status <= 1'b1; // WAIT indicator
end
end
2'b01: begin // Y
if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin
state_s <= 2'b10; // R
st_time <= 8'b00010000; // 10
st_event <= 1'b1;
status <= 1'b0;
end
end
2'b10: begin // R
if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin
state_s <= 2'b11; // G1
st_time <= 8'b00010000; // 10
st_event <= 1'b1;
end
end
2'b11: begin // G1
if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin
state_s <= 2'b00; // G
st_event <= 1'b1;
end else if (request == 1'b0) begin
second_req <= 1'b1;
status <= 1'b1;
end
end
endcase
end
end
assign state = state_s; // update outputs after process
assign state_time = st_time;
assign state_event = st_event;
assign req_status = status;
endmodule
// vector values as unsigned integers
/* basic arithmetic operations for representing integers */
module counter #(
parameter integer n = 4,
parameter integer k = 15
) (
input wire clock, reset, enable, load,
input wire [n-1:0] start_time,
output wire rollover,
output reg [n-1:0] count
);
assign rollover = (count == 0);
always @(posedge clock or negedge reset) begin
if (!reset) begin
count <= start_time; // reset timer to start_time
end else if (load) begin
count <= start_time; /* load next state time whenever the
state changes */
end else if (enable) begin
if (count != 0)
count <= count - 1'b1;
else
count <= k - 1;
end
end
endmodule
module bcd7seg (
input wire [3:0] BCD, // 4-bit BCD input
input wire [1:0] state, // 2-bit state input
output reg [6:0] HEX // 7-bit output (0 to 6 range)
);
always @(*) begin
// High priority: Check state first
if (state == 2'b00) begin
HEX = 7'b0111111; // "stand-by" when G
end else begin
case (BCD)
4'b0000: HEX = 7'b1000000; // 0
4'b0001: HEX = 7'b1111001; // 1
4'b0010: HEX = 7'b0100100; // 2
4'b0011: HEX = 7'b0110000; // 3
4'b0100: HEX = 7'b0011001; // 4
4'b0101: HEX = 7'b0010010; // 5
4'b0110: HEX = 7'b0000010; // 6
4'b0111: HEX = 7'b1111000; // 7
4'b1000: HEX = 7'b0000000; // 8
4'b1001: HEX = 7'b0010000; // 9
default: HEX = 7'b1111111;
endcase
end
end
endmodule
module light (
input wire status,
input wire [1:0] state,
output wire [5:0] LED
);
assign LED[5] = status; // request status (WAIT)
assign LED[4:0] = (state == 2'b00) ? 5'b10001 : // G
(state == 2'b01) ? 5'b10010 : // Y
(state == 2'b10) ? 5'b01100 : // R
5'b10001 ;
endmodule
