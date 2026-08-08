import cart_types::*;

module cart(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] rom [ROM_SIZE] /*verilator public*/;
    logic [7:0] ram [RAM_SIZE];

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

    assign cart_type = rom[ROM_ADDR_WIDTH'(HEADER_CART_TYPE)];

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
            default: begin
                rom_addr = mbc0_rom_addr;
                rom_cs = mbc0_rom_cs;
                ram_addr = mbc0_ram_addr;
                ram_cs = mbc0_ram_cs;
            end
        endcase
    end

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

endmodule
