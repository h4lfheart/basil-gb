package ppu_types;

    typedef struct packed {
        logic EN;
        logic WIN_TILE_MAP;
        logic WIN_EN;
        logic TILE_DATA_MAP;
        logic BG_TILE_MAP;
        logic OBJ_SIZE;
        logic OBJ_EN;
        logic BG_EN;
    } lcdc_t;

    typedef struct packed {
        logic LYC_INT;
        logic OAM_INT;
        logic VBLANK_INT;
        logic HBLANK_INT;
    } stat_int_t;

    typedef struct packed {
        logic auto_increment;
        logic unused;
        logic [5:0] address;
    } palette_index_t;

    typedef struct packed {
        logic bg_priority;
        logic y_flip;
        logic x_flip;
        logic dmg_palette;
        logic vram_bank;
        logic [2:0] cgb_palette;
    } oam_flags_t;

    typedef struct packed {
        logic [7:0] y;
        logic [7:0] x;
        logic [7:0] tile;
        oam_flags_t flags;
    } oam_entry_t;

    typedef struct packed {
        logic bg_priority;
        logic y_flip;
        logic x_flip;
        logic unused;
        logic vram_bank;
        logic [2:0] palette;
    } tile_attr_t;

    typedef enum logic [1:0] {
        PPU_MODE_HBLANK = 2'd0,
        PPU_MODE_VBLANK = 2'd1,
        PPU_MODE_OAM = 2'd2,
        PPU_MODE_DRAW = 2'd3
    } ppu_mode_t;

    localparam logic [15:0] PPU_REG_START = 'hFF40;
    localparam logic [15:0] PPU_REG_END = 'hFF4B;

    localparam logic [15:0] REG_LCDC = 'hFF40;
    localparam logic [15:0] REG_STAT = 'hFF41;
    localparam logic [15:0] REG_SCY = 'hFF42;
    localparam logic [15:0] REG_SCX = 'hFF43;
    localparam logic [15:0] REG_LY = 'hFF44;
    localparam logic [15:0] REG_LYC = 'hFF45;
    localparam logic [15:0] REG_BGP = 'hFF47;
    localparam logic [15:0] REG_OBP0 = 'hFF48;
    localparam logic [15:0] REG_OBP1 = 'hFF49;
    localparam logic [15:0] REG_WY = 'hFF4A;
    localparam logic [15:0] REG_WX = 'hFF4B;
    localparam logic [15:0] REG_VBK = 'hFF4F;
    localparam logic [15:0] REG_BCPS = 'hFF68;
    localparam logic [15:0] REG_BCPD = 'hFF69;
    localparam logic [15:0] REG_OCPS = 'hFF6A;
    localparam logic [15:0] REG_OCPD = 'hFF6B;

    function automatic logic is_ppu_reg(input logic [15:0] addr);
        return addr inside {
            [PPU_REG_START:PPU_REG_END],
            REG_VBK,
            REG_BCPS,
            REG_BCPD,
            REG_OCPS,
            REG_OCPD
        };
    endfunction

    localparam logic [8:0] DOTS_PER_LINE = 'd456;
    localparam logic [8:0] OAM_SCAN_END = 'd80;
    localparam logic [7:0] LY_MAX = 'd153;
    localparam logic [7:0] VBLANK_START = 'd144;
    localparam int SPRITES_PER_LINE = 10;
    localparam int OAM_SPRITE_COUNT = 40;
endpackage
