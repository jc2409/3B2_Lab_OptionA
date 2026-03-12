// Option A: Traffic Light Controller with Countdown Timer
// Uses the original counter approach, split into:
//   - tick:    cycles 0..49,999,999 (one-second timebase)
//   - seconds: counts elapsed seconds per state (drives transitions AND display)
//
// This avoids the long comparison chain -- time_remaining is just
// (max_seconds - seconds).

module tlc (
    input wire        clk,
    input wire        request,
    input wire        reset,
    output reg [4:0]  lights,     // {veh_G, veh_Y, veh_R, ped_G, ped_R}
    output reg [6:0]  hex0,       // 7-seg ones digit
    output reg [6:0]  hex1        // 7-seg tens digit
);

    localparam G = 2'd0;
    localparam Y = 2'd1;
    localparam R = 2'd2;
    localparam W = 2'd3;

    localparam TICKS_PER_SEC = 26'd50_000_000;

    reg [1:0]  state;
    reg [25:0] tick;       // sub-second counter: 0 to TICKS_PER_SEC-1
    reg [3:0]  seconds;    // elapsed seconds in current state

    // One-second pulse
    wire one_sec = (tick == TICKS_PER_SEC - 1);

    // -------------------------------------------------------
    // State machine (same structure as original tlc.v)
    // -------------------------------------------------------
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state   <= G;
            tick    <= 26'd0;
            seconds <= 4'd0;
        end else begin
            case (state)
                G: begin
                    tick    <= 26'd0;
                    seconds <= 4'd0;
                    if (request == 1'b0) begin
                        state <= Y;
                    end
                end
                Y: begin
                    if (one_sec) begin
                        tick <= 26'd0;
                        if (seconds == 4'd4) begin   // 5 seconds elapsed (0..4)
                            state   <= R;
                            seconds <= 4'd0;
                        end else begin
                            seconds <= seconds + 4'd1;
                        end
                    end else begin
                        tick <= tick + 26'd1;
                    end
                end
                R: begin
                    if (one_sec) begin
                        tick <= 26'd0;
                        if (seconds == 4'd9) begin   // 10 seconds elapsed (0..9)
                            state   <= W;
                            seconds <= 4'd0;
                        end else begin
                            seconds <= seconds + 4'd1;
                        end
                    end else begin
                        tick <= tick + 26'd1;
                    end
                end
                W: begin
                    if (one_sec) begin
                        tick <= 26'd0;
                        if (seconds == 4'd9) begin   // 10 seconds cooldown
                            state   <= G;
                            seconds <= 4'd0;
                        end else begin
                            seconds <= seconds + 4'd1;
                        end
                    end else begin
                        tick <= tick + 26'd1;
                    end
                end
                default: begin
                    state   <= G;
                    tick    <= 26'd0;
                    seconds <= 4'd0;
                end
            endcase
        end
    end

    // -------------------------------------------------------
    // Time remaining -- just a subtraction from the seconds counter
    // -------------------------------------------------------
    reg [3:0] time_remaining;

    always @(*) begin
        case (state)
            Y:       time_remaining = 4'd5  - seconds;  // counts 5,4,3,2,1
            R:       time_remaining = 4'd10 - seconds;  // counts 10,9,...,1
            W:       time_remaining = 4'd10 - seconds;
            default: time_remaining = 4'd0;              // blank in G
        endcase
    end

    // -------------------------------------------------------
    // LED outputs
    // -------------------------------------------------------
    always @(*) begin
        case (state)
            G: lights = 5'b10001;
            Y: lights = 5'b01001;
            R: lights = 5'b00110;
            W: lights = 5'b10001;
            default: lights = 5'b10001;
        endcase
    end

    // -------------------------------------------------------
    // 7-segment decoder (active-low for DE1-SoC)
    // hex[6:0] = {g, f, e, d, c, b, a}
    // -------------------------------------------------------
    reg [3:0] ones_digit;
    reg [3:0] tens_digit;

    always @(*) begin
        ones_digit = time_remaining % 10;
        tens_digit = time_remaining / 10;
    end

    always @(*) begin
        case (ones_digit)
            4'd0: hex0 = 7'b1000000;
            4'd1: hex0 = 7'b1111001;
            4'd2: hex0 = 7'b0100100;
            4'd3: hex0 = 7'b0110000;
            4'd4: hex0 = 7'b0011001;
            4'd5: hex0 = 7'b0010010;
            4'd6: hex0 = 7'b0000010;
            4'd7: hex0 = 7'b1111000;
            4'd8: hex0 = 7'b0000000;
            4'd9: hex0 = 7'b0010000;
            default: hex0 = 7'b1111111;
        endcase
    end

    always @(*) begin
        if (tens_digit == 4'd0)
            hex1 = 7'b1111111;        // blank leading zero
        else
            hex1 = 7'b1111001;        // can only be "1" (for 10)
    end

endmodule