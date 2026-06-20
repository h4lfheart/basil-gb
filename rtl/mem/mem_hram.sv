import mem_types::*;

module mem_hram(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] hram ['h80] /*verilator public*/;

    always_comb begin
        bus.data_rd = 8'hFF;

        if (bus.cs && bus.rd)
            bus.data_rd = hram[bus.addr - HRAM_START];
    end

    always_ff @(posedge bus.wr) begin
        if (bus.cs)
            hram[bus.addr - HRAM_START] <= bus.data_wr;
    end

endmodule