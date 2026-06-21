import ppu_types::*;

module ppu_shifter(
    input logic clk,
    input logic rst,
    input logic en,
    input logic line_start,
    input logic [7:0] SCX,
    input logic [7:0] WX,
    input logic [7:0] BGP,
    input lcdc_t LCDC,
    input logic win_y_condition,
    input fifo_pixel_t fifo_head_pixel,
    input logic [3:0] fifo_count,
    output logic fifo_pop_en,
    output logic [7:0] LX,
    output logic win_enter,
    output logic win_line_tick,
    output logic px_valid,
    output logic [1:0] px_color
);

    logic [2:0] scx_discard_count;
    logic in_window;
    logic signed [9:0] wx_target;
    assign wx_target = {2'b0, WX} - 'sd7;

    always_comb begin
        fifo_pop_en = 0;
        px_valid = 0;
        px_color = 0;
        win_enter = 0;
        win_line_tick = 0;

        if (en && !in_window && LCDC.WIN_EN && win_y_condition
                && WX <= 'd166
                && $signed({2'b0, LX}) >= wx_target) begin
            win_enter = 1;
            win_line_tick = 1;
        end

        if (en && fifo_count > 0 && LX < 160 && !win_enter) begin
            if (scx_discard_count > 0) begin
                fifo_pop_en = 1;
            end else begin
                fifo_pop_en = 1;
                px_valid = 1;
                px_color = LCDC.BG_EN
                    ? (BGP >> (fifo_head_pixel.color * 2)) & 'b11
                    : 'b00;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst || !en || line_start) begin
            LX <= 0;
            scx_discard_count <= SCX[2:0];
            in_window <= 0;
        end else begin
            if (win_enter) begin
                in_window <= 1;
            end else if (fifo_pop_en) begin
                if (scx_discard_count > 0)
                    scx_discard_count <= scx_discard_count - 1;
                else
                    LX <= LX + 1;
            end
        end
    end

endmodule