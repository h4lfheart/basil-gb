import mem_types::*;

module serial(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    import "DPI-C" function void serial_putchar(byte unsigned c);

    logic [7:0] SB;
    logic [7:0] SC;

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd) begin
            case (bus.addr)
                REG_SB: bus.data_rd = SB;
                REG_SC: bus.data_rd = SC;
            endcase
        end
    end

    logic wr_prev;
    always_ff @(posedge clk or posedge rst) begin
        wr_prev <= bus.cs && bus.wr;

        if (bus.cs && bus.wr) begin
            case (bus.addr)
                REG_SB: begin
                    SB <= bus.data_wr;
                    if (bus.wr != wr_prev)
                        serial_putchar(bus.data_wr);
                end
                REG_SC: SC <= bus.data_wr;
            endcase
        end
    end

endmodule