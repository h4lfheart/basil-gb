import cpu_types::*;

module cpu_clock(
    input logic clk,
    input logic rst,
    input logic rst_mcycle,
    input logic halt_hold,
    input logic halt_align,
    input logic stall_req,
    output logic stalled,
    output logic [1:0] tcycle,
    output logic [2:0] mcycle
);

    logic ready;

    always_ff @(posedge clk) begin
        if (rst) begin
            tcycle <= 0;
            ready <= 0;
            mcycle <= 0;
            stalled <= 0;
        end else if (!ready) begin
            mcycle <= 0;
            tcycle <= 0;
            ready <= 1;
            stalled <= 0;
        end else if (halt_align) begin
            tcycle <= T0;
            mcycle <= M0;
            stalled <= 0;
        end else if (stalled) begin
            tcycle <= T0;
            if (!stall_req)
                stalled <= 0;
        end else begin
            if (stall_req && tcycle == T3)
                stalled <= 1;

            tcycle <= tcycle + 1;

            if (tcycle == T3) begin
                if (rst_mcycle)
                    mcycle <= M0;
                else if (!halt_hold)
                    mcycle <= mcycle + 1;
            end
        end
    end
endmodule
