interface spi_flash_bus;
    logic cs_n;
    logic clk;
    logic mosi;
    logic miso;

    modport controller (
        output cs_n,
        output clk,
        output mosi,
        input miso
    );
endinterface
