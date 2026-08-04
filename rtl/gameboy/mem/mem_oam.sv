import mem_types::*;

module mem_oam(
    input logic clk,
    input logic rst,
    bus.child_port bus,
    oam_ppu_bus.child_port ppu_bus
);
    logic [7:0] oam [160] /*verilator public*/;

    always_comb begin
        bus.data_rd = 8'hFF;
        ppu_bus.data_rd = 16'hFFFF;

        if (bus.cs && bus.rd)
            bus.data_rd = oam[bus.addr - OAM_START];

        if (ppu_bus.cs && ppu_bus.rd)
            ppu_bus.data_rd = {oam[ppu_bus.addr + 8'd1], oam[ppu_bus.addr]};
    end

    always_ff @(posedge clk) begin
        if (bus.cs && bus.wr)
            oam[bus.addr - OAM_START] <= bus.data_wr;
    end

endmodule
