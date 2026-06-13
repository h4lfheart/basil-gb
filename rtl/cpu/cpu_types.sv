package cpu_types;

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

    `define OP_NOP 'b00000000
    
    `define OP_LD_RR_NN 'b00000000

    typedef enum {
        BUS_RD_SRC_NONE,
        BUS_RD_SRC_PC
    } bus_rd_src_t;
    
    typedef enum {
        BUS_RD_DST_NONE,
        BUS_RD_DST_IR
    } bus_rd_dst_t;

    typedef enum {
        ID_ADJ_NONE,
        IDU_ADJ_INC,
        IDU_ADJ_DEC
    } idu_adj_t;

    typedef enum {
        IDU_SRC_NONE,
        IDU_SRC_PC
    } idu_src_t;
    
    typedef enum {
        IDU_DST_NONE,
        IDU_DST_PC
    } idu_dst_t;
    
    typedef struct packed {

        // Bus
        logic bus_rd;
        logic bus_wr;
        bus_rd_src_t bus_rd_src;
        bus_rd_dst_t bus_rd_dst;

        // Increment-Decrement Unit
        idu_adj_t idu_adj;
        idu_src_t idu_src;
        idu_dst_t idu_dst;


        // Misc.
        logic fetch_cycle;

    } control_t;
endpackage