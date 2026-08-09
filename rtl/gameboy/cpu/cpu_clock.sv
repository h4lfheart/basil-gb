import cpu_types::*;

module cpu_clock(
    input logic clk,
    input logic rst,
    input logic rst_mcycle,
    input logic halt_hold,
    input logic halt_align,
    input logic stall_req,
    output logic stalled,
    output tcycle_t tcycle,
    output mcycle_t mcycle
);

    logic ready;
    logic [1:0] tcycle_counter;
    logic [2:0] mcycle_counter;

    assign tcycle = tcycle_t'(tcycle_counter);
    assign mcycle = mcycle_t'(mcycle_counter);

    always_ff @(posedge clk) begin
        if (rst) begin
            tcycle_counter <= 0;
            ready <= 0;
            mcycle_counter <= 0;
            stalled <= 0;
        end else if (!ready) begin
            mcycle_counter <= 0;
            tcycle_counter <= 0;
            ready <= 1;
            stalled <= 0;
        end else if (halt_align) begin
            tcycle_counter <= 0;
            mcycle_counter <= 0;
            stalled <= 0;
        end else if (stalled) begin
            tcycle_counter <= 0;
            if (!stall_req)
                stalled <= 0;
        end else begin
            if (stall_req && tcycle_counter == 3)
                stalled <= 1;

            tcycle_counter <= tcycle_counter + 1;

            if (tcycle_counter == 3) begin
                if (rst_mcycle)
                    mcycle_counter <= 0;
                else if (!halt_hold)
                    mcycle_counter <= mcycle_counter + 1;
            end
        end
    end
endmodule
