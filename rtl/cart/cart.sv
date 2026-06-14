module cart(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] rom [32768] /*verilator public*/;

    always_comb begin
        bus.data_rd = rom[bus.addr];
    end

endmodule