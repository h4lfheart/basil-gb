module mem_boot_rom(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] rom ['h900] /*verilator public*/
        /* synthesis syn_ramstyle = "block_ram" */;

`ifdef VERILATOR
    always_comb begin
        bus.data_rd = 8'hFF;

        if (bus.cs && bus.rd)
            bus.data_rd = rom[bus.addr[12:0]];
    end
`else
    initial $readmemh("rom/bootrom.hex", rom);

    logic [7:0] rom_q;
    always_ff @(negedge clk)
        rom_q <= rom[bus.addr[11:0]];

    assign bus.data_rd = (bus.cs && bus.rd) ? rom_q : 8'hFF;
`endif

endmodule
