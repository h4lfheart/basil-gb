package cart_types;
    localparam int ROM_SIZE = 'h200000;
    localparam int RAM_SIZE = 'h10000;
    localparam int ROM_ADDR_WIDTH = 21;
    localparam int RAM_ADDR_WIDTH = 16;

    localparam logic [15:0] HEADER_CART_TYPE = 'h0147;

    localparam logic [7:0] CART_TYPE_ROM_ONLY = 'h00;
    localparam logic [7:0] CART_TYPE_MBC1 = 'h01;
    localparam logic [7:0] CART_TYPE_MBC1_RAM = 'h02;
    localparam logic [7:0] CART_TYPE_MBC1_RAM_BATTERY = 'h03;
    localparam logic [7:0] CART_TYPE_MBC3_TIMER_BATTERY = 'h0F;
    localparam logic [7:0] CART_TYPE_MBC3_TIMER_RAM_BATTERY = 'h10;
    localparam logic [7:0] CART_TYPE_MBC3 = 'h11;
    localparam logic [7:0] CART_TYPE_MBC3_RAM = 'h12;
    localparam logic [7:0] CART_TYPE_MBC3_RAM_BATTERY = 'h13;
    localparam logic [7:0] CART_TYPE_MBC5 = 'h19;
    localparam logic [7:0] CART_TYPE_MBC5_RAM = 'h1A;
    localparam logic [7:0] CART_TYPE_MBC5_RAM_BATTERY = 'h1B;
    localparam logic [7:0] CART_TYPE_MBC5_RUMBLE = 'h1C;
    localparam logic [7:0] CART_TYPE_MBC5_RUMBLE_RAM = 'h1D;
    localparam logic [7:0] CART_TYPE_MBC5_RUMBLE_RAM_BATTERY = 'h1E;
endpackage
