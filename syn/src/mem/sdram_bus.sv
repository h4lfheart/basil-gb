interface sdram_bus;
    logic rd;
    logic wr;
    logic refresh;
    logic [22:0] addr;
    logic [7:0] din;
    logic [7:0] dout;
    logic data_ready;
    logic busy;

    modport client (
        output rd,
        output wr,
        output refresh,
        output addr,
        output din,
        input dout,
        input data_ready,
        input busy
    );

    modport host (
        input rd,
        input wr,
        input refresh,
        input addr,
        input din,
        output dout,
        output data_ready,
        output busy
    );
endinterface
