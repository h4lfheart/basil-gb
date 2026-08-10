module apu_duty(
    input logic clk,
    input logic rst,
    input logic clear,
    input logic tick,
    input logic trigger,
    input logic [1:0] duty,
    output logic digital
);
    logic [2:0] position;
    logic [7:0] pattern;

    always_comb begin
        case (duty)
            'd0: pattern = 8'b00000001;
            'd1: pattern = 8'b10000001;
            'd2: pattern = 8'b10000111;
            'd3: pattern = 8'b01111110;
        endcase
    end

    assign digital = pattern[position];

    always_ff @(posedge clk) begin
        if (rst || clear || trigger)
            position <= '0;
        else if (tick)
            position <= position + 'd1;
    end
endmodule
