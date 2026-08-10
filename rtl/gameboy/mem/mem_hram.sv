import mem_types::*;

module mem_hram(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] hram ['h80] /*verilator public*/;

    logic [6:0] hram_addr;
    assign hram_addr = bus.addr[6:0];

`ifdef VERILATOR
    always_comb begin
        bus.data_rd = 8'hFF;

        if (bus.cs && bus.rd)
            bus.data_rd = hram[hram_addr];
    end
`else
    logic [7:0] hram_q;
    always_ff @(negedge clk)
        hram_q <= hram[hram_addr];

    assign bus.data_rd = (bus.cs && bus.rd) ? hram_q : 8'hFF;
`endif

    always_ff @(posedge clk) begin
        if (bus.cs && bus.wr)
            hram[hram_addr] <= bus.data_wr;
    end

endmodule
