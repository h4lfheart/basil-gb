import mem_types::*;

module mem_vram(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] vram ['h2000] /*verilator public*/;

    always_comb begin
        bus.data_rd = 8'hFF;

        if (bus.cs && bus.rd)
            bus.data_rd = vram[bus.addr - VRAM_START];
    end

    
    always_ff @(posedge bus.wr) begin
        if (bus.cs)
            vram[bus.addr - VRAM_START] <= bus.data_wr;
    end

endmodule