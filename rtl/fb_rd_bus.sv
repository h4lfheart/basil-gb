interface fb_rd_bus;
    logic clk;
    logic [14:0] addr;
    logic [14:0] data;

    modport ppu (
        input clk,
        input addr,
        output data
    );

    modport scanout (
        output addr,
        input data
    );
endinterface
