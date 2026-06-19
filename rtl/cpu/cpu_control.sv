module cpu_control(
    input logic [7:0] IR,
    input logic CC,
    input mcycle_t mcycle,
    input logic cb_prefix,
    input logic isr,
    input logic halted,
    input logic halt_exit,
    output control_t ctrl
);

    r16_t r16_field;
    assign r16_field = r16_t'(IR[5:4]);

    r8_t r8_dst_field;
    assign r8_dst_field = r8_t'(IR[5:3]);

    r8_t r8_src_field;
    assign r8_src_field = r8_t'(IR[2:0]);

    logic [2:0] bit_field;
    assign bit_field = IR[5:3];

    cc_t cc_field;
    assign cc_field = cc_t'(IR[4:3]);
    
    task ctrl_pc_read(bus_rd_dst_t dst);
        ctrl.bus_rd = 1;
        ctrl.bus_rd_src = BUS_RD_SRC_PC; 
        ctrl.bus_rd_dst = dst; 

        ctrl.idu_adj = IDU_ADJ_INC;
        ctrl.idu_src = IDU_SRC_PC;
        ctrl.idu_dst = IDU_DST_PC;
    endtask

    task ctrl_fetch();
        ctrl_pc_read(BUS_RD_DST_IR);

        ctrl.last_mcycle = 1;
    endtask

    task ctrl_alu_a(alu_action_t action, logic writeback);
        if (r8_src_field == R8_HL) begin
            case (mcycle)
                M0: begin
                    ctrl.bus_rd = 1;
                    ctrl.bus_rd_src = BUS_RD_SRC_R16;
                    ctrl.bus_rd_src_r16 = R16_HL;
                    ctrl.bus_rd_dst = BUS_RD_DST_Z;
                end
                M1: begin
                    ctrl_fetch();

                    ctrl.alu_action = action;
                    ctrl.alu_a_src = ALU_SRC_R8;
                    ctrl.alu_a_r8 = R8_A;
                    ctrl.alu_b_src = ALU_SRC_Z;

                    if (writeback) begin
                        ctrl.wb_src = WB_SRC_ALU;
                        ctrl.wb_dst = WB_DST_R8;
                        ctrl.wb_r8 = R8_A;
                    end
                    ctrl.wb_flags = 1;
                end
            endcase
        end
        else begin
            ctrl_fetch();

            ctrl.alu_action = action;
            ctrl.alu_a_src = ALU_SRC_R8;
            ctrl.alu_a_r8 = R8_A;
            ctrl.alu_b_src = ALU_SRC_R8;
            ctrl.alu_b_r8 = r8_src_field;

            if (writeback) begin
                ctrl.wb_src = WB_SRC_ALU;
                ctrl.wb_dst = WB_DST_R8;
                ctrl.wb_r8 = R8_A;
            end
            ctrl.wb_flags = 1;
        end
    endtask

    task ctrl_alu_a_n(alu_action_t action, logic writeback);
        case (mcycle)
            M0: begin
                ctrl_pc_read(BUS_RD_DST_Z);
            end
            M1: begin
                ctrl_fetch();

                ctrl.alu_action = action;
                ctrl.alu_a_src = ALU_SRC_R8;
                ctrl.alu_a_r8 = R8_A;
                ctrl.alu_b_src = ALU_SRC_Z;

                if (writeback) begin
                    ctrl.wb_src = WB_SRC_ALU;
                    ctrl.wb_dst = WB_DST_R8;
                    ctrl.wb_r8 = R8_A;
                end
                ctrl.wb_flags = 1;
            end
        endcase
    endtask

    task ctrl_cb_bit_op(alu_action_t action);
        if (r8_src_field == R8_HL) begin
            if (action == ALU_ACTION_BIT) begin
                case (mcycle)
                    M0: begin
                        ctrl.bus_rd = 1;
                        ctrl.bus_rd_src = BUS_RD_SRC_R16;
                        ctrl.bus_rd_src_r16 = R16_HL;
                        ctrl.bus_rd_dst = BUS_RD_DST_Z;
                    end
                    M1: begin
                        ctrl_fetch();

                        ctrl.alu_action = action;
                        ctrl.alu_a_src = ALU_SRC_Z;
                        ctrl.alu_bit = bit_field;

                        ctrl.wb_flags = 1;
                    end
                endcase
            end
            else begin
                case (mcycle)
                    M0: begin
                        ctrl.bus_rd = 1;
                        ctrl.bus_rd_src = BUS_RD_SRC_R16;
                        ctrl.bus_rd_src_r16 = R16_HL;
                        ctrl.bus_rd_dst = BUS_RD_DST_Z;
                    end
                    M1: begin
                        ctrl.alu_action = action;
                        ctrl.alu_a_src = ALU_SRC_Z;
                        ctrl.alu_bit = bit_field;

                        ctrl.bus_wr = 1;
                        ctrl.bus_wr_src = BUS_WR_SRC_ALU;
                        ctrl.bus_wr_dst = BUS_WR_DST_R16;
                        ctrl.bus_wr_dst_r16 = R16_HL;
                    end
                    M2: begin
                        ctrl_fetch();
                    end
                endcase
            end
        end
        else begin
            ctrl_fetch();

            ctrl.alu_action = action;
            ctrl.alu_a_src = ALU_SRC_R8;
            ctrl.alu_a_r8 = r8_src_field;
            ctrl.alu_bit = bit_field;

            if (action != ALU_ACTION_BIT) begin
                ctrl.wb_src = WB_SRC_ALU;
                ctrl.wb_dst = WB_DST_R8;
                ctrl.wb_r8 = r8_src_field;
            end

            if (action == ALU_ACTION_BIT)
                ctrl.wb_flags = 1;
        end
    endtask

    task ctrl_inc_dec_r(alu_action_t action);
        if (r8_dst_field == R8_HL) begin
            case (mcycle)
                M0: begin
                    ctrl.bus_rd = 1;
                    ctrl.bus_rd_src = BUS_RD_SRC_R16;
                    ctrl.bus_rd_src_r16 = R16_HL;
                    ctrl.bus_rd_dst = BUS_RD_DST_Z;
                end
                M1: begin
                    ctrl.alu_action = action;
                    ctrl.alu_a_src = ALU_SRC_Z;

                    ctrl.bus_wr = 1;
                    ctrl.bus_wr_src = BUS_WR_SRC_ALU;
                    ctrl.bus_wr_dst = BUS_WR_DST_R16;
                    ctrl.bus_wr_dst_r16 = R16_HL;

                    ctrl.wb_flags = 1;
                end
                M2: begin
                    ctrl_fetch();
                end
            endcase
        end
        else begin
            ctrl_fetch();

            ctrl.alu_action = action;
            ctrl.alu_a_src = ALU_SRC_R8;
            ctrl.alu_a_r8 = r8_dst_field;

            ctrl.wb_src = WB_SRC_ALU;
            ctrl.wb_dst = WB_DST_R8;
            ctrl.wb_r8 = r8_dst_field;
            ctrl.wb_flags = 1;
        end
    endtask

    task ctrl_inc_dec_rr(idu_adj_t adj);
        case (mcycle)
            M0: begin
                ctrl.idu_adj = adj;
                ctrl.idu_src = IDU_SRC_R16;
                ctrl.idu_src_r16 = r16_to_r16(r16_field);

                ctrl.wb_src = WB_SRC_IDU;
                ctrl.wb_dst = WB_DST_R16;
                ctrl.wb_r16 = r16_to_r16(r16_field);
            end
            M1: begin
                ctrl_fetch();
            end
        endcase
    endtask

    task ctrl_cb_alu_op(alu_action_t alu_action);
        if (r8_src_field == R8_HL) begin
            case (mcycle)
                M0: begin
                    ctrl.bus_rd = 1;
                    ctrl.bus_rd_src = BUS_RD_SRC_R16;
                    ctrl.bus_rd_src_r16 = R16_HL;
                    ctrl.bus_rd_dst = BUS_RD_DST_Z;
                end
                M1: begin
                    ctrl.alu_action = alu_action;
                    ctrl.alu_a_src = ALU_SRC_Z;

                    ctrl.bus_wr = 1;
                    ctrl.bus_wr_src = BUS_WR_SRC_ALU;
                    ctrl.bus_wr_dst = BUS_WR_DST_R16;
                    ctrl.bus_wr_dst_r16 = R16_HL;

                    ctrl.wb_flags = 1;
                end
                M2: begin
                    ctrl_fetch();
                end
            endcase
        end
        else begin
            ctrl_fetch();

            ctrl.alu_action = alu_action;
            ctrl.alu_a_src = ALU_SRC_R8;
            ctrl.alu_a_r8 = r8_src_field;

            ctrl.wb_src = WB_SRC_ALU;
            ctrl.wb_dst = WB_DST_R8;
            ctrl.wb_r8 = r8_src_field;
            ctrl.wb_flags = 1;
        end
    endtask

    task ctrl_alu_a_acc(alu_action_t action);
        ctrl_fetch();

        ctrl.alu_action = action;
        ctrl.alu_a_src = ALU_SRC_R8;
        ctrl.alu_a_r8 = R8_A;
        ctrl.alu_z_mod = ALU_Z_MOD_CLEAR;

        ctrl.wb_src = WB_SRC_ALU;
        ctrl.wb_dst = WB_DST_R8;
        ctrl.wb_r8 = R8_A;
        ctrl.wb_flags = 1;
    endtask

    always_comb begin
        ctrl = 0;

        if (isr) begin
            case (mcycle)
                M0: begin
                    ctrl.idu_adj = IDU_ADJ_DEC;
                    ctrl.idu_src = IDU_SRC_PC;
                    ctrl.idu_dst = IDU_DST_PC;

                    ctrl.ime_action = IME_ACTION_ISR;
                end
                M1: begin
                    // Decrement SP
                    ctrl.idu_adj = IDU_ADJ_DEC;
                    ctrl.idu_src = IDU_SRC_R16;
                    ctrl.idu_src_r16 = R16_SP;

                    ctrl.wb_src = WB_SRC_IDU;
                    ctrl.wb_dst = WB_DST_R16;
                    ctrl.wb_r16 = R16_SP;
                end
                M2: begin
                    ctrl.bus_wr = 1;
                    ctrl.bus_wr_src = BUS_WR_SRC_PCH;
                    ctrl.bus_wr_dst = BUS_WR_DST_R16;
                    ctrl.bus_wr_dst_r16 = R16_SP;

                    ctrl.idu_adj = IDU_ADJ_DEC;
                    ctrl.idu_src = IDU_SRC_R16;
                    ctrl.idu_src_r16 = R16_SP;

                    ctrl.wb_src = WB_SRC_IDU;
                    ctrl.wb_dst = WB_DST_R16;
                    ctrl.wb_r16 = R16_SP;

                    ctrl.isr_wb = ISR_WB_IE;
                end
                M3: begin
                    ctrl.bus_wr = 1;
                    ctrl.bus_wr_src = BUS_WR_SRC_PCL;
                    ctrl.bus_wr_dst = BUS_WR_DST_R16;
                    ctrl.bus_wr_dst_r16 = R16_SP;

                    ctrl.isr_wb = ISR_WB_IF;
                end
                M4: begin
                    ctrl.isr_ack = 1;
                    ctrl.last_mcycle = 1;
                end
            endcase
        end
        else if (!cb_prefix) begin
            casez(IR)
                `OP_NOP: begin
                    ctrl_fetch();
                end

                `OP_CALL_NN: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl_pc_read(BUS_RD_DST_W);
                        end
                        M2: begin
                            ctrl.idu_adj = IDU_ADJ_DEC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;
                            
                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M3: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_PCH;
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = R16_SP;

                            ctrl.idu_adj = IDU_ADJ_DEC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;
                            
                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M4: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_PCL;
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_PC;
                        end
                        M5: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_CALL_CC_NN: begin
                    ctrl.cc = cc_field;

                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl_pc_read(BUS_RD_DST_W);
                        end
                        M2: begin
                            if (CC) begin
                                ctrl.idu_adj = IDU_ADJ_DEC;
                                ctrl.idu_src = IDU_SRC_R16;
                                ctrl.idu_src_r16 = R16_SP;

                                ctrl.wb_src = WB_SRC_IDU;
                                ctrl.wb_dst = WB_DST_R16;
                                ctrl.wb_r16 = R16_SP;
                            end
                            else begin
                                ctrl_fetch();
                            end
                        end
                        M3: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_PCH;
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = R16_SP;

                            ctrl.idu_adj = IDU_ADJ_DEC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M4: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_PCL;
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_PC;
                        end
                        M5: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_JR_E: begin
                    case (mcycle)
                        M0: begin    
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl.alu_action = ALU_ACTION_ADD;
                            ctrl.alu_a_src = ALU_SRC_PCL;
                            ctrl.alu_b_src = ALU_SRC_Z;
                            ctrl.alu_dst = ALU_DST_Z;
                            ctrl.wb_flags = 0;

                            ctrl.idu_adj = IDU_ADJ_CARRY;
                            ctrl.idu_src = IDU_SRC_PCH;
                            ctrl.idu_dst = IDU_DST_W;
                        end
                        M2: begin
                            ctrl.last_mcycle = 1;

                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_WZ;
                            ctrl.bus_rd_dst = BUS_RD_DST_IR;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_WZ;
                            ctrl.idu_dst = IDU_DST_PC;
                        end
                    endcase
                end

                `OP_JR_CC_E: begin
                    ctrl.cc = cc_field;

                    case (mcycle)
                        M0: begin    
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            if (CC) begin
                                ctrl.alu_action = ALU_ACTION_ADD;
                                ctrl.alu_a_src = ALU_SRC_PCL;
                                ctrl.alu_b_src = ALU_SRC_Z;
                                ctrl.alu_dst = ALU_DST_Z;
                                ctrl.wb_flags = 0;

                                ctrl.idu_adj = IDU_ADJ_CARRY;
                                ctrl.idu_src = IDU_SRC_PCH;
                                ctrl.idu_dst = IDU_DST_W;

                            end
                            else begin
                                ctrl_fetch();
                            end
                        end
                        M2: begin
                            ctrl.last_mcycle = 1;

                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_WZ;
                            ctrl.bus_rd_dst = BUS_RD_DST_IR;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_WZ;
                            ctrl.idu_dst = IDU_DST_PC;
                        end
                    endcase
                end

                `OP_JP_NN: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl_pc_read(BUS_RD_DST_W);
                        end
                        M2: begin
                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_PC;
                        end
                        M3: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_JP_CC_NN: begin
                    ctrl.cc = cc_field;

                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl_pc_read(BUS_RD_DST_W);
                        end
                        M2: begin
                            if (CC) begin
                                ctrl.wb_src = WB_SRC_WZ;
                                ctrl.wb_dst = WB_DST_PC;
                            end
                            else begin
                                ctrl_fetch();
                            end
                        end
                        M3: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_JP_HL: begin
                    ctrl.last_mcycle = 1;

                    ctrl.bus_rd = 1;
                    ctrl.bus_rd_src = BUS_RD_SRC_R16;
                    ctrl.bus_rd_src_r16 = R16_HL;
                    ctrl.bus_rd_dst = BUS_RD_DST_IR;

                    ctrl.idu_adj = IDU_ADJ_INC;
                    ctrl.idu_src = IDU_SRC_R16;
                    ctrl.idu_src_r16 = R16_HL;
                    ctrl.idu_dst = IDU_DST_PC;
                end

                `OP_RST: begin
                    ctrl.rst = IR[5:3];

                    case (mcycle)
                        M0: begin
                            ctrl.idu_adj = IDU_ADJ_DEC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M1: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_PCH;
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = R16_SP;

                            ctrl.idu_adj = IDU_ADJ_DEC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M2: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_PCL;
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_RST;
                            ctrl.wb_dst = WB_DST_PC;
                        end
                        M3: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_INC_RR: begin
                    ctrl_inc_dec_rr(IDU_ADJ_INC);
                end

                `OP_DEC_RR: begin
                    ctrl_inc_dec_rr(IDU_ADJ_DEC);
                end

                `OP_INC_R: begin
                    ctrl_inc_dec_r(ALU_ACTION_INC);
                end

                `OP_DEC_R: begin
                    ctrl_inc_dec_r(ALU_ACTION_DEC);
                end

                `OP_HALT: begin
                    if (!halted)
                        ctrl.halt = 1;
                    else if (halt_exit) begin
                        ctrl_fetch();
                    end
                end

                `OP_LD_R_R: begin
                    if (r8_dst_field == R8_HL) begin
                        // LD (HL), r
                        case (mcycle)
                            M0: begin
                                ctrl.bus_wr = 1;
                                ctrl.bus_wr_src = BUS_WR_SRC_R8;
                                ctrl.bus_wr_src_r8 = r8_src_field;
                                ctrl.bus_wr_dst = BUS_WR_DST_R16;
                                ctrl.bus_wr_dst_r16 = R16_HL;
                            end
                            M1: begin
                                ctrl_fetch();
                            end
                        endcase
                    end
                    else if (r8_src_field == R8_HL) begin
                        // LD r, (HL)
                        case (mcycle)
                            M0: begin
                                ctrl.bus_rd = 1;
                                ctrl.bus_rd_src = BUS_RD_SRC_R16;
                                ctrl.bus_rd_src_r16 = R16_HL;
                                ctrl.bus_rd_dst = BUS_RD_DST_Z;
                            end
                            M1: begin
                                ctrl_fetch();

                                ctrl.alu_action = ALU_ACTION_LD;
                                ctrl.alu_a_src = ALU_SRC_Z;

                                ctrl.wb_src = WB_SRC_ALU;
                                ctrl.wb_dst = WB_DST_R8;
                                ctrl.wb_r8 = r8_dst_field;
                            end
                        endcase
                    end
                    else begin
                        // LD r, r'
                        ctrl_fetch();

                        ctrl.alu_action = ALU_ACTION_LD;
                        ctrl.alu_a_src = ALU_SRC_R8;
                        ctrl.alu_a_r8 = r8_src_field;

                        ctrl.wb_src = WB_SRC_ALU;
                        ctrl.wb_dst = WB_DST_R8;
                        ctrl.wb_r8 = r8_dst_field;
                    end
                end

                `OP_LD_R_N: begin
                    if (r8_dst_field == R8_HL) begin
                        case (mcycle)
                            M0: begin
                                ctrl_pc_read(BUS_RD_DST_Z);
                            end
                            M1: begin
                                ctrl.bus_wr = 1;
                                ctrl.bus_wr_src = BUS_WR_SRC_Z;
                                ctrl.bus_wr_dst = BUS_WR_DST_R16;
                                ctrl.bus_wr_dst_r16 = R16_HL;
                            end
                            M2: begin
                                ctrl_fetch();
                            end
                        endcase
                    end
                    else begin
                        case (mcycle)
                            M0: begin    
                                ctrl_pc_read(BUS_RD_DST_Z);
                            end
                            M1: begin
                                ctrl_fetch();
                                ctrl.alu_action = ALU_ACTION_LD;
                                ctrl.alu_a_src = ALU_SRC_Z;
                                
                                ctrl.wb_src = WB_SRC_ALU;
                                ctrl.wb_dst = WB_DST_R8;
                                ctrl.wb_r8 = r8_dst_field;
                            end
                        endcase
                    end
                end

                `OP_LD_RR_NN: begin
                    case (mcycle)
                        M0: begin    
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl_pc_read(BUS_RD_DST_W);
                        end
                        M2: begin
                            ctrl_fetch();

                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = r16_to_r16(r16_field);
                        end
                    endcase
                end

                `OP_LD_RR_MEM_A: begin
                    case (mcycle)
                        M0: begin
                            r16mem_t r16mem = r16mem_t'(r16_field);

                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_R8;
                            ctrl.bus_wr_src_r8 = R8_A;
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = r16mem_to_r16(r16_field);

                            if (r16mem == R16MEM_HLI || r16mem == R16MEM_HLD) begin
                                ctrl.idu_adj = r16mem == R16MEM_HLI ? IDU_ADJ_INC : IDU_ADJ_DEC;
                                ctrl.idu_src = IDU_SRC_R16;
                                ctrl.idu_src_r16 = r16mem_to_r16(r16_field);

                                ctrl.wb_src = WB_SRC_IDU;
                                ctrl.wb_dst = WB_DST_R16;
                                ctrl.wb_r16 = r16mem_to_r16(r16_field);
                            end
                            
                        end
                        M1: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_LD_A_RR_MEM: begin
                    case (mcycle)
                        M0: begin
                            r16mem_t r16mem = r16mem_t'(r16_field);

                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_R16;
                            ctrl.bus_rd_src_r16 = r16mem_to_r16(r16_field);
                            ctrl.bus_rd_dst = BUS_RD_DST_Z;

                            if (r16mem == R16MEM_HLI || r16mem == R16MEM_HLD) begin
                                ctrl.idu_adj = r16mem == R16MEM_HLI ? IDU_ADJ_INC : IDU_ADJ_DEC;
                                ctrl.idu_src = IDU_SRC_R16;
                                ctrl.idu_src_r16 = r16mem_to_r16(r16_field);

                                ctrl.wb_src = WB_SRC_IDU;
                                ctrl.wb_dst = WB_DST_R16;
                                ctrl.wb_r16 = r16mem_to_r16(r16_field);
                            end
                        end
                        M1: begin
                            ctrl_fetch();

                            ctrl.alu_action = ALU_ACTION_LD;
                            ctrl.alu_a_src = ALU_SRC_Z;

                            ctrl.wb_src = WB_SRC_ALU;
                            ctrl.wb_dst = WB_DST_R8;
                            ctrl.wb_r8 = R8_A;
                        end
                    endcase
                end

                `OP_LD_NN_A: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl_pc_read(BUS_RD_DST_W);
                        end
                        M2: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_R8;
                            ctrl.bus_wr_src_r8 = R8_A;
                            ctrl.bus_wr_dst = BUS_WR_DST_WZ;
                        end
                        M3: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_LD_NN_SP: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl_pc_read(BUS_RD_DST_W);
                        end
                        M2: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_R16L;
                            ctrl.bus_wr_src_r16 = R16_SP;
                            ctrl.bus_wr_dst = BUS_WR_DST_WZ;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_WZ;
                            ctrl.idu_dst = IDU_DST_WZ;
                        end
                        M3: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_R16H;
                            ctrl.bus_wr_src_r16 = R16_SP;
                            ctrl.bus_wr_dst = BUS_WR_DST_WZ;
                        end
                        M4: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_LD_A_NN: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl_pc_read(BUS_RD_DST_W);
                        end
                        M2: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_WZ;
                            ctrl.bus_rd_dst = BUS_RD_DST_Z;
                        end
                        M3: begin
                            ctrl_fetch();

                            ctrl.alu_action = ALU_ACTION_LD;
                            ctrl.alu_a_src = ALU_SRC_Z;

                            ctrl.wb_src = WB_SRC_ALU;
                            ctrl.wb_dst = WB_DST_R8;
                            ctrl.wb_r8 = R8_A;
                        end
                    endcase
                end

                `OP_LD_SP_HL: begin
                    case (mcycle)
                        M0: begin
                            ctrl.idu_adj = IDU_ADJ_NONE;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_HL;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;

                        end
                        M1: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_ADD_SP_E: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl.alu_action = ALU_ACTION_ADD;
                            ctrl.alu_a_src = ALU_SRC_R16L;
                            ctrl.alu_a_r16 = R16_SP;
                            ctrl.alu_b_src = ALU_SRC_Z;
                            ctrl.alu_dst = ALU_DST_Z;
                            ctrl.wb_flags = 1;
                            ctrl.alu_z_mod = ALU_Z_MOD_CLEAR;
                            ctrl.z_sign = 1;
                        end
                        M2: begin
                            ctrl.alu_action = ALU_ACTION_ADC;
                            ctrl.alu_a_src = ALU_SRC_R16H;
                            ctrl.alu_a_r16 = R16_SP;
                            ctrl.alu_b_src = ALU_SRC_Z_SIGN_EXT;
                            ctrl.alu_dst = ALU_DST_W;
                            ctrl.alu_z_mod = ALU_Z_MOD_PRESERVE;
                        end
                        M3: begin
                            ctrl_fetch();

                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                    endcase
                end

                `OP_LD_HL_SP_E: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl.alu_action = ALU_ACTION_ADD;
                            ctrl.alu_a_src = ALU_SRC_R16L;
                            ctrl.alu_a_r16 = R16_SP;
                            ctrl.alu_b_src = ALU_SRC_Z;

                            ctrl.wb_src = WB_SRC_ALU;
                            ctrl.wb_dst = WB_DST_R8;
                            ctrl.wb_r8 = R8_L;
                            ctrl.wb_flags = 1;
                            ctrl.alu_z_mod = ALU_Z_MOD_CLEAR;

                            ctrl.z_sign = 1;
                        end
                        M2: begin
                            ctrl_fetch();

                            ctrl.alu_action = ALU_ACTION_ADC;
                            ctrl.alu_a_src = ALU_SRC_R16H;
                            ctrl.alu_a_r16 = R16_SP;
                            ctrl.alu_b_src = ALU_SRC_Z_SIGN_EXT;

                            ctrl.wb_src = WB_SRC_ALU;
                            ctrl.wb_dst = WB_DST_R8;
                            ctrl.wb_r8 = R8_H;
                            ctrl.alu_z_mod = ALU_Z_MOD_PRESERVE;
                        end
                    endcase
                end

                `OP_RLCA: begin
                    ctrl_alu_a_acc(ALU_ACTION_RLC);
                end

                `OP_RRCA: begin
                    ctrl_alu_a_acc(ALU_ACTION_RRC);
                end

                `OP_RLA: begin
                    ctrl_alu_a_acc(ALU_ACTION_RL);
                end

                `OP_RRA: begin
                    ctrl_alu_a_acc(ALU_ACTION_RR);
                end

                `OP_ADD_R: begin
                    ctrl_alu_a(ALU_ACTION_ADD, 1);
                end

                `OP_XOR_R: begin
                    ctrl_alu_a(ALU_ACTION_XOR, 1);
                end

                `OP_AND_R: begin
                    ctrl_alu_a(ALU_ACTION_AND, 1);
                end

                `OP_OR_R: begin
                    ctrl_alu_a(ALU_ACTION_OR, 1);
                end

                `OP_SUB_R: begin
                    ctrl_alu_a(ALU_ACTION_SUB, 1);
                end

                `OP_CP_R: begin
                    ctrl_alu_a(ALU_ACTION_SUB, 0);
                end

                `OP_ADC_R: begin
                    ctrl_alu_a(ALU_ACTION_ADC, 1);
                end

                `OP_SBC_R: begin
                    ctrl_alu_a(ALU_ACTION_SBC, 1);
                end

                `OP_ADC_N: begin
                    ctrl_alu_a_n(ALU_ACTION_ADC, 1);
                end

                `OP_SUB_N: begin
                    ctrl_alu_a_n(ALU_ACTION_SUB, 1);
                end

                `OP_SBC_N: begin
                    ctrl_alu_a_n(ALU_ACTION_SBC, 1);
                end

                `OP_XOR_N: begin
                    ctrl_alu_a_n(ALU_ACTION_XOR, 1);
                end

                `OP_OR_N: begin
                    ctrl_alu_a_n(ALU_ACTION_OR, 1);
                end

                `OP_ADD_N: begin
                    ctrl_alu_a_n(ALU_ACTION_ADD, 1);
                end

                `OP_AND_N: begin
                    ctrl_alu_a_n(ALU_ACTION_AND, 1);
                end

                `OP_CP_N: begin
                    ctrl_alu_a_n(ALU_ACTION_SUB, 0);
                end

                `OP_CPL: begin
                    ctrl_fetch();

                    ctrl.alu_action = ALU_ACTION_CPL;
                    ctrl.alu_a_src = ALU_SRC_R8;
                    ctrl.alu_a_r8 = R8_A;

                    ctrl.wb_src = WB_SRC_ALU;
                    ctrl.wb_dst = WB_DST_R8;
                    ctrl.wb_r8 = R8_A;
                    ctrl.wb_flags = 1;
                end

                `OP_CCF: begin
                    ctrl_fetch();

                    ctrl.alu_action = ALU_ACTION_CCF;
                    ctrl.wb_flags = 1;
                end

                `OP_SCF: begin
                    ctrl_fetch();

                    ctrl.alu_action = ALU_ACTION_SCF;
                    ctrl.wb_flags = 1;
                end

                `OP_DAA: begin
                    ctrl_fetch();

                    ctrl.alu_action = ALU_ACTION_DAA;
                    ctrl.alu_a_src = ALU_SRC_R8;
                    ctrl.alu_a_r8 = R8_A;

                    ctrl.wb_src = WB_SRC_ALU;
                    ctrl.wb_dst = WB_DST_R8;
                    ctrl.wb_r8 = R8_A;
                    ctrl.wb_flags = 1;
                end

                `OP_RET: begin
                    case (mcycle)
                        M0: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_R16;
                            ctrl.bus_rd_src_r16 = R16_SP;
                            ctrl.bus_rd_dst = BUS_RD_DST_Z;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M1: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_R16;
                            ctrl.bus_rd_src_r16 = R16_SP;
                            ctrl.bus_rd_dst = BUS_RD_DST_W;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M2: begin
                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_PC;
                        end
                        M3: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_RETI: begin
                    case (mcycle)
                        M0: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_R16;
                            ctrl.bus_rd_src_r16 = R16_SP;
                            ctrl.bus_rd_dst = BUS_RD_DST_Z;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M1: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_R16;
                            ctrl.bus_rd_src_r16 = R16_SP;
                            ctrl.bus_rd_dst = BUS_RD_DST_W;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M2: begin
                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_PC;
                            ctrl.ime_action = IME_ACTION_RETI;
                        end
                        M3: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_RET_CC: begin
                    ctrl.cc = cc_field;

                    case (mcycle)
                        M0: begin
                            // cc check
                        end
                        M1: begin
                            if (CC) begin
                                ctrl.bus_rd = 1;
                                ctrl.bus_rd_src = BUS_RD_SRC_R16;
                                ctrl.bus_rd_src_r16 = R16_SP;
                                ctrl.bus_rd_dst = BUS_RD_DST_Z;

                                ctrl.idu_adj = IDU_ADJ_INC;
                                ctrl.idu_src = IDU_SRC_R16;
                                ctrl.idu_src_r16 = R16_SP;

                                ctrl.wb_src = WB_SRC_IDU;
                                ctrl.wb_dst = WB_DST_R16;
                                ctrl.wb_r16 = R16_SP;
                            end
                            else begin
                                ctrl_fetch();
                            end
                        end
                        M2: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_R16;
                            ctrl.bus_rd_src_r16 = R16_SP;
                            ctrl.bus_rd_dst = BUS_RD_DST_W;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M3: begin
                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_PC;
                        end
                        M4: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_PUSH_RR: begin
                    case (mcycle)
                        M0: begin
                            ctrl.idu_adj = IDU_ADJ_DEC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M1: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_R16H;
                            ctrl.bus_wr_src_r16 = r16stk_to_r16(r16_field);
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = R16_SP;

                            ctrl.idu_adj = IDU_ADJ_DEC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M2: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_R16L;
                            ctrl.bus_wr_src_r16 = r16stk_to_r16(r16_field);
                            ctrl.bus_wr_dst = BUS_WR_DST_R16;
                            ctrl.bus_wr_dst_r16 = R16_SP;
                        end
                        M3: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_POP_RR: begin
                    case (mcycle)
                        M0: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_R16;
                            ctrl.bus_rd_src_r16 = R16_SP;
                            ctrl.bus_rd_dst = BUS_RD_DST_Z;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M1: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_R16;
                            ctrl.bus_rd_src_r16 = R16_SP;
                            ctrl.bus_rd_dst = BUS_RD_DST_W;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_R16;
                            ctrl.idu_src_r16 = R16_SP;

                            ctrl.wb_src = WB_SRC_IDU;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = R16_SP;
                        end
                        M2: begin
                            ctrl_fetch();

                            ctrl.wb_src = WB_SRC_WZ;
                            ctrl.wb_dst = WB_DST_R16;
                            ctrl.wb_r16 = r16stk_to_r16(r16_field);
                        end
                    endcase
                end

                `OP_CB: begin
                    ctrl_fetch();
                    ctrl.set_cb_prefix = 1;
                end

                `OP_LDH_N_A: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl.bus_wr = 1;
                            ctrl.bus_wr_src = BUS_WR_SRC_R8;
                            ctrl.bus_wr_src_r8 = R8_A;
                            ctrl.bus_wr_dst = BUS_WR_DST_Z;
                        end
                        M2: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_LDH_C_A: begin
                    case (mcycle)
                        M0: begin
                           ctrl.bus_wr = 1;
                           ctrl.bus_wr_src = BUS_WR_SRC_R8;
                           ctrl.bus_wr_src_r8 = R8_A;
                           ctrl.bus_wr_dst = BUS_WR_DST_C;
                        end
                        M1: begin
                            ctrl_fetch();
                        end
                    endcase
                end

                `OP_LDH_A_N: begin
                    case (mcycle)
                        M0: begin
                            ctrl_pc_read(BUS_RD_DST_Z);
                        end
                        M1: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_Z;
                            ctrl.bus_rd_dst = BUS_RD_DST_Z;
                        end
                        M2: begin
                            ctrl_fetch();

                            ctrl.alu_action = ALU_ACTION_LD;
                            ctrl.alu_a_src = ALU_SRC_Z;

                            ctrl.wb_src = WB_SRC_ALU;
                            ctrl.wb_dst = WB_DST_R8;
                            ctrl.wb_r8 = R8_A;
                        end
                    endcase
                end

                `OP_LDH_A_C: begin
                    case (mcycle)
                        M0: begin
                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_C;
                            ctrl.bus_rd_dst = BUS_RD_DST_Z;
                        end
                        M1: begin
                            ctrl_fetch();

                            ctrl.alu_action = ALU_ACTION_LD;
                            ctrl.alu_a_src = ALU_SRC_Z;

                            ctrl.wb_src = WB_SRC_ALU;
                            ctrl.wb_dst = WB_DST_R8;
                            ctrl.wb_r8 = R8_A;
                        end
                    endcase
                end
                
                `OP_ADD_HL_RR: begin
                    case (mcycle)
                        M0: begin
                            ctrl.alu_action = ALU_ACTION_ADD;
                            ctrl.alu_a_src = ALU_SRC_R8;
                            ctrl.alu_a_r8 = R8_L;
                            ctrl.alu_b_src = ALU_SRC_R16L;
                            ctrl.alu_b_r16 = r16_to_r16(r16_field);

                            ctrl.wb_src = WB_SRC_ALU;
                            ctrl.wb_dst = WB_DST_R8;
                            ctrl.wb_r8 = R8_L;
                            ctrl.wb_flags = 1;
                            ctrl.alu_z_mod = ALU_Z_MOD_PRESERVE;
                        end
                        M1: begin
                            ctrl_fetch();

                            ctrl.alu_action = ALU_ACTION_ADC;
                            ctrl.alu_a_src = ALU_SRC_R8;
                            ctrl.alu_a_r8 = R8_H;
                            ctrl.alu_b_src = ALU_SRC_R16H;
                            ctrl.alu_b_r16 = r16_to_r16(r16_field);

                            ctrl.wb_src = WB_SRC_ALU;
                            ctrl.wb_dst = WB_DST_R8;
                            ctrl.wb_r8 = R8_H;
                            ctrl.wb_flags = 1;
                            ctrl.alu_z_mod = ALU_Z_MOD_PRESERVE;
                        end
                    endcase
                end

                `OP_DI: begin
                    ctrl_fetch();
                    ctrl.ime_action = IME_ACTION_DI;
                end

                `OP_EI: begin
                    ctrl_fetch();
                    ctrl.ime_action = IME_ACTION_EI;
                end

                default: begin
                    $display("Unsupported Instruction: 0x%0h", IR);
                    $finish;
                end

            endcase
        end
        else begin
            casez(IR)
                `OP_CB_RLC: begin
                    ctrl_cb_alu_op(ALU_ACTION_RLC);
                end

                `OP_CB_RRC: begin
                    ctrl_cb_alu_op(ALU_ACTION_RRC);
                end

                `OP_CB_RL: begin
                    ctrl_cb_alu_op(ALU_ACTION_RL);
                end

                `OP_CB_RR: begin
                    ctrl_cb_alu_op(ALU_ACTION_RR);
                end

                `OP_CB_SLA: begin
                    ctrl_cb_alu_op(ALU_ACTION_SLA);
                end

                `OP_CB_SRA: begin
                    ctrl_cb_alu_op(ALU_ACTION_SRA);
                end

                `OP_CB_SWAP: begin
                    ctrl_cb_alu_op(ALU_ACTION_SWAP);
                end

                `OP_CB_SRL: begin
                    ctrl_cb_alu_op(ALU_ACTION_SRL);
                end

                `OP_CB_BIT: begin
                    ctrl_cb_bit_op(ALU_ACTION_BIT);
                end

                `OP_CB_RES: begin
                    ctrl_cb_bit_op(ALU_ACTION_RES);
                end

                `OP_CB_SET: begin
                    ctrl_cb_bit_op(ALU_ACTION_SET);
                end

                default: begin
                    $display("Unsupported Instruction: 0xcb%0h", IR);
                    $finish;
                end

            endcase
        end
    end

endmodule