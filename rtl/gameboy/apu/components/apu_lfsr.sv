module apu_lfsr(
    input logic clk,
    input logic rst,
    input logic clear,
    input logic tick,
    input logic trigger,
    input logic width_mode,
    output logic digital
);
    logic [14:0] lfsr;
    logic [14:0] lfsr_next;

    always_comb begin
        lfsr_next = {lfsr[0] ^ lfsr[1], lfsr[14:1]};
        if (width_mode)
            lfsr_next[6] = lfsr[0] ^ lfsr[1];
    end

    assign digital = !lfsr[0];

    always_ff @(posedge clk) begin
        if (rst || clear || trigger)
            lfsr <= '1;
        else if (tick)
            lfsr <= lfsr_next;
    end

endmodule
