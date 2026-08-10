import cart_types::*;
import mem_types::*;

module mbc5(
    input logic clk,
    input logic rst,
    input logic [15:0] addr,
    input logic [7:0] data_wr,
    input logic wr,
    input logic cs,
    output logic [ROM_ADDR_WIDTH-1:0] rom_addr,
    output logic rom_cs,
    output logic [RAM_ADDR_WIDTH-1:0] ram_addr,
    output logic ram_cs
);
    localparam logic [15:0] ROM_BANKX_START = 'h4000;
    localparam logic [15:0] ROM_BANKX_END = 'h7FFF;

    localparam logic [15:0] RAM_ENABLE_START = 'h0000;
    localparam logic [15:0] RAM_ENABLE_END = 'h1FFF;
    localparam logic [15:0] ROM_BANK_LOW_START = 'h2000;
    localparam logic [15:0] ROM_BANK_LOW_END = 'h2FFF;
    localparam logic [15:0] ROM_BANK_HIGH_START = 'h3000;
    localparam logic [15:0] ROM_BANK_HIGH_END = 'h3FFF;
    localparam logic [15:0] RAM_BANK_START = 'h4000;
    localparam logic [15:0] RAM_BANK_END = 'h5FFF;

    localparam logic [3:0] RAM_ENABLE_VALUE = 'hA;

    logic [8:0] rom_bank;
    logic [3:0] ram_bank;
    logic ram_enabled;

    always_ff @(posedge clk) begin
        if (rst) begin
            rom_bank <= 'd1;
            ram_bank <= 'd0;
            ram_enabled <= 0;
        end
        else if (cs && wr) begin
            if (addr inside {[RAM_ENABLE_START:RAM_ENABLE_END]})
                ram_enabled <= data_wr[3:0] == RAM_ENABLE_VALUE;
            else if (addr inside {[ROM_BANK_LOW_START:ROM_BANK_LOW_END]})
                rom_bank[7:0] <= data_wr;
            else if (addr inside {[ROM_BANK_HIGH_START:ROM_BANK_HIGH_END]})
                rom_bank[8] <= data_wr[0];
            else if (addr inside {[RAM_BANK_START:RAM_BANK_END]})
                ram_bank <= data_wr[3:0];
        end
    end

    always_comb begin
        rom_cs = cs && addr inside {[CART_ROM_START:CART_ROM_END]};
        rom_addr = addr inside {[ROM_BANKX_START:ROM_BANKX_END]} ? {rom_bank[6:0], addr[13:0]} : ROM_ADDR_WIDTH'(addr[13:0]);
        ram_cs = cs && ram_enabled && addr inside {[CART_RAM_START:CART_RAM_END]};
        ram_addr = {ram_bank[2:0], addr[12:0]};
    end

endmodule
