import apu_types::*;

module apu_sweep(
    input logic clk,
    input logic rst,
    input logic clear,
    input logic sweep_tick,
    input logic trigger,
    input nr10_t nr10,
    input logic [10:0] trigger_period,
    output logic overflow,
    output logic period_update,
    output logic [10:0] period,
    output logic negate_used
);
    logic [10:0] shadow;
    logic [3:0] timer;
    logic enabled;

    logic [11:0] next_period;
    logic [11:0] overflow_check_period;

    function automatic logic [11:0] calculate(
        input logic [10:0] value,
        input logic [2:0] shift,
        input logic negate
    );
        logic [11:0] offset;
        offset = {1'b0, value} >> shift;
        return negate ? {1'b0, value} - offset : {1'b0, value} + offset;
    endfunction

    assign next_period = calculate(shadow, nr10.shift, nr10.negate);
    assign overflow_check_period = calculate(next_period[10:0], nr10.shift, nr10.negate);

    always_ff @(posedge clk) begin
        overflow <= 0;
        period_update <= 0;
        period <= shadow;

        if (rst || clear) begin
            shadow <= '0;
            timer <= '0;
            enabled <= 0;
            negate_used <= 0;
        end else begin
            if (sweep_tick && enabled) begin
                if (timer > 'd1) begin
                    timer <= timer - 'd1;
                end else begin
                    timer <= nr10.pace == 0 ? 4'd8 : {1'b0, nr10.pace};
                    if (nr10.pace != 0) begin
                        if (next_period > 'd2047) begin
                            overflow <= 1;
                        end else if (nr10.shift != 0) begin
                            shadow <= next_period[10:0];
                            period <= next_period[10:0];
                            period_update <= 1;
                            if (overflow_check_period > 'd2047)
                                overflow <= 1;
                            if (nr10.negate)
                                negate_used <= 1;
                        end
                    end
                end
            end

            if (trigger) begin
                shadow <= trigger_period;
                period <= trigger_period;
                timer <= nr10.pace == 0 ? 4'd8 : {1'b0, nr10.pace};
                enabled <= nr10.pace != 0 || nr10.shift != 0;
                negate_used <= 0;
                if (nr10.shift != 0 && calculate(trigger_period, nr10.shift, nr10.negate) > 'd2047)
                    overflow <= 1;
            end
        end
    end

endmodule
