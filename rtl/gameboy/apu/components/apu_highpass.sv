module apu_highpass #(
    parameter int WIDTH = 10,
    parameter int FRAC = 20,
    parameter int CHARGE = 1048532
)(
    input logic clk,
    input logic rst,
    input logic enable,
    input logic signed [WIDTH-1:0] in,
    output logic signed [WIDTH-1:0] out
);
    localparam int LEAK = (1 <<< FRAC) - CHARGE;
    localparam int ACCW = WIDTH + FRAC + 4;
    localparam logic signed [WIDTH:0] MAXV = (1 <<< (WIDTH - 1)) - 1;
    localparam logic signed [WIDTH:0] MINV = -(1 <<< (WIDTH - 1));

    logic signed [ACCW-1:0] capacitor;
    logic signed [WIDTH-1:0] cap_int;
    logic signed [WIDTH:0] out_wide;
    logic signed [WIDTH-1:0] out_clamped;

    assign cap_int = WIDTH'(capacitor >>> FRAC);
    assign out_wide = (WIDTH + 1)'($signed(in)) - (WIDTH + 1)'($signed(cap_int));

    always_comb begin
        if (out_wide > MAXV)
            out_clamped = MAXV[WIDTH-1:0];
        else if (out_wide < MINV)
            out_clamped = MINV[WIDTH-1:0];
        else
            out_clamped = out_wide[WIDTH-1:0];
    end

    always_ff @(posedge clk) begin
        if (rst || !enable) begin
            capacitor <= '0;
            out <= '0;
        end else begin
            out <= out_clamped;
            capacitor <= capacitor + ACCW'($signed(out_clamped) * LEAK);
        end
    end

endmodule
