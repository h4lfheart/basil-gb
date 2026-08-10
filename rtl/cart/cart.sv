import cart_types::*;

module cart(
    input logic clk,
    input logic rst,
    bus.child_port bus
`ifndef VERILATOR
    ,
    input logic [7:0] header_cart_type,
    cart_ext_mem.core mem
`endif
);
`ifdef VERILATOR
    logic [7:0] rom [ROM_SIZE] /*verilator public*/;
    logic [7:0] ram [RAM_SIZE];
`endif

    logic [7:0] cart_type;

    logic [ROM_ADDR_WIDTH-1:0] rom_addr;
    logic [RAM_ADDR_WIDTH-1:0] ram_addr;
    logic rom_cs;
    logic ram_cs;

    logic [ROM_ADDR_WIDTH-1:0] mbc0_rom_addr;
    logic [RAM_ADDR_WIDTH-1:0] mbc0_ram_addr;
    logic mbc0_rom_cs;
    logic mbc0_ram_cs;

    logic [ROM_ADDR_WIDTH-1:0] mbc1_rom_addr;
    logic [RAM_ADDR_WIDTH-1:0] mbc1_ram_addr;
    logic mbc1_rom_cs;
    logic mbc1_ram_cs;

    logic [ROM_ADDR_WIDTH-1:0] mbc3_rom_addr;
    logic [RAM_ADDR_WIDTH-1:0] mbc3_ram_addr;
    logic mbc3_rom_cs;
    logic mbc3_ram_cs;

    logic [ROM_ADDR_WIDTH-1:0] mbc5_rom_addr;
    logic [RAM_ADDR_WIDTH-1:0] mbc5_ram_addr;
    logic mbc5_rom_cs;
    logic mbc5_ram_cs;

`ifdef VERILATOR
    assign cart_type = rom[ROM_ADDR_WIDTH'(HEADER_CART_TYPE)];
`else
    assign cart_type = header_cart_type;
`endif

    mbc0 mbc0(
        .addr(bus.addr),
        .cs(bus.cs),
        .rom_addr(mbc0_rom_addr),
        .rom_cs(mbc0_rom_cs),
        .ram_addr(mbc0_ram_addr),
        .ram_cs(mbc0_ram_cs)
    );

    mbc1 mbc1(
        .clk(clk),
        .rst(rst),
        .addr(bus.addr),
        .data_wr(bus.data_wr),
        .wr(bus.wr),
        .cs(bus.cs),
        .rom_addr(mbc1_rom_addr),
        .rom_cs(mbc1_rom_cs),
        .ram_addr(mbc1_ram_addr),
        .ram_cs(mbc1_ram_cs)
    );

    mbc3 mbc3(
        .clk(clk),
        .rst(rst),
        .addr(bus.addr),
        .data_wr(bus.data_wr),
        .wr(bus.wr),
        .cs(bus.cs),
        .rom_addr(mbc3_rom_addr),
        .rom_cs(mbc3_rom_cs),
        .ram_addr(mbc3_ram_addr),
        .ram_cs(mbc3_ram_cs)
    );

    mbc5 mbc5(
        .clk(clk),
        .rst(rst),
        .addr(bus.addr),
        .data_wr(bus.data_wr),
        .wr(bus.wr),
        .cs(bus.cs),
        .rom_addr(mbc5_rom_addr),
        .rom_cs(mbc5_rom_cs),
        .ram_addr(mbc5_ram_addr),
        .ram_cs(mbc5_ram_cs)
    );

    always_comb begin
        case (cart_type)
            CART_TYPE_MBC1,
            CART_TYPE_MBC1_RAM,
            CART_TYPE_MBC1_RAM_BATTERY: begin
                rom_addr = mbc1_rom_addr;
                rom_cs = mbc1_rom_cs;
                ram_addr = mbc1_ram_addr;
                ram_cs = mbc1_ram_cs;
            end
            CART_TYPE_MBC3_TIMER_BATTERY,
            CART_TYPE_MBC3_TIMER_RAM_BATTERY,
            CART_TYPE_MBC3,
            CART_TYPE_MBC3_RAM,
            CART_TYPE_MBC3_RAM_BATTERY: begin
                rom_addr = mbc3_rom_addr;
                rom_cs = mbc3_rom_cs;
                ram_addr = mbc3_ram_addr;
                ram_cs = mbc3_ram_cs;
            end
            CART_TYPE_MBC5,
            CART_TYPE_MBC5_RAM,
            CART_TYPE_MBC5_RAM_BATTERY,
            CART_TYPE_MBC5_RUMBLE,
            CART_TYPE_MBC5_RUMBLE_RAM,
            CART_TYPE_MBC5_RUMBLE_RAM_BATTERY: begin
                rom_addr = mbc5_rom_addr;
                rom_cs = mbc5_rom_cs;
                ram_addr = mbc5_ram_addr;
                ram_cs = mbc5_ram_cs;
            end
            default: begin
                rom_addr = mbc0_rom_addr;
                rom_cs = mbc0_rom_cs;
                ram_addr = mbc0_ram_addr;
                ram_cs = mbc0_ram_cs;
            end
        endcase
    end


`ifdef VERILATOR
    always_comb begin
        bus.data_rd = 'hFF;

        if (bus.rd) begin
            if (rom_cs)
                bus.data_rd = rom[rom_addr];
            else if (ram_cs)
                bus.data_rd = ram[ram_addr];
        end
    end

    always_ff @(posedge clk) begin
        if (bus.wr && ram_cs)
            ram[ram_addr] <= bus.data_wr;
    end
`else
    assign mem.req = bus.cs && bus.rd && (rom_cs || ram_cs);
    assign mem.wr = bus.cs && bus.wr && ram_cs;
    assign mem.ram_sel = ram_cs;
    assign mem.addr = ram_cs ? ROM_ADDR_WIDTH'(ram_addr) : rom_addr;
    assign mem.data_wr = bus.data_wr;

    always_comb begin
        bus.data_rd = 8'hFF;
        if (bus.cs && bus.rd && (rom_cs || ram_cs))
            bus.data_rd = mem.data_rd;
    end
`endif

endmodule
