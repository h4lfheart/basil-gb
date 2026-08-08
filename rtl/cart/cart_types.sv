package cart_types;
    localparam int ROM_SIZE = 'h200000;
    localparam int RAM_SIZE = 'h8000;
    localparam int ROM_ADDR_WIDTH = 21;
    localparam int RAM_ADDR_WIDTH = 15;

    localparam logic [15:0] HEADER_CART_TYPE = 'h0147;

    localparam logic [7:0] CART_TYPE_ROM_ONLY = 'h00;
    localparam logic [7:0] CART_TYPE_MBC1 = 'h01;
    localparam logic [7:0] CART_TYPE_MBC1_RAM = 'h02;
    localparam logic [7:0] CART_TYPE_MBC1_RAM_BATTERY = 'h03;
endpackage
