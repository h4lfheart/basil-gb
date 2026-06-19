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

    localparam logic [15:0] REG_BANK = 'hFF50;
    localparam logic [15:0] REG_SB = 'hFF01;
    localparam logic [15:0] REG_SC = 'hFF02;
    localparam logic [15:0] REG_IF = 'hFF0F;
    localparam logic [15:0] REG_IE = 'hFFFF;
endpackage