import ppu_types::*;

module ppu_obj_fetcher(
    input logic clk,
    input logic rst,
    input logic en,
    input logic cgb_mode,
    input logic line_start,
    input logic [7:0] LY,
    input logic [7:0] LX,
    input lcdc_t LCDC,
    input logic [3:0] sprite_count,
    input oam_entry_t sprites [SPRITES_PER_LINE],
    output logic [12:0] vram_addr,
    output logic vram_bank,
    input logic [7:0] vram_data,
    output logic obj_fetch_active,
    output logic obj_fetch_stall,
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
    logic [3:0] active_index;
    logic fetched [SPRITES_PER_LINE];
    oam_entry_t active;
    logic [7:0] tile_data_low;
    logic [7:0] tile_data_high;
    logic [2:0] skip_pixels;

    pixel_fifo_t fifo;
    assign fifo_head_pixel = fifo_head(fifo);
    assign fifo_count = fifo.count;

    logic trigger;
    logic [3:0] trigger_index;
    logic [7:0] row_in_sprite;
    logic [2:0] pixel_y;
    logic [7:0] tile_index;
    logic [12:0] tile_data_base;
    logic [2:0] sprite_palette;

    always_comb begin
        trigger = 1'b0;
        trigger_index = 4'd0;
        if (en && LCDC.OBJ_EN && !obj_fetch_active) begin
            for (int i = 0; i < SPRITES_PER_LINE; i++) begin
                if (!trigger && i < int'(sprite_count) && !fetched[i]
                        && sprites[i].x > 8'd0
                        && ({1'b0, sprites[i].x} <= {1'b0, LX} + 9'd8)) begin
                    trigger = 1'b1;
                    trigger_index = 4'(i);
                end
            end
        end
    end

    assign obj_fetch_stall = obj_fetch_active || trigger;

    always_comb begin
        row_in_sprite = LY + 8'd16 - active.y;
        if (active.flags.y_flip)
            row_in_sprite = (LCDC.OBJ_SIZE ? 8'd15 : 8'd7) - row_in_sprite;

        if (LCDC.OBJ_SIZE) begin
            tile_index = {active.tile[7:1], row_in_sprite[3]};
            pixel_y = row_in_sprite[2:0];
        end else begin
            tile_index = active.tile;
            pixel_y = row_in_sprite[2:0];
        end

        tile_data_base = {tile_index, 4'b0};
        sprite_palette = cgb_mode ? active.flags.cgb_palette : {2'b00, active.flags.dmg_palette};
    end

    always_comb begin
        vram_bank = cgb_mode ? active.flags.vram_bank : 1'b0;
        unique case (state)
            FETCH_DATA_LOW: vram_addr = tile_data_base + {pixel_y, 1'b0};
            FETCH_DATA_HIGH: vram_addr = tile_data_base + {pixel_y, 1'b1};
            default: vram_addr = tile_data_base + {pixel_y, 1'b0};
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst || !en || line_start) begin
            state <= FETCH_TILE;
            active_index <= 4'd0;
            active <= '0;
            tile_data_low <= 8'd0;
            tile_data_high <= 8'd0;
            skip_pixels <= 3'd0;
            obj_fetch_active <= 1'b0;
            fifo_reset(fifo);
            for (int i = 0; i < SPRITES_PER_LINE; i++)
                fetched[i] <= 1'b0;
        end else begin
            if (fifo_pop_en)
                fifo_pop(fifo);

            if (obj_fetch_active) begin
                unique case (state)
                    FETCH_TILE: begin
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
                        fifo_overlay_sprite(
                            fifo,
                            tile_data_low,
                            tile_data_high,
                            active.flags.x_flip,
                            sprite_palette,
                            active.flags.bg_priority,
                            skip_pixels
                        );
                        fetched[active_index] <= 1'b1;
                        obj_fetch_active <= 1'b0;
                        state <= FETCH_TILE;
                    end
                endcase
            end else if (trigger) begin
                active_index <= trigger_index;
                active <= sprites[trigger_index];
                skip_pixels <= (sprites[trigger_index].x < 8'd8)
                    ? 3'(8'd8 - sprites[trigger_index].x)
                    : 3'd0;
                obj_fetch_active <= 1'b1;
                state <= FETCH_TILE;
            end
        end
    end

endmodule
