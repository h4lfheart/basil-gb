import cpu_types::*;

module cpu_clock(
    input logic clk,
    input logic rst,
    input logic rst_mcycle,
    output logic [1:0] tcycle,
    output logic [2:0] mcycle
);

    logic ready;

    always_ff @(posedge clk) begin
        if (rst) begin
            tcycle <= 0;
            ready <= 0;
            mcycle <= 0;
        end else if (!ready) begin
            mcycle <= 0;
            tcycle <= 0;
            ready <= 1;
        end else begin
            tcycle <= tcycle + 1;

            if (tcycle == T3)
                mcycle <= rst_mcycle ? M0 : mcycle + 1;
        end
    end
endmodule