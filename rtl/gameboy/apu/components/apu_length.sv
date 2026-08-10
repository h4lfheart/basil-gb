module apu_length #(
    parameter int WIDTH = 6
)(
    input logic clk,
    input logic rst,
    input logic clear,
    input logic length_tick,
    input logic length_enable,
    input logic load,
    input logic [WIDTH:0] load_value,
    input logic trigger,
    input logic extra_window,
    input logic enable_rising,
    input logic trigger_length_enable,
    output logic expire
);
    localparam logic [WIDTH:0] MAX_LENGTH = {1'b1, {WIDTH{1'b0}}};

    logic [WIDTH:0] counter;
    logic extra_on_enable;
    logic extra_on_trigger;

    assign extra_on_enable = extra_window && enable_rising && counter != 0;
    assign extra_on_trigger = extra_window && trigger_length_enable && counter == 0;

    always_ff @(posedge clk) begin
        expire <= 0;

        if (rst || clear) begin
            counter <= '0;
        end else begin
            if (load)
                counter <= load_value;

            if (length_tick && length_enable && counter != 0) begin
                counter <= counter - 'd1;
                if (counter == 1)
                    expire <= 1;
            end

            if (trigger && counter == 0) begin
                counter <= extra_on_trigger ? MAX_LENGTH - 'd1 : MAX_LENGTH;
            end else if (extra_on_enable) begin
                counter <= counter - 'd1;
                if (counter == 1)
                    expire <= 1;
            end
        end
    end

endmodule
