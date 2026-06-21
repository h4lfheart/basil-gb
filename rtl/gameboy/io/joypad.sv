typedef struct packed {
    logic up;
    logic down;
    logic left;
    logic right;
    logic a;
    logic b;
    logic start;
    logic select;
} joypad_buttons_t;

module joypad(
    input logic clk,
    input logic rst,
    input joypad_buttons_t buttons,
    bus.child_port bus
);
    logic select_buttons = 1;
    logic select_dpad = 1;

    always_comb begin
        bus.data_rd = 8'hFF;

        if (bus.cs && bus.rd) begin
            logic [3:0] bits = 4'b1111;

            if (select_buttons == 0) begin
                bits[3] = buttons.start;
                bits[2] = buttons.select;
                bits[1] = buttons.b;
                bits[0] = buttons.a;
            end

            if (select_dpad == 0) begin
                bits[3] = buttons.down;
                bits[2] = buttons.up;
                bits[1] = buttons.left;
                bits[0] = buttons.right;
            end

            bus.data_rd = {2'b00, select_buttons, select_dpad, bits};
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            select_buttons <= 1;
            select_dpad <= 1;
        end else if (bus.cs && bus.wr) begin
            select_buttons <= bus.data_wr[5];
            select_dpad <= bus.data_wr[4];
        end
    end

endmodule