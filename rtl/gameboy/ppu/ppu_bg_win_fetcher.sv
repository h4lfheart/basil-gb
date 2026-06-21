import ppu_types::*;

module ppu_bg_win_fetcher(
    input logic clk,
    input logic rst,
    input logic en,
    input logic fetcher_tick,
    input logic line_start,
    input logic win_enter,
    input logic [7:0] LY,
    input logic [7:0] WLY,
    input logic [7:0] SCX,
    input logic [7:0] SCY,
    input lcdc_t LCDC,
    output logic [12:0] vram_addr,
    input logic [7:0] vram_data,
    output fifo_pixel_t fifo_head_pixel,
    output logic [3:0] fifo_count,
    input logic fifo_pop_en
);

    typedef enum logic [1:0] {
        FETCH_TILE,
        FETCH_DATA_LOW,
        FETCH_DATA_HIGH,
        FETCH_PUSH
    } fetch_state_t;

    fetch_state_t state;
    logic [7:0] tile_id;
    logic [7:0] tile_data_low;
    logic [7:0] tile_data_high;
    logic [7:0] fetcher_x;
    logic in_window;

    pixel_fifo_t fifo;
    assign fifo_head_pixel = fifo_head(fifo);
    assign fifo_count = fifo.count;

    logic [7:0] offset_x, offset_y;
    logic [4:0] tx, ty;
    logic [2:0] pixel_y;
    logic [15:0] tile_map_base;
    logic [12:0] tile_map_offset;

    always_comb begin
        offset_x = fetcher_x + SCX;
        offset_y = LY + SCY;
        if (in_window) begin
            tx = fetcher_x[7:3];
            ty = WLY[7:3];
            pixel_y = WLY[2:0];
            tile_map_base = LCDC.WIN_TILE_MAP ? 13'h1C00 : 13'h1800;
        end else begin
            tx = offset_x[7:3];
            ty = offset_y[7:3];
            pixel_y = offset_y[2:0];
            tile_map_base = LCDC.BG_TILE_MAP ? 13'h1C00 : 13'h1800;
        end
        tile_map_offset = {ty, tx};
    end

    logic [12:0] tile_data_base;
    assign tile_data_base = LCDC.TILE_DATA_MAP
        ? {tile_id, 4'b0}
        : 13'h1000 + 13'($signed(tile_id) <<< 4);

    always_comb begin
        unique case (state)
            FETCH_TILE: vram_addr = tile_map_base + tile_map_offset;
            FETCH_DATA_LOW: vram_addr = tile_data_base + {pixel_y, 1'b0};
            FETCH_DATA_HIGH: vram_addr = tile_data_base + {pixel_y, 1'b1};
            default: vram_addr = tile_data_base + {pixel_y, 1'b0};
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst || !en) begin
            state <= FETCH_TILE;
            tile_id <= 'd0;
            tile_data_low <= 'd0;
            tile_data_high <= 'd0;
            fetcher_x <= 'd0;
            in_window <= 1'b0;
            fifo_reset(fifo);
        end else begin
            if (line_start) begin
                fetcher_x <= 'd0;
                in_window <= 1'b0;
                state <= FETCH_TILE;
                fifo_reset(fifo);
            end else if (win_enter) begin
                fetcher_x <= 'd0;
                in_window <= 1'b1;
                state <= FETCH_TILE;
                fifo_reset(fifo);
            end else begin
                if (fifo_pop_en)
                    fifo_pop(fifo);

                if (fetcher_tick) begin
                    unique case (state)
                        FETCH_TILE: begin
                            tile_id <= vram_data;
                            state <= FETCH_DATA_LOW;
                        end
                        FETCH_DATA_LOW: begin
                            tile_data_low <= vram_data;
                            state <= FETCH_DATA_HIGH;
                        end
                        FETCH_DATA_HIGH: begin
                            tile_data_high <= vram_data;
                            state <= FETCH_PUSH;
                        end
                        FETCH_PUSH: begin
                            if (fifo.count == 0) begin
                                for (int i = 0; i < 8; i++) begin
                                    fifo_push(fifo, fifo_pixel_t'{
                                        color: {tile_data_high[7-i], tile_data_low[7-i]},
                                        palette: 'b00,
                                        bg_priority: 0
                                    });
                                end

                                fetcher_x <= fetcher_x + 'd8;
                                state <= FETCH_TILE;
                            end
                        end
                    endcase
                end
            end
        end
    end

endmodule