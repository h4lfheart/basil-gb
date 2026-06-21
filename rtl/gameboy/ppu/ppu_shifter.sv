import ppu_types::*;

module ppu_shifter(
    input logic clk,
    input logic rst,
    input logic en,
    input logic [7:0] SCX,
    input logic [7:0] BGP,
    input logic LCDC_BG_EN,
    input fifo_pixel_t fifo_head_pixel,
    input logic [3:0] fifo_count,
    output logic fifo_pop_en,
    output logic [7:0] LX,
    output logic px_valid,
    output logic [1:0] px_color
);

    logic [2:0] scx_discard_count;

    always_comb begin
        fifo_pop_en = 0;
        px_valid = 0;
        px_color = 0;

        if (en && fifo_count > 0 && LX < 160) begin
            if (scx_discard_count > 0) begin
                fifo_pop_en = 1;
            end else begin
                fifo_pop_en = 1;
                px_valid = 1;
                px_color = LCDC_BG_EN
                    ? (BGP >> (fifo_head_pixel.color * 2)) & 'b11
                    : 'b00;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst || !en) begin
            LX <= 0;
            scx_discard_count <= SCX[2:0];
        end else if (fifo_pop_en) begin
            if (scx_discard_count > 0)
                scx_discard_count <= scx_discard_count - 1;
            else
                LX <= LX + 1;
        end
    end

endmodule