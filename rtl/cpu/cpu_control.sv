module cpu_control(
    input logic [7:0] IR,
    input mcycle_t mcycle,
    output control_t ctrl
);

    logic [1:0] r16_field;
    assign r16_field = IR[5:4];

    logic [2:0] r8_dst_field;
    assign r8_dst_field = IR[5:3];

    logic [2:0] r8_src_field;
    assign r8_dst_field = IR[2:0];
    
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
        ctrl.alu_b_r8 = r8_t'(r8_src_field);

        ctrl.wb_src = WB_SRC_ALU;
        ctrl.wb_dst = WB_DST_R8;
        ctrl.wb_r8 = R8_A;
        ctrl.wb_flags = 1;
    endtask



    always_comb begin
        ctrl = 0;

        casez(IR)
            `OP_NOP: begin
                ctrl_fetch();
            end

            
            `OP_XOR_R: begin
                ctrl_alu_a(ALU_ACTION_XOR);
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

            default: begin
                $display("Unsupported Instruction: 0x%0h", IR);
                $finish;
            end

        endcase
    end

endmodule