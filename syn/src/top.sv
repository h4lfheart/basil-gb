module top (
    input I_clk,
    input I_rst,
    output running,
    output O_tmds_clk_p,
    output O_tmds_clk_n,
    output [2:0] O_tmds_data_p,
    output [2:0] O_tmds_data_n,
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,
    output O_sdram_cas_n,
    output O_sdram_ras_n,
    output O_sdram_wen_n,
    inout [31:0] IO_sdram_dq,
    output [10:0] O_sdram_addr,
    output [1:0] O_sdram_ba,
    output [3:0] O_sdram_dqm,
    output flash_cs_n,
    output flash_clk,
    output flash_mosi,
    input flash_miso
);
    wire board_rst_n = ~I_rst;

    wire serial_clk;
    wire pixel_clk;
    wire tmds_pll_lock;
    wire hdmi_reset = I_rst | ~tmds_pll_lock;

    TMDS_rPLL u_tmds_pll (
        .clkin(I_clk),
        .clkout(serial_clk),
        .lock(tmds_pll_lock)
    );

    CLKDIV u_pixel_div (
        .RESETN(board_rst_n & tmds_pll_lock),
        .HCLKIN(serial_clk),
        .CLKOUT(pixel_clk),
        .CALIB(1'b1)
    );
    defparam u_pixel_div.DIV_MODE = "5";
    defparam u_pixel_div.GSREN = "false";

    wire sdram_clk;
    wire sdram_clk_phase;
    wire sdram_pll_lock;
    wire sdram_rst_n = board_rst_n & sdram_pll_lock;

    SDRAM_rPLL u_sdram_pll (
        .clkin(I_clk),
        .clkout(sdram_clk),
        .clkoutp(sdram_clk_phase),
        .lock(sdram_pll_lock)
    );

    sdram_bus boot_sdram();
    sdram_bus run_sdram();
    spi_flash_bus flash();
    cart_ext_mem cart_mem();
    wram_ext_mem wram_mem();
    fb_rd_bus fb_rd();

    logic rom_ready;
    logic [7:0] header_cart_type;

    logic sdram_rd;
    logic sdram_wr;
    logic sdram_refresh;
    logic [22:0] sdram_addr;
    logic [7:0] sdram_din;
    logic [7:0] sdram_dout;
    logic sdram_data_ready;
    logic sdram_busy;

    assign sdram_rd = rom_ready ? run_sdram.rd : boot_sdram.rd;
    assign sdram_wr = rom_ready ? run_sdram.wr : boot_sdram.wr;
    assign sdram_refresh = rom_ready ? run_sdram.refresh : boot_sdram.refresh;
    assign sdram_addr = rom_ready ? run_sdram.addr : boot_sdram.addr;
    assign sdram_din = rom_ready ? run_sdram.din : boot_sdram.din;

    assign boot_sdram.dout = sdram_dout;
    assign run_sdram.dout = sdram_dout;
    assign boot_sdram.data_ready = sdram_data_ready;
    assign run_sdram.data_ready = sdram_data_ready;
    assign boot_sdram.busy = sdram_busy;
    assign run_sdram.busy = sdram_busy;

    assign flash_cs_n = flash.cs_n;
    assign flash_clk = flash.clk;
    assign flash_mosi = flash.mosi;
    assign flash.miso = flash_miso;

    sdram #(.FREQ(54_000_000)) u_sdram (
        .clk(sdram_clk),
        .clk_sdram(sdram_clk_phase),
        .resetn(sdram_rst_n),
        .rd(sdram_rd),
        .wr(sdram_wr),
        .refresh(sdram_refresh),
        .addr(sdram_addr),
        .din(sdram_din),
        .dout(sdram_dout),
        .dout32(),
        .data_ready(sdram_data_ready),
        .busy(sdram_busy),
        .SDRAM_DQ(IO_sdram_dq),
        .SDRAM_A(O_sdram_addr),
        .SDRAM_BA(O_sdram_ba),
        .SDRAM_nCS(O_sdram_cs_n),
        .SDRAM_nWE(O_sdram_wen_n),
        .SDRAM_nRAS(O_sdram_ras_n),
        .SDRAM_nCAS(O_sdram_cas_n),
        .SDRAM_CLK(O_sdram_clk),
        .SDRAM_CKE(O_sdram_cke),
        .SDRAM_DQM(O_sdram_dqm)
    );

    rom_loader u_loader (
        .clk(sdram_clk),
        .rst_n(sdram_rst_n),
        .sdram(boot_sdram),
        .flash(flash),
        .header_cart_type(header_cart_type),
        .ready(rom_ready)
    );

    localparam logic [25:0] GB_STEP = 'd8_388_608;
    localparam logic [25:0] GB_RATE = 'd27_000_000;
    logic [25:0] gb_accumulator;
    logic gb_clk_r /* synthesis syn_keep=1 */;
    wire [26:0] gb_sum = {1'b0, gb_accumulator} + GB_STEP;
    wire gb_clk = gb_clk_r;

    always_ff @(posedge I_clk or negedge board_rst_n) begin
        if (!board_rst_n) begin
            gb_accumulator <= '0;
            gb_clk_r <= 1'b0;
        end else if (gb_sum >= GB_RATE) begin
            gb_accumulator <= gb_sum - GB_RATE;
            gb_clk_r <= ~gb_clk_r;
        end else begin
            gb_accumulator <= gb_sum[25:0];
        end
    end

    logic [5:0] gb_reset_count;
    logic gb_reset;
    always_ff @(posedge gb_clk or negedge board_rst_n) begin
        if (!board_rst_n) begin
            gb_reset_count <= '0;
            gb_reset <= 1'b1;
        end else if (!rom_ready || !tmds_pll_lock || !sdram_pll_lock) begin
            gb_reset_count <= '0;
            gb_reset <= 1'b1;
        end else begin
            if (!gb_reset_count)
                gb_reset_count <= gb_reset_count + 1'b1;
            gb_reset <= !gb_reset_count;
        end
    end

    joypad_buttons_t buttons;
    assign buttons = '1;
    assign fb_rd.clk = pixel_clk;

    sdram_bridge u_sdram_bridge (
        .gb_clk(gb_clk),
        .enable(rom_ready),
        .cart_mem(cart_mem),
        .wram_mem(wram_mem),
        .sdram_clk(sdram_clk),
        .sdram_rst_n(sdram_rst_n),
        .sdram(run_sdram)
    );

    console u_console (
        .clk(gb_clk),
        .rst(gb_reset),
        .buttons(buttons),
        .audio_sample_left(),
        .audio_sample_right(),
        .fb_rd(fb_rd),
        .header_cart_type(header_cart_type),
        .cart_mem(cart_mem),
        .wram_mem(wram_mem)
    );

    logic [9:0] hdmi_cx;
    logic [9:0] hdmi_cy;
    logic [23:0] pixel_rgb;
    logic [2:0] tmds_serial;
    logic tmds_clock;

    gb_scaler u_scaler (
        .clk(pixel_clk),
        .rst(hdmi_reset),
        .cx(hdmi_cx),
        .cy(hdmi_cy),
        .fb_rd(fb_rd),
        .rgb(pixel_rgb)
    );

    hdmi #(
        .VIDEO_ID_CODE(1),
        .DVI_OUTPUT(1'b1),
        .VIDEO_REFRESH_RATE(60.0),
        .VENDOR_NAME({"basil-gb"}),
        .PRODUCT_DESCRIPTION({"Tang Nano 20K", 24'd0}),
        .SOURCE_DEVICE_INFORMATION(8'h08)
    ) u_hdmi (
        .clk_pixel_x5(serial_clk),
        .clk_pixel(pixel_clk),
        .clk_audio(1'b0),
        .reset(hdmi_reset),
        .rgb(pixel_rgb),
        .audio_sample_word('{16'sd0, 16'sd0}),
        .tmds(tmds_serial),
        .tmds_clock(tmds_clock),
        .cx(hdmi_cx),
        .cy(hdmi_cy),
        .frame_width(),
        .frame_height(),
        .screen_width(),
        .screen_height()
    );

    TLVDS_OBUF u_tmds_clk_buf (
        .I(tmds_clock),
        .O(O_tmds_clk_p),
        .OB(O_tmds_clk_n)
    );

    genvar lane;
    generate
        for (lane = 0; lane < 3; lane = lane + 1) begin : g_tmds_buf
            TLVDS_OBUF u_data_buf (
                .I(tmds_serial[lane]),
                .O(O_tmds_data_p[lane]),
                .OB(O_tmds_data_n[lane])
            );
        end
    endgenerate

    logic [24:0] heartbeat;
    always_ff @(posedge I_clk or negedge board_rst_n) begin
        if (!board_rst_n)
            heartbeat <= '0;
        else
            heartbeat <= heartbeat + 1'b1;
    end
    assign running = heartbeat[24];
endmodule
