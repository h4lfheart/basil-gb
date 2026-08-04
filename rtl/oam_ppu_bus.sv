interface oam_ppu_bus;
    logic [7:0] addr;
    logic [15:0] data_rd;
    logic rd;
    logic cs;

    modport parent_port (
        output addr,
        input data_rd,
        output rd,
        output cs
    );

    modport child_port (
        input addr,
        output data_rd,
        input rd,
        input cs
    );
endinterface
