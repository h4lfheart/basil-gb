module gb_scaler #(
    parameter int X_ORIGIN = 80,
    parameter int Y_ORIGIN = 24,
    parameter int SCALE = 3
) (
    input logic clk,
    input logic rst,
    input logic [9:0] cx,
    input logic [9:0] cy,
    fb_rd_bus.scanout fb_rd,
    output logic [23:0] rgb
);
    localparam int X_END = X_ORIGIN + 160 * SCALE;
    localparam int Y_END = Y_ORIGIN + 144 * SCALE;

    logic visible;
    logic visible_q;
    logic [7:0] gb_x;
    logic [7:0] gb_y;
    logic [4:0] red;
    logic [4:0] green;
    logic [4:0] blue;

    always_comb begin
        visible = (cx >= X_ORIGIN) && (cx < X_END)
            && (cy >= Y_ORIGIN) && (cy < Y_END);
        gb_x = visible ? 8'((cx - X_ORIGIN) / SCALE) : '0;
        gb_y = visible ? 8'((cy - Y_ORIGIN) / SCALE) : '0;
        fb_rd.addr = (15'(gb_y) << 7) + (15'(gb_y) << 5) + 15'(gb_x);
    end

    always_ff @(posedge clk) begin
        if (rst)
            visible_q <= 0;
        else
            visible_q <= visible;
    end

    assign red = fb_rd.data[4:0];
    assign green = fb_rd.data[9:5];
    assign blue = fb_rd.data[14:10];
    assign rgb = visible_q
        ? {{red, red[4:2]}, {green, green[4:2]}, {blue, blue[4:2]}}
        : '0;
endmodule
