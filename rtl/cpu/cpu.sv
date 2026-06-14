import cpu_types::*;

`define ON_TCYCLE(tc) always_ff @(posedge clk) if (tcycle == (tc))

module cpu(
    input logic clk,
    input logic rst,
    bus.parent_port bus
);

    // Clock
    tcycle_t tcycle;
    mcycle_t mcycle;
    cpu_clock clock(
        .clk(clk),
        .rst(rst),
        .rst_mcycle(ctrl.fetch_cycle),
        .tcycle(tcycle),
        .mcycle(mcycle)
    );

    // Registers
    logic [15:0] PC;
    logic [7:0] IR;
    logic [7:0] Z;
    logic [7:0] W;

    logic [7:0] A, B, C, D, E, H, L;
    logic [15:0] SP;
    flags_t F;

    logic [7:0] wr_r8;
    logic [7:0] wr_reg_r8;
    logic [7:0] wr_data_r8;

    logic [15:0] wr_r16;
    logic [15:0] wr_reg_r16;
    logic [15:0] wr_data_r16;

    always_comb begin
        wr_r8 = 0;
        wr_reg_r8 = 0;
        wr_data_r8 = 0;

        wr_r16 = 0;
        wr_reg_r16 = 0;
        wr_data_r16 = 0;

        case (ctrl.wb_dst)
            WB_DST_R16: begin
                wr_r16 = 1'b1;
                wr_reg_r16 = ctrl.wb_r16;
                case (ctrl.wb_src)
                    WB_SRC_WZ: wr_data_r16 = {W, Z};
                endcase
            end
        endcase
    end

    cpu_regfile regfile (
        .clk(clk),
        .rst(rst),
        .tcycle(tcycle),

        .wr_r8(wr_r8),
        .wr_reg_r8(wr_reg_r8),
        .wr_data_r8(wr_data_r8),

        .wr_r16(wr_r16),
        .wr_reg_r16(wr_reg_r16),
        .wr_data_r16(wr_data_r16),

        .A(A), .B(B), .C(C), .D(D), .E(E), .H(H), .L(L),
        .SP(SP),
        .F(F)
    );

    // Control
    control_t ctrl;
    cpu_control control(
        .IR(IR),
        .mcycle(mcycle),
        .ctrl(ctrl)
    );

    // Bus
    logic [15:0] bus_addr;
    logic [7:0] bus_data_wr;
    logic [7:0] bus_data_rd;

    always_comb begin
        case (ctrl.bus_rd_src)
            BUS_RD_SRC_PC: bus_addr = PC;
        endcase
    end

    `ON_TCYCLE(T3)
        if (ctrl.bus_rd)
            case (ctrl.bus_rd_dst)
                BUS_RD_DST_IR: IR <= bus_data_rd;
                BUS_RD_DST_Z: Z <= bus_data_rd;
                BUS_RD_DST_W: W <= bus_data_rd;
            endcase

    cpu_bus_controller bus_controller(
        .clk(clk),
        .tcycle(tcycle),
        .rd(ctrl.bus_rd),
        .wr(ctrl.bus_wr),
        .addr(bus_addr),
        .data_wr(bus_data_wr),
        .data_rd(bus_data_rd),
        .bus(bus)
    );

    // Increment-Decrement Unit
    logic [15:0] idu_in;
    logic [15:0] idu_out;
    logic signed [1:0] idu_adj;

    always_comb begin
        case (ctrl.idu_src)
            IDU_SRC_PC: idu_in = PC;
        endcase
    end

    always_comb begin
        case (ctrl.idu_adj)
            IDU_ADJ_INC: idu_adj = 'sh1;
            IDU_ADJ_DEC: idu_adj = -'sh1;
        endcase
    end

    `ON_TCYCLE(T3)
        case (ctrl.idu_dst)
            IDU_DST_PC: PC <= idu_out;
        endcase
    
    cpu_idu idu(
        .in(idu_in),
        .adj(idu_adj),
        .out(idu_out)
    );


endmodule
