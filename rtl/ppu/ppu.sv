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
    logic B7;
    logic LYC_INT;
    logic OAM_INT;
    logic VBLANK_INT;
    logic HBLANK_INT;
    logic LYC_FLAG;
    logic [1:0] MODE;
} stat_t;

module ppu(
    input logic clk,
    input logic rst,
    bus.child_port bus,
    output logic vblank_interrupt
);

    // Registers
    lcdc_t LCDC /* verilator public */;
    stat_t STAT;
    logic [7:0] SCY /*verilator public*/;
    logic [7:0] SCX /*verilator public*/;
    logic [7:0] LY /*verilator public*/;
    logic [7:0] LYC;
    logic [7:0] BGP /*verilator public*/;
    logic [7:0] OBP0;
    logic [7:0] OBP1;
    logic [7:0] WY;
    logic [7:0] WX;

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd)
            case (bus.addr)
                REG_LCDC: bus.data_rd = LCDC;
                REG_STAT: bus.data_rd = STAT;
                REG_SCY: bus.data_rd = SCY;
                REG_SCX: bus.data_rd = SCX;
                REG_LY: bus.data_rd = LY;
                REG_LYC: bus.data_rd = LYC;
                REG_BGP: bus.data_rd = BGP;
                REG_OBP0: bus.data_rd = OBP0;
                REG_OBP1: bus.data_rd = OBP1;
                REG_WY: bus.data_rd = WY;
                REG_WX: bus.data_rd = WX;
            endcase
    end

     always @(posedge clk) begin
        if (bus.cs && bus.wr)
            case (bus.addr)
                REG_LCDC: LCDC <= bus.data_wr;
                REG_STAT: STAT <= {bus.data_wr[7:3], STAT[2:0]};
                REG_SCY: SCY <= bus.data_wr;
                REG_SCX: SCX <= bus.data_wr;
                REG_LYC: LYC <= bus.data_wr;
                REG_BGP: BGP <= bus.data_wr;
                REG_OBP0: OBP0 <= bus.data_wr;
                REG_OBP1: OBP1 <= bus.data_wr;
                REG_WY: WY <= bus.data_wr;
                REG_WX: WX <= bus.data_wr;
            endcase
    end

    logic [8:0] dot;

    always_ff @(posedge clk) begin
        if (rst) begin
            dot <= 0;
            LY <= 0;
            vblank_interrupt <= 0;
        end else if (LCDC.EN) begin
            vblank_interrupt <= 0;
            if (dot == 'd455) begin
                dot <= 0;
                LY <= (LY == 'd153) ? 0 : LY + 1;

                if (LY == 'd143)
                    vblank_interrupt <= 1;
            end 
            else begin
                dot <= dot + 1;
            end
        end
    end
endmodule

