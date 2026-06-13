module cpu_control(
    input logic [7:0] IR,
    input mcycle_t mcycle,
    output control_t ctrl
);

    task ctrl_fetch();
        ctrl.bus_rd = 1;
        ctrl.bus_rd_src = BUS_RD_SRC_PC;
        ctrl.bus_rd_dst = BUS_RD_DST_IR;

        ctrl.idu_adj = IDU_ADJ_INC;
        ctrl.idu_src = IDU_SRC_PC;
        ctrl.idu_dst = IDU_DST_PC;

        ctrl.fetch_cycle = 1;
    endtask

    always_comb begin
        ctrl = 0;

        casez(IR)
            `OP_NOP: begin
                ctrl_fetch();
            end
        endcase
    end

endmodule