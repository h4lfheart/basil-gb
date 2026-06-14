module cpu_control(
    input logic [7:0] IR,
    input logic CC,
    input mcycle_t mcycle,
    input logic cb_prefix,
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

        ctrl.fetch_cycle = 1;
    endtask

    task ctrl_alu_a(alu_action_t action);
        ctrl_fetch();

        ctrl.alu_action = ALU_ACTION_XOR;
        ctrl.alu_a_src = ALU_SRC_R8;
        ctrl.alu_a_r8 = R8_A;
        ctrl.alu_b_src = ALU_SRC_R8;
        ctrl.alu_b_r8 = r8_src_field;

        ctrl.wb_src = WB_SRC_ALU;
        ctrl.wb_dst = WB_DST_R8;
        ctrl.wb_r8 = R8_A;
        ctrl.wb_flags = 1;
    endtask

    task ctrl_cb_bit_op(alu_action_t action);
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
    endtask

    always_comb begin
        ctrl = 0;

        if (!cb_prefix) begin
            casez(IR)
                `OP_NOP: begin
                    ctrl_fetch();
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
                            ctrl.fetch_cycle = 1;

                            ctrl.bus_rd = 1;
                            ctrl.bus_rd_src = BUS_RD_SRC_WZ;
                            ctrl.bus_rd_dst = BUS_RD_DST_IR;

                            ctrl.idu_adj = IDU_ADJ_INC;
                            ctrl.idu_src = IDU_SRC_WZ;
                            ctrl.idu_dst = IDU_DST_PC;
                        end
                    endcase
                end

                `OP_INC_R: begin
                    ctrl_fetch();

                    ctrl.alu_action = ALU_ACTION_INC;
                    ctrl.alu_a_src = ALU_SRC_R8;
                    ctrl.alu_a_r8 = r8_dst_field;

                    ctrl.wb_src = WB_SRC_ALU;
                    ctrl.wb_dst = WB_DST_R8;
                    ctrl.wb_r8 = r8_dst_field;
                    ctrl.wb_flags = 1;
                end

                `OP_HALT: begin
                    $finish("Unimplemented HALT instruction.");
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
                
                `OP_XOR_R: begin
                    ctrl_alu_a(ALU_ACTION_XOR);
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

                default: begin
                    $display("Unsupported Instruction: 0x%0h", IR);
                    $finish;
                end

            endcase
        end
        else begin
            casez(IR)
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