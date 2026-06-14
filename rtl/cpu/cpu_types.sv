package cpu_types;

    `define OP_NOP 'b00000000

    `define OP_CALL_NN 'b11001101
    `define OP_JR_CC_E 'b001??000

    `define OP_INC_R 'b00???100

    `define OP_LD_R_R 'b01??????
    `define OP_HALT 'b01110110
    `define OP_LD_R_N 'b00???110

    `define OP_LD_RR_NN 'b00??0001
    `define OP_LD_RR_MEM_A 'b00??0010
    `define OP_LD_A_RR_MEM 'b00??1010

    `define OP_LDH_N_A 'b11100000
    `define OP_LDH_C_A 'b11100010

    `define OP_XOR_R 'b10101???

    `define OP_CB 'b11001011

    `define OP_CB_BIT 'b01??????
    `define OP_CB_RES 'b10??????
    `define OP_CB_SET 'b11??????

    typedef enum logic [1:0] {
        T0 = 'd0,
        T1 = 'd1,
        T2 = 'd2,
        T3 = 'd3
    } tcycle_t;

    typedef enum logic [2:0] {
        M0 = 'd0,
        M1 = 'd1,
        M2 = 'd2,
        M3 = 'd3,
        M4 = 'd4,
        M5 = 'd5
    } mcycle_t;

    typedef enum {
        BUS_RD_SRC_NONE,
        BUS_RD_SRC_PC,
        BUS_RD_SRC_WZ,
        BUS_RD_SRC_R16
    } bus_rd_src_t;
    
    typedef enum {
        BUS_RD_DST_NONE,
        BUS_RD_DST_IR,
        BUS_RD_DST_Z,
        BUS_RD_DST_W
    } bus_rd_dst_t;

    typedef enum {
        BUS_WR_SRC_NONE,
        BUS_WR_SRC_R8,
        BUS_WR_SRC_PCH,
        BUS_WR_SRC_PCL
    } bus_wr_src_t;
    
    typedef enum {
        BUS_WR_DST_NONE,
        BUS_WR_DST_R16,
        BUS_WR_DST_C,
        BUS_WR_DST_Z
    } bus_wr_dst_t;

    typedef enum {
        ID_ADJ_NONE,
        IDU_ADJ_INC,
        IDU_ADJ_DEC,
        IDU_ADJ_CARRY
    } idu_adj_t;

    typedef enum {
        IDU_SRC_NONE,
        IDU_SRC_PC,
        IDU_SRC_R16,
        IDU_SRC_WZ,
        IDU_SRC_PCH
    } idu_src_t;
    
    typedef enum {
        IDU_DST_NONE,
        IDU_DST_PC,
        IDU_DST_W
    } idu_dst_t;

    typedef enum {
        WB_SRC_NONE,
        WB_SRC_WZ,
        WB_SRC_ALU,
        WB_SRC_IDU
    } wb_src_t;

    typedef enum {
        WB_DST_NONE,
        WB_DST_R8,
        WB_DST_R16,
        WB_DST_PC
    } wb_dst_t;

    typedef enum {
        ALU_ACTION_NONE,
        ALU_ACTION_BIT,
        ALU_ACTION_RES,
        ALU_ACTION_SET,

        ALU_ACTION_INC,

        ALU_ACTION_ADD,
        ALU_ACTION_XOR,

        ALU_ACTION_LD
    } alu_action_t;

    typedef enum {
        ALU_SRC_NONE,
        ALU_SRC_R8,
        ALU_SRC_Z,
        ALU_SRC_PCL
    } alu_src_t;

    typedef enum {
        ALU_DST_NONE,
        ALU_DST_Z
    } alu_dst_t;

    typedef enum logic [2:0] {
        R8_B = 'd0,
        R8_C = 3'd1,
        R8_D = 'd2,
        R8_E = 'd3,
        R8_H = 'd4,
        R8_L = 'd5,
        R8_HL = 'd6, // INVALID
        R8_A = 'd7
    } r8_t;

    typedef enum logic [2:0] {
        R16_BC = 'd0,
        R16_DE = 'd1,
        R16_HL = 'd2,
        R16_SP = 'd3,
        R16_AF = 'd4
    } r16_t;

    typedef enum logic [2:0] {
        R16STK_BC = 'd0,
        R16STK_DE = 'd1,
        R16STK_HL = 'd2,
        R16STK_AF = 'd3
    } r16stk_t;

    typedef enum logic [2:0] {
        R16MEM_BC = 'd0,
        R16MEM_DE = 'd1,
        R16MEM_HLI = 'd2,
        R16MEM_HLD = 'd3
    } r16mem_t;

    function automatic r16_t r16_to_r16(logic [1:0] register);
        case (register)
            R16_BC: return R16_BC;
            R16_DE: return R16_DE;
            R16_HL: return R16_HL;
            R16_SP: return R16_SP;
            R16_AF: return R16_AF;
        endcase
    endfunction

    function automatic r16_t r16stk_to_r16(logic [1:0] register);
        case (register)
            R16STK_BC: return R16_BC;
            R16STK_DE: return R16_DE;
            R16STK_HL: return R16_HL;
            R16STK_AF: return R16_AF;
        endcase
    endfunction

    function automatic r16_t r16mem_to_r16(logic [1:0] register);
        case (register)
            R16MEM_BC: return R16_BC;
            R16MEM_DE: return R16_DE;
            R16MEM_HLI: return R16_HL;
            R16MEM_HLD: return R16_HL;
        endcase
    endfunction

    typedef struct packed {
        logic z; // zero
        logic n; // subtract
        logic h; // half-carry
        logic c; // carry
        logic [3:0] unused;
    } flags_t;

    
    typedef enum logic [1:0] {
        CC_NZ = 2'd0,
        CC_Z = 2'd1,
        CC_NC = 2'd2,
        CC_C = 2'd3
    } cc_t;
    
    typedef struct packed {

        // Bus
        logic bus_rd;
        bus_rd_src_t bus_rd_src;
        bus_rd_dst_t bus_rd_dst;
        r16_t bus_rd_src_r16;

        logic bus_wr;
        bus_wr_src_t bus_wr_src;
        r8_t bus_wr_src_r8;

        bus_wr_dst_t bus_wr_dst;
        r16_t bus_wr_dst_r16;

        // Increment-Decrement Unit
        idu_adj_t idu_adj;
        idu_src_t idu_src;
        r16_t idu_src_r16;
        idu_dst_t idu_dst;

        // Writeback
        wb_src_t wb_src;
        wb_dst_t wb_dst;
        r8_t wb_r8;
        r16_t wb_r16;
        logic wb_flags;

        // ALU
        alu_action_t alu_action;
        alu_src_t alu_a_src;
        alu_src_t alu_b_src;
        r8_t alu_a_r8;
        r8_t alu_b_r8;
        logic [2:0] alu_bit;
        alu_dst_t alu_dst;

        // Misc.
        logic fetch_cycle;
        logic set_cb_prefix;
        cc_t cc;

    } control_t;
endpackage