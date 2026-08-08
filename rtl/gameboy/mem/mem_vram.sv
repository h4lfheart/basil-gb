module mem_vram(
    input logic clk,
    input logic rst,
    input logic cpu_bank,
    bus.child_port bus,
    vram_ppu_bus.child_port ppu_bus
);
    logic [7:0] vram [2]['h2000] /*verilator public*/;

    always_comb begin
        bus.data_rd = 'hFF;
        ppu_bus.bank0_data = 'hFF;
        ppu_bus.bank1_data = 'hFF;

        if (bus.cs && bus.rd)
            bus.data_rd = vram[cpu_bank][bus.addr[12:0]];

        if (ppu_bus.cs && ppu_bus.rd) begin
            ppu_bus.bank0_data = vram[0][ppu_bus.addr[12:0]];
            ppu_bus.bank1_data = vram[1][ppu_bus.addr[12:0]];
        end
    end

    always_ff @(posedge clk) begin
        if (bus.cs && bus.wr)
            vram[cpu_bank][bus.addr[12:0]] <= bus.data_wr;
    end

endmodule
