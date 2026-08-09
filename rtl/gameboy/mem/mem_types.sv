package mem_types;
    typedef struct packed {
        logic [3:0] unused_high;
        logic partial_cgb_disable;
        logic dmg_compat;
        logic [1:0] unused_low;
    } key0_t;

    localparam logic [15:0] BOOT_ROM_START = 'h0000;
    localparam logic [15:0] BOOT_ROM_END = 'h00FF;

    localparam logic [15:0] BOOT_ROM_EXT_START = 'h0200;
    localparam logic [15:0] BOOT_ROM_EXT_END = 'h08FF;

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

    localparam logic [15:0] OAM_START = 'hFE00;
    localparam logic [15:0] OAM_END = 'hFE9F;

    localparam logic [15:0] HRAM_START = 'hFF80;
    localparam logic [15:0] HRAM_END = 'hFFFE;

    localparam logic [15:0] REG_JOYP = 'hFF00;

    localparam logic [15:0] REG_SB = 'hFF01;
    localparam logic [15:0] REG_SC = 'hFF02;
    
    localparam logic [15:0] REG_DIV = 'hFF04;
    localparam logic [15:0] REG_TIMA = 'hFF05;
    localparam logic [15:0] REG_TMA = 'hFF06;
    localparam logic [15:0] REG_TAC = 'hFF07;

    localparam logic [15:0] REG_IF = 'hFF0F;

    localparam logic [15:0] REG_DMA = 'hFF46;

    localparam logic [15:0] REG_KEY0 = 'hFF4C;
    localparam logic [15:0] REG_BANK = 'hFF50;

    localparam logic [15:0] REG_HDMA1 = 'hFF51;
    localparam logic [15:0] REG_HDMA2 = 'hFF52;
    localparam logic [15:0] REG_HDMA3 = 'hFF53;
    localparam logic [15:0] REG_HDMA4 = 'hFF54;
    localparam logic [15:0] REG_HDMA5 = 'hFF55;

    localparam logic [15:0] REG_SVBK = 'hFF70;

    localparam logic [15:0] REG_IE = 'hFFFF;
endpackage
