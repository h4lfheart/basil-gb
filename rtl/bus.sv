interface bus;
    logic [15:0] addr;
    logic [7:0] data_rd;
    logic [7:0] data_wr;
    logic rd;
    logic wr;
    logic cs;

    modport parent_port (
        output addr,
        input data_rd,
        output data_wr,
        output rd,
        output wr,
        output cs
    );

    modport child_port (
        input addr,
        output data_rd,
        input data_wr,
        input rd,
        input wr,
        input cs
    );
endinterface