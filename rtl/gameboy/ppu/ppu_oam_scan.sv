import ppu_types::*;

module ppu_oam_scan(
    input logic clk,
    input logic rst,
    input logic scan_en,
    input logic [8:0] dot,
    input logic [7:0] LY,
    input lcdc_t LCDC,
    oam_ppu_bus.parent_port oam_bus,
    output logic [3:0] sprite_count,
    output oam_entry_t sprites [SPRITES_PER_LINE]
);

    logic [3:0] count;
    oam_entry_t buffer [SPRITES_PER_LINE];
    oam_entry_t entry;
    oam_entry_t next;

    logic [5:0] obj_index;
    logic fetch_attrs;
    logic [7:0] sprite_height;
    logic [8:0] ly_plus_16;
    logic on_line;
    logic scanning;

    assign obj_index = dot[8:1];
    assign fetch_attrs = dot[0];
    assign sprite_height = LCDC.OBJ_SIZE ? 8'd16 : 8'd8;
    assign ly_plus_16 = {1'b0, LY} + 9'd16;
    assign sprite_count = count;
    assign sprites = buffer;
    assign scanning = scan_en && (dot < OAM_SCAN_END);

    always_comb begin
        oam_bus.cs = scanning;
        oam_bus.rd = scanning;
        oam_bus.addr = {obj_index, 2'b00} + (fetch_attrs ? 8'd2 : 8'd0);
    end

    always_comb begin
        next = entry;
        if (scanning) begin
            if (!fetch_attrs)
                next = '{
                    y: oam_bus.data_rd[7:0],
                    x: oam_bus.data_rd[15:8],
                    tile: entry.tile,
                    flags: entry.flags
                };
            else
                next = '{
                    y: entry.y,
                    x: entry.x,
                    tile: oam_bus.data_rd[7:0],
                    flags: oam_bus.data_rd[15:8]
                };
        end
    end

    always_comb begin
        on_line = (ly_plus_16 >= {1'b0, next.y})
            && (ly_plus_16 < {1'b0, next.y} + {1'b0, sprite_height});
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 4'd0;
            entry <= '0;
            for (int i = 0; i < SPRITES_PER_LINE; i++)
                buffer[i] <= '0;
        end else if (scan_en) begin
            if (dot == 9'd0) begin
                count <= 4'd0;
                for (int i = 0; i < SPRITES_PER_LINE; i++)
                    buffer[i] <= '0;
            end

            if (scanning) begin
                entry <= next;
                if (fetch_attrs && count < 4'(SPRITES_PER_LINE) && on_line) begin
                    buffer[count] <= next;
                    count <= count + 4'd1;
                end
            end
        end
    end
endmodule
