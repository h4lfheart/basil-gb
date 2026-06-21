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


    typedef enum logic [1:0] {
        PPU_MODE_HBLANK = 2'd0,
        PPU_MODE_VBLANK = 2'd1,
        PPU_MODE_OAM = 2'd2,
        PPU_MODE_DRAW = 2'd3
    } ppu_mode_t;


    localparam logic [8:0] DOTS_PER_LINE = 'd456;
    localparam logic [8:0] OAM_END = 'd80;
    localparam logic [7:0] LY_MAX = 'd153;
    localparam logic [7:0] VBLANK_START = 'd144;
endpackage