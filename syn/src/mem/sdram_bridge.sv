module sdram_bridge #(
    parameter logic [22:0] CART_RAM_BASE = 'h20_0000,
    parameter logic [22:0] WRAM_BASE = 'h21_0000
) (
    input logic gb_clk,
    input logic enable,
    cart_ext_mem.memory cart_mem,
    wram_ext_mem.memory wram_mem,
    input logic sdram_clk,
    input logic sdram_rst_n,
    sdram_bus.client sdram
);
    localparam logic [3:0] ISSUE_PHASE = 'd2;

    logic [2:0] gb_sync;
    logic [3:0] phase;
    logic [7:0] data_latched;
    logic [15:0] refresh_div;
    logic refresh_pending;

    wire gb_rise = gb_sync[1] & ~gb_sync[2];

    logic [22:0] cart_addr;
    assign cart_addr = cart_mem.ram_sel
        ? (CART_RAM_BASE | {2'b00, cart_mem.addr})
        : {2'b00, cart_mem.addr};

    always_ff @(posedge sdram_clk or negedge sdram_rst_n) begin
        if (!sdram_rst_n) begin
            gb_sync <= '0;
            phase <= 'hF;
            sdram.rd <= 1'b0;
            sdram.wr <= 1'b0;
            sdram.refresh <= 1'b0;
            sdram.addr <= '0;
            sdram.din <= '0;
            data_latched <= 8'hFF;
            refresh_div <= '0;
            refresh_pending <= 1'b0;
        end else begin
            sdram.rd <= 1'b0;
            sdram.wr <= 1'b0;
            sdram.refresh <= 1'b0;
            gb_sync <= {gb_sync[1:0], gb_clk};

            if (gb_rise)
                phase <= '0;
            else if (phase != 'hF)
                phase <= phase + 1'b1;

            refresh_div <= refresh_div + 1'b1;
            if (refresh_div >= 'd800) begin
                refresh_div <= '0;
                refresh_pending <= 1'b1;
            end

            if (phase == ISSUE_PHASE && !sdram.busy) begin
                if (enable && wram_mem.wr) begin
                    sdram.wr <= 1'b1;
                    sdram.addr <= WRAM_BASE | {8'b0, wram_mem.addr};
                    sdram.din <= wram_mem.data_wr;
                end else if (enable && wram_mem.req) begin
                    sdram.rd <= 1'b1;
                    sdram.addr <= WRAM_BASE | {8'b0, wram_mem.addr};
                end else if (enable && cart_mem.wr) begin
                    sdram.wr <= 1'b1;
                    sdram.addr <= cart_addr;
                    sdram.din <= cart_mem.data_wr;
                end else if (enable && cart_mem.req) begin
                    sdram.rd <= 1'b1;
                    sdram.addr <= cart_addr;
                end else if (refresh_pending) begin
                    sdram.refresh <= 1'b1;
                    refresh_pending <= 1'b0;
                end
            end

            if (sdram.data_ready)
                data_latched <= sdram.dout;
        end
    end

    assign cart_mem.data_rd = data_latched;
    assign wram_mem.data_rd = data_latched;
endmodule
