import ppu_types::*;

module ppu_shifter(
    input logic clk,
    input logic rst,
    input logic en,
    input logic line_start,
    input logic obj_fetch_active,
    input logic [7:0] SCX,
    input logic [7:0] WX,
    input logic [7:0] BGP,
    input logic [7:0] OBP0,
    input logic [7:0] OBP1,
    input lcdc_t LCDC,
    input logic win_y_condition,
    input fifo_pixel_t bg_fifo_head,
    input logic [3:0] bg_fifo_count,
    output logic bg_fifo_pop_en,
    input fifo_pixel_t obj_fifo_head,
    input logic [3:0] obj_fifo_count,
    output logic obj_fifo_pop_en,
    output logic [7:0] LX,
    output logic win_enter,
    output logic win_line_tick,
    output logic px_valid,
    output logic [1:0] px_color
);

    logic [2:0] scx_discard_count;
    logic in_window;
    logic signed [9:0] wx_target;
    logic [1:0] bg_color;
    logic [1:0] obj_color;
    logic [7:0] obj_palette;
    logic use_obj;

    assign wx_target = {2'b0, WX} - 'sd7;

    always_comb begin
        bg_fifo_pop_en = 0;
        obj_fifo_pop_en = 0;
        px_valid = 0;
        px_color = 0;
        win_enter = 0;
        win_line_tick = 0;
        bg_color = 0;
        obj_color = 0;
        obj_palette = OBP0;
        use_obj = 0;

        if (en && !obj_fetch_active && !in_window && LCDC.WIN_EN && win_y_condition
                && WX <= 'd166
                && $signed({2'b0, LX}) >= wx_target) begin
            win_enter = 1;
            win_line_tick = 1;
        end

        if (en && !obj_fetch_active && bg_fifo_count > 0 && LX < 160 && !win_enter) begin
            if (scx_discard_count > 0) begin
                bg_fifo_pop_en = 1;
            end else begin
                bg_fifo_pop_en = 1;
                if (obj_fifo_count > 0)
                    obj_fifo_pop_en = 1;

                px_valid = 1;

                bg_color = LCDC.BG_EN ? bg_fifo_head.color : 2'b00;
                obj_color = (obj_fifo_count > 0) ? obj_fifo_head.color : 2'b00;
                obj_palette = obj_fifo_head.palette[0] ? OBP1 : OBP0;

                use_obj = (obj_color != 2'b00)
                    && !(obj_fifo_head.bg_priority && bg_color != 2'b00)
                    && LCDC.OBJ_EN;

                if (use_obj)
                    px_color = (obj_palette >> (obj_color * 2)) & 2'b11;
                else if (LCDC.BG_EN)
                    px_color = (BGP >> (bg_color * 2)) & 2'b11;
                else
                    px_color = 2'b00;
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
            end else if (bg_fifo_pop_en) begin
                if (scx_discard_count > 0)
                    scx_discard_count <= scx_discard_count - 1;
                else
                    LX <= LX + 1;
            end
        end
    end

endmodule
