module apu_freq_timer #(
    parameter int WIDTH = 14
)(
    input logic clk,
    input logic rst,
    input logic clear,
    input logic enable,
    input logic trigger,
    input logic [WIDTH-1:0] reload,
    output logic tick
);
    logic [WIDTH-1:0] counter;

    always_ff @(posedge clk) begin
        tick <= 0;

        if (rst || clear) begin
            counter <= '0;
        end else begin
            if (enable) begin
                if (counter <= 1) begin
                    counter <= reload;
                    tick <= 1;
                end else begin
                    counter <= counter - 'd1;
                end
            end

            if (trigger)
                counter <= reload;
        end
    end

endmodule
