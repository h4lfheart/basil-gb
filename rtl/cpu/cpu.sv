import cpu_types::*;

`define always_mcycle always_ff @(posedge clk) if (tcycle == T3)

module cpu(
    input logic clk,
    input logic rst,
    bus.parent_port bus,
    bus.child_port reg_bus
);

    // Clock
    tcycle_t tcycle;
    mcycle_t mcycle;
    cpu_clock clock(
        .clk(clk),
        .rst(rst),
        .rst_mcycle(ctrl.last_mcycle),
        .tcycle(tcycle),
        .mcycle(mcycle)
    );

    // Registers
    logic [7:0] IE;
    logic [7:0] IF;

    always_comb begin
        reg_bus.data_rd = 'hFF;
        if (reg_bus.cs && reg_bus.rd)
            case (reg_bus.addr)
                REG_IF: reg_bus.data_rd = IF;
                REG_IE: reg_bus.data_rd = IE;
            endcase
    end

    always @(posedge clk) begin
        if (reg_bus.cs && reg_bus.wr)
            case (reg_bus.addr)
                REG_IF: IF <= reg_bus.data_wr;
                REG_IE: IE <= reg_bus.data_wr;
            endcase
    end

    // IME
    logic IME;
    logic ime_pending;

    `always_mcycle begin

        if (ime_pending) begin
            IME <= 1;
            ime_pending <= 0;
        end

        case (ctrl.ime_action)
            IME_ACTION_EI: begin
                ime_pending <= 1;
            end
            IME_ACTION_DI: begin
                IME <= 0;
                ime_pending <= 0;
            end
            IME_ACTION_RETI: begin
                IME <= 1;
                ime_pending <= 0;
            end
        endcase
    end

    // Control
    control_t ctrl;

    logic cb_prefix;
    `always_mcycle begin
        if (ctrl.set_cb_prefix)
            cb_prefix <= 1;
        else if (ctrl.last_mcycle)
            cb_prefix <= 0;
    end

    function automatic logic cc_sel(cc_t cc);
        case (cc)
            CC_NZ: return ~regfile.F.z;
            CC_Z: return regfile.F.z;
            CC_NC: return ~regfile.F.c;
            CC_C: return regfile.F.c;
        endcase
    endfunction

    logic CC;
    assign CC = cc_sel(ctrl.cc);

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

    function automatic logic [15:0] bus_rd_addr_sel(bus_rd_src_t src);
        case (src)
            BUS_RD_SRC_PC: return PC;
            BUS_RD_SRC_WZ: return WZ;
            BUS_RD_SRC_R16: return regfile.read_r16(ctrl.bus_rd_src_r16);
            BUS_RD_SRC_Z: return {'hFF, Z};
            BUS_RD_SRC_C: return {'hFF, regfile.read_r8(R8_C)};
        endcase
    endfunction

    function automatic logic [7:0] bus_wr_data_sel(bus_wr_src_t src);
        case (src)
            BUS_WR_SRC_Z: return Z;
            BUS_WR_SRC_R8: return regfile.read_r8(ctrl.bus_wr_src_r8);
            BUS_WR_SRC_PCH: return PC[15:8];
            BUS_WR_SRC_PCL: return PC[7:0];
            BUS_WR_SRC_R16H: return regfile.read_r16(ctrl.bus_wr_src_r16)[15:8];
            BUS_WR_SRC_R16L: return regfile.read_r16(ctrl.bus_wr_src_r16)[7:0];
            BUS_WR_SRC_ALU: return alu_result;
        endcase
    endfunction

    function automatic logic [15:0] bus_wr_addr_sel(bus_wr_dst_t dst);
        case (dst)
            BUS_WR_DST_R16: return regfile.read_r16(ctrl.bus_wr_dst_r16);
            BUS_WR_DST_C: return {'hFF, regfile.read_r8(R8_C)};
            BUS_WR_DST_Z: return {'hFF, Z};
            BUS_WR_DST_WZ: return WZ;
        endcase
    endfunction

    always_comb begin
        bus_addr = ctrl.bus_wr ? bus_wr_addr_sel(ctrl.bus_wr_dst)
                               : bus_rd_addr_sel(ctrl.bus_rd_src);
        bus_data_wr = bus_wr_data_sel(ctrl.bus_wr_src);
    end

    `always_mcycle begin
        if (ctrl.bus_rd) begin
            case (ctrl.bus_rd_dst)
                BUS_RD_DST_IR: IR <= bus_data_rd;
                BUS_RD_DST_Z:  Z  <= bus_data_rd;
                BUS_RD_DST_W:  W  <= bus_data_rd;
            endcase
        end
    end

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

    logic Z_SIGN;
    `always_mcycle begin
        if (ctrl.z_sign)
            Z_SIGN <= Z[7];
    end

    logic wr_r8;
    logic [7:0] wr_reg_r8;
    logic [7:0] wr_data_r8;

    logic wr_r16;
    logic [15:0] wr_reg_r16;
    logic [15:0] wr_data_r16;

    logic wr_flags;
    flags_t wr_data_flags;

    function automatic logic [15:0] rst_vector(logic [2:0] rst_tgt);
        case (rst_tgt)
            3'd0: return 'h0000;
            3'd1: return 'h0008;
            3'd2: return 'h0010;
            3'd3: return 'h0018;
            3'd4: return 'h0020;
            3'd5: return 'h0028;
            3'd6: return 'h0030;
            3'd7: return 'h0038;
        endcase
    endfunction

    function automatic logic [15:0] wb_sel(wb_src_t src);
        case (src)
            WB_SRC_WZ: return WZ;
            WB_SRC_ALU: return alu_result;
            WB_SRC_IDU: return idu_out;
            WB_SRC_RST: return rst_vector(ctrl.rst);
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

        if (ctrl.wb_flags) begin
            wr_flags = 1;
            wr_data_flags = alu_flags;
        end
    end

    `always_mcycle begin
        case (ctrl.wb_dst)
            WB_DST_PC: PC <= wb_sel(ctrl.wb_src);
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

        .wr_flags(wr_flags),
        .wr_data_flags(wr_data_flags)
    );

    // ALU
    logic [7:0] alu_a;
    logic [7:0] alu_b;
    logic [7:0] alu_result;
    flags_t alu_flags;

    function automatic logic [7:0] alu_src_sel(alu_src_t src, r8_t r8, r16_t r16);
        case (src)
            ALU_SRC_R8: return regfile.read_r8(r8);
            ALU_SRC_Z: return Z;
            ALU_SRC_PCL: return PC[7:0];
            ALU_SRC_R16H: return regfile.read_r16(r16)[15:8];
            ALU_SRC_R16L: return regfile.read_r16(r16)[7:0];
            ALU_SRC_Z_SIGN_EXT: return Z_SIGN ? 'hFF : 'h00;
        endcase
    endfunction

    assign alu_a = alu_src_sel(ctrl.alu_a_src, ctrl.alu_a_r8, ctrl.alu_a_r16);
    assign alu_b = alu_src_sel(ctrl.alu_b_src, ctrl.alu_b_r8, ctrl.alu_b_r16);

    `always_mcycle begin
        case (ctrl.alu_dst)
            ALU_DST_Z: Z <= alu_result;
            ALU_DST_W: W <= alu_result;
        endcase
    end

    cpu_alu alu(
        .action(ctrl.alu_action),
        .a(alu_a),
        .b(alu_b),
        .bit_idx(ctrl.alu_bit),
        .flags_in(regfile.F),
        .z_mod(ctrl.alu_z_mod),
        .result(alu_result),
        .flags(alu_flags)
    );

    // Increment-Decrement Unit
    logic [15:0] idu_in;
    logic [15:0] idu_out;
    logic signed [1:0] idu_adj;

    function automatic logic signed [1:0] idu_adj_sel(idu_adj_t adj);
        case (adj)
            IDU_ADJ_NONE: return 'sh0;
            IDU_ADJ_INC: return 'sh1;
            IDU_ADJ_DEC: return -'sh1;
            IDU_ADJ_CARRY: begin
                logic carry_out;
                carry_out = (9'(Z) + 9'(PC[7:0])) > 9'hFF;
                return (carry_out == Z[7]) 
                    ? 2'sd0
                    : carry_out ? 2'sd1 : -2'sd1;
            end
        endcase
    endfunction

    function automatic logic [15:0] idu_src_sel(idu_src_t src);
        case (src)
            IDU_SRC_PC: return PC;
            IDU_SRC_R16: return regfile.read_r16(ctrl.idu_src_r16);
            IDU_SRC_WZ: return WZ;
            IDU_SRC_PCH: return PC[15:8];
        endcase
    endfunction

    assign idu_adj = idu_adj_sel(ctrl.idu_adj);
    assign idu_in = idu_src_sel(ctrl.idu_src);

    `always_mcycle begin
        case (ctrl.idu_dst)
            IDU_DST_PC: PC <= idu_out;
            IDU_DST_WZ: begin
                W <= idu_out[15:8];
                Z <= idu_out[7:0];
            end
            IDU_DST_W: W <= idu_out;
        endcase
    end

    cpu_idu idu(
        .in(idu_in),
        .adj(idu_adj),
        .out(idu_out)
    );

endmodule