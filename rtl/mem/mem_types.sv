package mem_types;
    localparam logic [15:0] BOOT_ROM_START = 'h0000;
    localparam logic [15:0] BOOT_ROM_END = 'h00FF;

    localparam logic [15:0] CART_ROM_START = 'h0000;
    localparam logic [15:0] CART_ROM_END = 'h7FFF;

    localparam logic [15:0] VRAM_START = 'h8000;
    localparam logic [15:0] VRAM_END = 'h9FFF;

    localparam logic [15:0] CART_RAM_START = 'hA000;
    localparam logic [15:0] CART_RAM_END = 'hBFFF;

    localparam logic [15:0] WRAM_BANK0_START = 'hC000;
    localparam logic [15:0] WRAM_BANK0_END = 'hCFFF;
    localparam logic [15:0] WRAM_BANKX_START = 'hD000;
    localparam logic [15:0] WRAM_BANKX_END = 'hDFFF;
    localparam logic [15:0] ECHO_BANK0_START = 'hE000;
    localparam logic [15:0] ECHO_BANK0_END = 'hEFFF;
    localparam logic [15:0] ECHO_BANKX_START = 'hF000;
    localparam logic [15:0] ECHO_BANKX_END = 'hFDFF;

    localparam logic [15:0] HRAM_START = 'hFF80;
    localparam logic [15:0] HRAM_END = 'hFFFE;

    localparam logic [15:0] PPU_REG_START = 'hFF40;
    localparam logic [15:0] PPU_REG_END = 'hFF4B;

    localparam logic [15:0] REG_SB = 'hFF01;
    localparam logic [15:0] REG_SC = 'hFF02;
    
    localparam logic [15:0] REG_DIV = 'hFF04;
    localparam logic [15:0] REG_TIMA = 'hFF05;
    localparam logic [15:0] REG_TMA = 'hFF06;
    localparam logic [15:0] REG_TAC = 'hFF07;

    localparam logic [15:0] REG_IF = 'hFF0F;

    localparam logic [15:0] REG_LCDC = 'hFF40;
    localparam logic [15:0] REG_STAT = 'hFF41;
    localparam logic [15:0] REG_SCY = 'hFF42;
    localparam logic [15:0] REG_SCX = 'hFF43;
    localparam logic [15:0] REG_LY = 'hFF44;
    localparam logic [15:0] REG_LYC = 'hFF45;
    localparam logic [15:0] REG_DMA = 'hFF46;
    localparam logic [15:0] REG_BGP = 'hFF47;
    localparam logic [15:0] REG_OBP0 = 'hFF48;
    localparam logic [15:0] REG_OBP1 = 'hFF49;
    localparam logic [15:0] REG_WY = 'hFF4A;
    localparam logic [15:0] REG_WX = 'hFF4B;

    localparam logic [15:0] REG_BANK = 'hFF50;

    localparam logic [15:0] REG_IE = 'hFFFF;
endpackage