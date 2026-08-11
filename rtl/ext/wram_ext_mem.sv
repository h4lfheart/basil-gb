interface wram_ext_mem;
    logic req;
    logic wr;
    logic [14:0] addr;
    logic [7:0] data_wr;
    logic [7:0] data_rd;

    modport core (
        output req,
        output wr,
        output addr,
        output data_wr,
        input data_rd
    );

    modport memory (
        input req,
        input wr,
        input addr,
        input data_wr,
        output data_rd
    );
endinterface
