import ppu_types::*;

module ppu(
    input logic clk,
    input logic rst,
    bus.child_port bus,
    bus.parent_port vram_bus,
    output logic vblank_interrupt,
    output logic stat_interrupt
);

    logic [1:0] framebuffer [144][160] /* verilator public */;

    lcdc_t LCDC /* verilator public */;
    stat_int_t STAT_INT;
    logic [7:0] SCY /* verilator public */;
    logic [7:0] SCX /* verilator public */;
    logic [7:0] LY /* verilator public */;
    logic [7:0] LYC;
    logic [7:0] BGP /* verilator public */;
    logic [7:0] OBP0;
    logic [7:0] OBP1;
    logic [7:0] WY;
    logic [7:0] WX;

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd)
            case (bus.addr)
                REG_LCDC: bus.data_rd = LCDC;
                REG_STAT: bus.data_rd = {1'b0, STAT_INT, lyc_match, mode};
                REG_SCY: bus.data_rd = SCY;
                REG_SCX: bus.data_rd = SCX;
                REG_LY: bus.data_rd = LY;
                REG_LYC: bus.data_rd = LYC;
                REG_BGP: bus.data_rd = BGP;
                REG_OBP0: bus.data_rd = OBP0;
                REG_OBP1: bus.data_rd = OBP1;
                REG_WY: bus.data_rd = WY;
                REG_WX: bus.data_rd = WX;
            endcase
    end

    always @(posedge clk) begin
        if (bus.cs && bus.wr)
            case (bus.addr)
                REG_LCDC: LCDC <= bus.data_wr;
                REG_STAT: STAT_INT <= bus.data_wr[6:3];
                REG_SCY: SCY <= bus.data_wr;
                REG_SCX: SCX <= bus.data_wr;
                REG_LYC: LYC <= bus.data_wr;
                REG_BGP: BGP <= bus.data_wr;
                REG_OBP0: OBP0 <= bus.data_wr;
                REG_OBP1: OBP1 <= bus.data_wr;
                REG_WY: WY <= bus.data_wr;
                REG_WX: WX <= bus.data_wr;
            endcase
    end

    logic [8:0] dot;
    ppu_mode_t mode;
    logic lyc_match;
    logic draw_done;
    logic [7:0] WLY;
    logic win_y_condition;
    logic win_line_tick;

    logic line_start;
    assign line_start = (mode == PPU_MODE_OAM) && (dot == OAM_END - 1);

    ppu_state ppu_state(
        .clk(clk),
        .rst(rst),
        .en(LCDC.EN),
        .LYC(LYC),
        .WY(WY),
        .draw_done(draw_done),
        .win_line_tick(win_line_tick),
        .dot(dot),
        .LY(LY),
        .WLY(WLY),
        .mode(mode),
        .lyc_match(lyc_match),
        .win_y_condition(win_y_condition)
    );

    logic fetcher_tick;
    assign fetcher_tick = mode == PPU_MODE_DRAW;

    fifo_pixel_t fifo_head_pixel;
    logic [3:0] fifo_count;
    logic fifo_pop_en;
    logic win_enter;

    assign vram_bus.wr = 1'b0;
    assign vram_bus.data_wr = 8'd0;
    assign vram_bus.rd = fetcher_tick;
    assign vram_bus.cs = 1'b1;

    ppu_bg_win_fetcher bg_win_fetcher(
        .clk(clk),
        .rst(rst),
        .en(fetcher_tick),
        .fetcher_tick(fetcher_tick),
        .line_start(line_start),
        .win_enter(win_enter),
        .LY(LY),
        .WLY(WLY),
        .SCX(SCX),
        .SCY(SCY),
        .LCDC(LCDC),
        .vram_addr(vram_bus.addr),
        .vram_data(vram_bus.data_rd),
        .fifo_head_pixel(fifo_head_pixel),
        .fifo_count(fifo_count),
        .fifo_pop_en(fifo_pop_en)
    );

    logic [7:0] LX;
    logic px_valid;
    logic [1:0] px_color;

    ppu_shifter shifter(
        .clk(clk),
        .rst(rst),
        .en(fetcher_tick),
        .line_start(line_start),
        .SCX(SCX),
        .WX(WX),
        .BGP(BGP),
        .LCDC(LCDC),
        .win_y_condition(win_y_condition),
        .fifo_head_pixel(fifo_head_pixel),
        .fifo_count(fifo_count),
        .fifo_pop_en(fifo_pop_en),
        .LX(LX),
        .win_enter(win_enter),
        .win_line_tick(win_line_tick),
        .px_valid(px_valid),
        .px_color(px_color)
    );

    assign draw_done = LX == 'd160;

    always_ff @(posedge clk) begin
        if (px_valid)
            framebuffer[LY][LX] <= px_color;
    end

    logic is_hblank, is_vblank, is_oam;
    assign is_hblank = (mode == PPU_MODE_HBLANK);
    assign is_vblank = (mode == PPU_MODE_VBLANK);
    assign is_oam = (mode == PPU_MODE_OAM);

    logic vblank_rising;
    edge_detect vblank_edge(
        .clk(clk),
        .rst(rst),
        .signal(is_vblank),
        .rising(vblank_rising)
    );

    logic stat_condition;
    assign stat_condition = (is_hblank && STAT_INT.HBLANK_INT)
                || (is_oam && STAT_INT.OAM_INT)
                || (is_vblank && STAT_INT.VBLANK_INT)
                || (lyc_match && STAT_INT.LYC_INT);

    logic stat_condition_rising;

    edge_detect stat_edge(
        .clk(clk),
        .rst(rst),
        .signal(stat_condition),
        .rising(stat_condition_rising)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            vblank_interrupt <= 0;
            stat_interrupt <= 0;
        end else begin
            vblank_interrupt <= vblank_rising;
            stat_interrupt <= stat_condition_rising;
        end
    end

endmodule