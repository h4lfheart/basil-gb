module mem_vram(
    input logic clk,
    input logic rst,
    input logic cpu_bank,
    bus.child_port bus,
    vram_ppu_bus.child_port ppu_bus
);
`ifdef VERILATOR
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
`else
    logic [7:0] vram0 ['h2000] /* synthesis syn_ramstyle = "block_ram" */;
    logic [7:0] vram1 ['h2000] /* synthesis syn_ramstyle = "block_ram" */;

    logic ppu_active;
    logic [12:0] rd_addr;
    logic [7:0] q0;
    logic [7:0] q1;
    logic cpu_bank_q;
    logic blocked_q;

    assign ppu_active = ppu_bus.cs && ppu_bus.rd;
    assign rd_addr = ppu_active ? ppu_bus.addr[12:0] : bus.addr[12:0];

    always_ff @(negedge clk) begin
        q0 <= vram0[rd_addr];
        q1 <= vram1[rd_addr];
        cpu_bank_q <= cpu_bank;
        blocked_q <= ppu_active;
    end

    assign bus.data_rd = (bus.cs && bus.rd && !blocked_q)
        ? (cpu_bank_q ? q1 : q0)
        : 8'hFF;
    assign ppu_bus.bank0_data = (ppu_bus.cs && ppu_bus.rd) ? q0 : 8'hFF;
    assign ppu_bus.bank1_data = (ppu_bus.cs && ppu_bus.rd) ? q1 : 8'hFF;

    always_ff @(posedge clk) begin
        if (bus.cs && bus.wr) begin
            if (cpu_bank)
                vram1[bus.addr[12:0]] <= bus.data_wr;
            else
                vram0[bus.addr[12:0]] <= bus.data_wr;
        end
    end
`endif

endmodule
