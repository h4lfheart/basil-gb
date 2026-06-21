import ppu_types::*;

module ppu_state(
    input logic clk,
    input logic rst,
    input logic en,
    input logic [7:0] LYC,
    input logic draw_done,
    output logic [8:0] dot,
    output logic [7:0] LY,
    output ppu_mode_t mode,
    output logic lyc_match
);

    logic line_end;
    assign line_end = (dot == DOTS_PER_LINE - 1);

    always_ff @(posedge clk) begin
        if (rst) begin
            dot <= 9'd0;
            LY <= 8'd0;
        end else if (en) begin
            if (line_end) begin
                dot <= 9'd0;
                LY <= (LY == LY_MAX) ? 8'd0 : LY + 8'd1;
            end else begin
                dot <= dot + 9'd1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mode <= PPU_MODE_OAM;
        end else if (en) begin
            unique case (mode)
                PPU_MODE_OAM: begin
                    if (dot == OAM_END - 1)
                        mode <= PPU_MODE_DRAW;
                end
                PPU_MODE_DRAW: begin
                    if (draw_done)
                        mode <= PPU_MODE_HBLANK;
                end
                PPU_MODE_HBLANK: begin
                    if (line_end)
                        mode <= (LY == VBLANK_START - 1) ? PPU_MODE_VBLANK : PPU_MODE_OAM;
                end
                PPU_MODE_VBLANK: begin
                    if (line_end && LY == LY_MAX)
                        mode <= PPU_MODE_OAM;
                end
            endcase
        end
    end

    always_comb begin
        lyc_match = (LY == LYC);
    end

endmodule