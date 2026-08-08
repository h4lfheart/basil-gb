import cart_types::*;
import mem_types::*;

module mbc0(
    input logic [15:0] addr,
    input logic cs,
    output logic [ROM_ADDR_WIDTH-1:0] rom_addr,
    output logic rom_cs,
    output logic [RAM_ADDR_WIDTH-1:0] ram_addr,
    output logic ram_cs
);
    assign rom_cs = cs && addr inside {[CART_ROM_START:CART_ROM_END]};
    assign rom_addr = ROM_ADDR_WIDTH'(addr[14:0]);

    assign ram_cs = 0;
    assign ram_addr = '0;

endmodule
