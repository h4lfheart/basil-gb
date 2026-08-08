import ppu_types::*;

module ppu(
    input logic clk,
    input logic rst,
    input logic cgb_mode /* verilator public */,
    bus.child_port bus,
    vram_ppu_bus.parent_port vram_bus,
    oam_ppu_bus.parent_port oam_bus,
    output logic cpu_vram_bank,
    output logic cpu_oam_blocked,
    output logic vblank_interrupt,
    output logic stat_interrupt
);

    logic [14:0] framebuffer [144][160] /* verilator public */;

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
    logic VBK;
    palette_index_t BCPS;
    palette_index_t OCPS;
    logic [14:0] bg_palette [8][4] /* verilator public */;
    logic [14:0] obj_palette [8][4] /* verilator public */;

    assign cpu_vram_bank = VBK;

    logic [2:0] bcps_pal;
    logic [1:0] bcps_color;
    logic bcps_high;
    logic [2:0] ocps_pal;
    logic [1:0] ocps_color;
    logic ocps_high;

    assign bcps_pal = BCPS.address[5:3];
    assign bcps_color = BCPS.address[2:1];
    assign bcps_high = BCPS.address[0];
    assign ocps_pal = OCPS.address[5:3];
    assign ocps_color = OCPS.address[2:1];
    assign ocps_high = OCPS.address[0];

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd)
            case (bus.addr)
                REG_LCDC: bus.data_rd = LCDC;
                REG_STAT: bus.data_rd = {1'b1, STAT_INT, lyc_match, mode};
                REG_SCY: bus.data_rd = SCY;
                REG_SCX: bus.data_rd = SCX;
                REG_LY: bus.data_rd = LY;
                REG_LYC: bus.data_rd = LYC;
                REG_BGP: bus.data_rd = BGP;
                REG_OBP0: bus.data_rd = OBP0;
                REG_OBP1: bus.data_rd = OBP1;
                REG_WY: bus.data_rd = WY;
                REG_WX: bus.data_rd = WX;
                REG_VBK: bus.data_rd = {7'h7F, VBK};
                REG_BCPS: bus.data_rd = BCPS;
                REG_BCPD: begin
                    if (bcps_high)
                        bus.data_rd = {1'b0, bg_palette[bcps_pal][bcps_color][14:8]};
                    else
                        bus.data_rd = bg_palette[bcps_pal][bcps_color][7:0];
                end
                REG_OCPS: bus.data_rd = OCPS;
                REG_OCPD: begin
                    if (ocps_high)
                        bus.data_rd = {1'b0, obj_palette[ocps_pal][ocps_color][14:8]};
                    else
                        bus.data_rd = obj_palette[ocps_pal][ocps_color][7:0];
                end
            endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            VBK <= 'b0;
            BCPS <= 'h00;
            OCPS <= 'h00;
        end else if (bus.cs && bus.wr) begin
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
                REG_VBK: VBK <= bus.data_wr[0];
                REG_BCPS: BCPS <= bus.data_wr;
                REG_BCPD: begin
                    if (bcps_high)
                        bg_palette[bcps_pal][bcps_color][14:8] <= bus.data_wr[6:0];
                    else
                        bg_palette[bcps_pal][bcps_color][7:0] <= bus.data_wr;
                    if (BCPS.auto_increment)
                        BCPS.address <= BCPS.address + 'd1;
                end
                REG_OCPS: OCPS <= bus.data_wr;
                REG_OCPD: begin
                    if (ocps_high)
                        obj_palette[ocps_pal][ocps_color][14:8] <= bus.data_wr[6:0];
                    else
                        obj_palette[ocps_pal][ocps_color][7:0] <= bus.data_wr;
                    if (OCPS.auto_increment)
                        OCPS.address <= OCPS.address + 'd1;
                end
            endcase
        end
    end

    logic [8:0] dot;
    ppu_mode_t mode;
    logic lyc_match;
    logic draw_done;
    logic [7:0] WLY;
    logic win_y_condition;
    logic win_line_tick;

    logic line_start;
    assign line_start = (mode == PPU_MODE_OAM) && (dot == OAM_SCAN_END - 1);

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

    logic [3:0] sprite_count;
    oam_entry_t sprites [SPRITES_PER_LINE];

    ppu_oam_scan oam_scan(
        .clk(clk),
        .rst(rst),
        .scan_en(LCDC.EN && mode == PPU_MODE_OAM),
        .dot(dot),
        .LY(LY),
        .LCDC(LCDC),
        .oam_bus(oam_bus),
        .sprite_count(sprite_count),
        .sprites(sprites)
    );

    logic fetcher_tick;
    logic obj_fetch_active;
    logic obj_fetch_stall;
    logic obj_fetch_active_d;
    logic bg_restart;

    assign fetcher_tick = (mode == PPU_MODE_DRAW) && !obj_fetch_stall;
    assign bg_restart = obj_fetch_active && !obj_fetch_active_d;

    always_ff @(posedge clk) begin
        if (rst)
            obj_fetch_active_d <= 1'b0;
        else
            obj_fetch_active_d <= obj_fetch_active;
    end

    fifo_pixel_t bg_fifo_head;
    logic [3:0] bg_fifo_count;
    logic bg_fifo_pop_en;
    fifo_pixel_t obj_fifo_head;
    logic [3:0] obj_fifo_count;
    logic obj_fifo_pop_en;
    logic win_enter;

    logic [12:0] bg_vram_addr;
    logic [12:0] obj_vram_addr;
    logic obj_vram_bank;

    assign vram_bus.rd = (mode == PPU_MODE_DRAW);
    assign vram_bus.cs = 1'b1;
    assign vram_bus.addr = obj_fetch_active ? obj_vram_addr : bg_vram_addr;

    logic [7:0] obj_vram_data;
    assign obj_vram_data = obj_vram_bank ? vram_bus.bank1_data : vram_bus.bank0_data;

    ppu_bg_win_fetcher bg_win_fetcher(
        .clk(clk),
        .rst(rst),
        .en(mode == PPU_MODE_DRAW),
        .cgb_mode(cgb_mode),
        .fetcher_tick(fetcher_tick),
        .line_start(line_start),
        .restart(bg_restart),
        .win_enter(win_enter),
        .LY(LY),
        .WLY(WLY),
        .SCX(SCX),
        .SCY(SCY),
        .LCDC(LCDC),
        .vram_addr(bg_vram_addr),
        .vram_bank0_data(vram_bus.bank0_data),
        .vram_bank1_data(vram_bus.bank1_data),
        .fifo_head_pixel(bg_fifo_head),
        .fifo_count(bg_fifo_count),
        .fifo_pop_en(bg_fifo_pop_en)
    );

    ppu_obj_fetcher obj_fetcher(
        .clk(clk),
        .rst(rst),
        .en(mode == PPU_MODE_DRAW),
        .cgb_mode(cgb_mode),
        .line_start(line_start),
        .LY(LY),
        .LX(LX),
        .LCDC(LCDC),
        .sprite_count(sprite_count),
        .sprites(sprites),
        .vram_addr(obj_vram_addr),
        .vram_bank(obj_vram_bank),
        .vram_data(obj_vram_data),
        .obj_fetch_active(obj_fetch_active),
        .obj_fetch_stall(obj_fetch_stall),
        .fifo_head_pixel(obj_fifo_head),
        .fifo_count(obj_fifo_count),
        .fifo_pop_en(obj_fifo_pop_en)
    );

    logic [7:0] LX;
    logic px_valid;
    logic [14:0] px_color;

    ppu_shifter shifter(
        .clk(clk),
        .rst(rst),
        .en(mode == PPU_MODE_DRAW),
        .cgb_mode(cgb_mode),
        .line_start(line_start),
        .obj_fetch_active(obj_fetch_stall),
        .SCX(SCX),
        .WX(WX),
        .BGP(BGP),
        .OBP0(OBP0),
        .OBP1(OBP1),
        .bg_palette(bg_palette),
        .obj_palette(obj_palette),
        .LCDC(LCDC),
        .win_y_condition(win_y_condition),
        .bg_fifo_head(bg_fifo_head),
        .bg_fifo_count(bg_fifo_count),
        .bg_fifo_pop_en(bg_fifo_pop_en),
        .obj_fifo_head(obj_fifo_head),
        .obj_fifo_count(obj_fifo_count),
        .obj_fifo_pop_en(obj_fifo_pop_en),
        .LX(LX),
        .win_enter(win_enter),
        .win_line_tick(win_line_tick),
        .px_valid(px_valid),
        .px_color(px_color)
    );

    assign draw_done = px_valid && (LX == 'd159);

    always_ff @(posedge clk) begin
        if (px_valid)
            framebuffer[LY][LX] <= px_color;
    end

    logic is_hblank, is_vblank, is_oam, is_draw;
    assign is_hblank = (mode == PPU_MODE_HBLANK);
    assign is_vblank = (mode == PPU_MODE_VBLANK);
    assign is_oam = (mode == PPU_MODE_OAM);
    assign is_draw = (mode == PPU_MODE_DRAW);

    assign cpu_oam_blocked = LCDC.EN && (is_oam || is_draw);

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
