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

    // Control
    control_t ctrl;

    logic cb_prefix;
    `ON_TCYCLE(T3) begin
        if (ctrl.set_cb_prefix)
            cb_prefix <= 1;
        else if (ctrl.fetch_cycle)
            cb_prefix <= 0;
    end

    logic CC;
    always_comb begin
        case (ctrl.cc)
            CC_NZ: CC <= ~F.z;
            CC_Z: CC <= F.z;
            CC_NC: CC <= ~F.c;
            CC_C: CC <= F.c;
        endcase
    end


    cpu_control control(
        .IR(IR),
        .CC(CC),
        .mcycle(mcycle),
        .cb_prefix(cb_prefix),
        .ctrl(ctrl)
    );

    // Bus
    logic [15:0] bus_addr;
    logic [7:0] bus_data_wr;
    logic [7:0] bus_data_rd;

    always_comb begin
        case (ctrl.bus_rd_src)
            BUS_RD_SRC_PC: bus_addr = PC;
            BUS_RD_SRC_WZ: bus_addr = WZ;
            BUS_RD_SRC_R16: bus_addr = r16_sel(ctrl.bus_rd_src_r16);
        endcase

        case (ctrl.bus_wr_src)
            BUS_WR_SRC_R8: bus_data_wr = r8_sel(ctrl.bus_wr_src_r8);
            BUS_WR_SRC_PCH: bus_data_wr = PC[15:8];
            BUS_WR_SRC_PCL: bus_data_wr = PC[7:0];
        endcase

        case (ctrl.bus_wr_dst)
            BUS_WR_DST_R16: bus_addr = r16_sel(ctrl.bus_wr_dst_r16);
            BUS_WR_DST_C: bus_addr = {'hFF, C};
            BUS_WR_DST_Z: bus_addr = {'hFF, Z};
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

    // Registers
    logic [15:0] PC;
    logic [7:0] IR;
    
    logic [7:0] Z;
    logic [7:0] W;
    logic [15:0] WZ;
    assign WZ = {W, Z};

    logic [7:0] A, B, C, D, E, H, L;
    logic [15:0] SP;
    flags_t F;

    logic [15:0] BC, DE, HL, AF;
    assign BC = {B, C};
    assign DE = {D, E};
    assign HL = {H, L};
    assign AF = {A, F};

    logic wr_r8;
    logic [7:0] wr_reg_r8;
    logic [7:0] wr_data_r8;

    logic wr_r16;
    logic [15:0] wr_reg_r16;
    logic [15:0] wr_data_r16;
    
    logic wr_flags;
    flags_t wr_data_flags;

    function automatic logic [7:0] r8_sel(r8_t r);
        case (r)
            R8_B: return B;
            R8_C: return C;
            R8_D: return D;
            R8_E: return E;
            R8_H: return H;
            R8_L: return L;
            R8_A: return A;
            R8_HL: begin
                $display("Unsupported R8_HL operand for ALU action %0d", ctrl.alu_action);
                $finish;
            end
        endcase
    endfunction

    function automatic logic [15:0] r16_sel(r16_t r);
        case (r)
            R16_BC: return BC;
            R16_DE: return DE;
            R16_HL: return HL;
            R16_SP: return SP;
            R16_AF: return AF;
        endcase
    endfunction

    function automatic logic [15:0] wb_sel(wb_src_t src);
        case (src)
            WB_SRC_WZ: return WZ;
            WB_SRC_ALU: return alu_result;
            WB_SRC_IDU: return idu_out;
        endcase
    endfunction

    always_comb begin
        wr_r8 = 0;
        wr_reg_r8 = 0;
        wr_data_r8 = 0;

        wr_r16 = 0;
        wr_reg_r16 = 0;
        wr_data_r16 = 0;

        wr_flags = 0;
        wr_data_flags = 0;

        case (ctrl.wb_dst)
            WB_DST_R8: begin
                wr_r8 = 1;
                wr_reg_r8 = ctrl.wb_r8;
                wr_data_r8 = wb_sel(ctrl.wb_src);
            end
            WB_DST_R16: begin
                wr_r16 = 1;
                wr_reg_r16 = ctrl.wb_r16;
                wr_data_r16 = wb_sel(ctrl.wb_src);
            end
        endcase

        if (ctrl.wb_flags)
            wr_flags = 1;
            wr_data_flags = alu_flags;
    end

    
    `ON_TCYCLE(T3)
        case (ctrl.wb_dst)
            WB_DST_PC: PC <= wb_sel(ctrl.wb_src);
        endcase

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

        .wr_flags(wr_flags),
        .wr_data_flags(wr_data_flags),

        .A(A), .B(B), .C(C), .D(D), .E(E), .H(H), .L(L),
        .SP(SP),
        .F(F)
    );

    // ALU
    logic [7:0] alu_a;
    logic [7:0] alu_b;
    logic [7:0] alu_result;
    flags_t alu_flags;

    function automatic logic [7:0] alu_src_sel(alu_src_t src, r8_t r8);
        case (src)
            ALU_SRC_R8: return r8_sel(r8);
            ALU_SRC_Z: return Z;
            ALU_SRC_PCL: return PC[7:0];
        endcase
    endfunction

    always_comb begin
       alu_a = alu_src_sel(ctrl.alu_a_src, ctrl.alu_a_r8);
       alu_b = alu_src_sel(ctrl.alu_b_src, ctrl.alu_b_r8);
    end

    `ON_TCYCLE(T3)
        case (ctrl.alu_dst)
            ALU_DST_Z: Z <= alu_result;
        endcase

    cpu_alu alu(
        .action(ctrl.alu_action),
        .a(alu_a),
        .b(alu_b),
        .bit_idx(ctrl.alu_bit),
        .flags_in(F),
        .result(alu_result),
        .flags(alu_flags)
    );

    // Increment-Decrement Unit
    logic [15:0] idu_in;
    logic [15:0] idu_out;
    logic signed [1:0] idu_adj;

    always_comb begin
        case (ctrl.idu_adj)
            IDU_ADJ_INC: idu_adj = 'sh1;
            IDU_ADJ_DEC: idu_adj = -'sh1;
            IDU_ADJ_CARRY: begin
                logic carry_out;
                carry_out = (9'(Z) + 9'(PC[7:0])) > 9'hFF;
                idu_adj = (carry_out == Z[7]) ? 2'sd0
                        : carry_out ? 2'sd1 : -2'sd1;
            end
        endcase
    end

    always_comb begin
        case (ctrl.idu_src)
            IDU_SRC_PC: idu_in = PC;
            IDU_SRC_R16: idu_in = r16_sel(ctrl.idu_src_r16);
            IDU_SRC_WZ: idu_in = WZ;
            IDU_SRC_PCH: idu_in = PC[15:8];
        endcase
    end

    `ON_TCYCLE(T3)
        case (ctrl.idu_dst)
            IDU_DST_PC: PC <= idu_out;
            IDU_DST_W: W <= idu_out;
        endcase
    
    cpu_idu idu(
        .in(idu_in),
        .adj(idu_adj),
        .out(idu_out)
    );


endmodule
