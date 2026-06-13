module cpu_idu(
    input logic [15:0] in,
    input logic signed [1:0] adj,
    output logic [15:0] out
);
    always_comb
        out = in + 16'(signed'(adj));

endmodule