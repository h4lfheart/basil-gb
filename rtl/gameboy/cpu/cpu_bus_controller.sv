module cpu_bus_controller(
    input logic clk,
    input tcycle_t tcycle,
    input logic rd,
    input logic wr,
    input logic [15:0] addr,
    input logic [7:0] data_wr,
    output logic [7:0] data_rd,

    bus.parent_port bus
);
    always_ff @(posedge clk) begin
        if (rd) begin
            case (tcycle)
                T0: begin
                    bus.addr <= addr;
                    bus.rd <= 1;
                    bus.wr <= 0;
                end
                T1: begin
                    data_rd <= bus.data_rd;
                end
                T2: begin
                    // idle
                end
                T3: begin
                    bus.rd <= 0;
                end
            endcase
        end
        else if (wr) begin
            case (tcycle)
                T0: begin
                    bus.addr <= addr;
                    bus.rd <= 0;
                end
                T1: begin
                    bus.wr <= 1;
                    bus.data_wr <= data_wr;
                end
                T2: begin
                    bus.wr <= 0;
                end
                T3: begin
                    // idle
                end
            endcase
        end
    end

endmodule