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

    // Registers
    logic [15:0] DIV;
    logic [7:0] TIMA;
    logic [7:0] TMA;
    tac_t TAC;

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

    always_ff @(posedge bus.wr) begin
        if (bus.cs)
            case (bus.addr)
                REG_DIV: DIV <= 'h0000;
                REG_TIMA: TIMA <= bus.data_wr;
                REG_TMA: TMA <= bus.data_wr;
                REG_TAC: TAC <= tac_t'(bus.data_wr[2:0]);
            endcase
    end

    // Logic
    
    function automatic logic tima_bit_sel();
        case (TAC.clock_select)
            'b00: return DIV[9];
            'b01: return DIV[3];
            'b10: return DIV[5];
            'b11: return DIV[7];
        endcase
    endfunction

    logic tima_bit;
    assign tima_bit = tima_bit_sel();

    logic tima_falling;
    edge_detect tima_edge(
        .clk,
        .rst,
        .signal(tima_bit),
        .falling(tima_falling)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            DIV <= 0;
            TIMA <= 0;
            TMA <= 0;
            TAC <= 0;
            interrupt <= 0;
        end
        else begin
            interrupt <= 0;
            DIV <= DIV + 1;

            if (TAC.enable && tima_falling) begin
                if (TIMA == 'hFF) begin
                    TIMA <= TMA;
                    interrupt <= 1;
                end else
                    TIMA <= TIMA + 1;
            end
        end
    end


endmodule

