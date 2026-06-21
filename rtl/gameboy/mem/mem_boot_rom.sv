module mem_boot_rom(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] rom [256] /*verilator public*/;

    always_comb begin
        bus.data_rd = 8'hFF;

        if (bus.cs && bus.rd)
            bus.data_rd = rom[bus.addr[7:0]];
    end

endmodule