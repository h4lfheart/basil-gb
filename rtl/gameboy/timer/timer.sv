import mem_types::*;

typedef struct packed {
    logic enable;
    logic [1:0] clock_select;
} tac_t;

module timer(
    input logic clk,
    input logic rst,
    bus.child_port bus,
    output logic interrupt
);

    logic [15:0] DIV;
    logic [7:0] TIMA;
    logic [7:0] TMA;
    tac_t TAC;

    logic div_write;
    logic tima_write;
    logic tma_write;
    logic tac_write;

    assign div_write = bus.cs && bus.wr && bus.addr == REG_DIV;
    assign tima_write = bus.cs && bus.wr && bus.addr == REG_TIMA;
    assign tma_write = bus.cs && bus.wr && bus.addr == REG_TMA;
    assign tac_write = bus.cs && bus.wr && bus.addr == REG_TAC;

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd)
            case (bus.addr)
                REG_DIV: bus.data_rd = DIV[15:8];
                REG_TIMA: bus.data_rd = TIMA;
                REG_TMA: bus.data_rd = TMA;
                REG_TAC: bus.data_rd = {5'd0, TAC};
            endcase
    end

    function automatic logic sel_bit(input logic [15:0] d, input logic [1:0] cs);
        case (cs)
            'b00: return d[9];
            'b01: return d[3];
            'b10: return d[5];
            'b11: return d[7];
        endcase
    endfunction

    logic [15:0] div_next;
    assign div_next = div_write ? 16'd2 : DIV + 16'd1;

    tac_t tac_next;
    assign tac_next = tac_write ? tac_t'(bus.data_wr[2:0]) : TAC;

    logic timer_input;
    logic timer_input_next;
    assign timer_input = sel_bit(DIV, TAC.clock_select) && TAC.enable;
    assign timer_input_next = tac_write
        ? sel_bit(DIV - 16'd2, tac_next.clock_select) && tac_next.enable
        : sel_bit(div_next, TAC.clock_select) && TAC.enable;

    logic tima_falling;
    assign tima_falling = tac_write
        ? sel_bit(DIV - 16'd2, TAC.clock_select) && TAC.enable && !timer_input_next
        : timer_input && !timer_input_next;

    logic reload_pending;
    logic [1:0] reload_delay;
    logic [1:0] reload_write_phase;
    assign interrupt = reload_pending && reload_delay == 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            DIV <= '0;
            TIMA <= '0;
            TMA <= '0;
            TAC <= '0;
            reload_pending <= 0;
            reload_delay <= 0;
            reload_write_phase <= 0;
        end else begin
            DIV <= div_next;

            if (reload_write_phase != 0)
                reload_write_phase <= reload_write_phase - 'd1;

            if (tma_write)
                TMA <= bus.data_wr;

            if (tac_write)
                TAC <= tac_next;

            if (reload_pending) begin
                if (reload_delay == 0) begin
                    TIMA <= tma_write ? bus.data_wr : TMA;
                    reload_pending <= 0;
                    reload_write_phase <= 'd2;
                end else
                    reload_delay <= reload_delay - 'd1;
            end

            if (tima_write) begin
                if (reload_write_phase != 1) begin
                    TIMA <= bus.data_wr;
                    reload_pending <= 0;
                end
            end else if (tima_falling) begin
                if (TIMA == 'hFF) begin
                    TIMA <= 'd0;
                    reload_pending <= 1;
                    reload_delay <= 'd3;
                end else
                    TIMA <= TIMA + 'd1;
            end

            if (tma_write && reload_write_phase == 1)
                TIMA <= bus.data_wr;
        end
    end

endmodule
