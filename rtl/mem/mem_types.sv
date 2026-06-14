package mem_types;
    localparam logic [15:0] BOOT_ROM_START = 'h0000;
    localparam logic [15:0] BOOT_ROM_END = 'h00FF;

    localparam logic [15:0] CART_ROM_START = 'h0000;
    localparam logic [15:0] CART_ROM_END = 'h7FFF;

    localparam logic [15:0] CART_RAM_START = 'hA000;
    localparam logic [15:0] CART_RAM_END = 'hBFFF;

    localparam logic [15:0] VRAM_START = 'h8000;
    localparam logic [15:0] VRAM_END = 'h9FFF;

    localparam logic [15:0] HRAM_START = 'hFF80;
    localparam logic [15:0] HRAM_END = 'hFFFE;
endpackage