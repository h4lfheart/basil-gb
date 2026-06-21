import ppu_types::*;

module ppu_state(
    input logic clk,
    input logic rst,
    input logic en,
    input logic [7:0] LYC,
    input logic [7:0] WY,
    input logic draw_done,
    input logic win_line_tick,
    output logic [8:0] dot,
    output logic [7:0] LY,
    output logic [7:0] WLY,
    output ppu_mode_t mode,
    output logic lyc_match,
    output logic win_y_condition
);

    logic win_shown_this_line;

    logic line_end;
    assign line_end = (dot == DOTS_PER_LINE - 1);

    logic line_start;
    assign line_start = (mode == PPU_MODE_OAM) && (dot == OAM_END - 1);

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

    always_ff @(posedge clk) begin
        if (rst) begin
            win_y_condition <= 1'b0;
        end else if (en) begin
            if (mode == PPU_MODE_VBLANK && line_end && LY == LY_MAX)
                win_y_condition <= 1'b0;
            else if (line_start && WY == LY)
                win_y_condition <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            WLY <= 8'd0;
            win_shown_this_line <= 1'b0;
        end else if (en) begin
            if (mode == PPU_MODE_VBLANK && line_end && LY == LY_MAX) begin
                WLY <= 8'd0;
                win_shown_this_line <= 1'b0;
            end else if (line_start) begin
                if (win_shown_this_line)
                    WLY <= WLY + 8'd1;
                win_shown_this_line <= 1'b0;
            end else if (win_line_tick) begin
                win_shown_this_line <= 1'b1;
            end
        end
    end

    always_comb begin
        lyc_match = (LY == LYC);
    end

endmodule