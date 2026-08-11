interface cart_ext_mem;
    logic req;
    logic wr;
    logic ram_sel;
    logic [20:0] addr;
    logic [7:0] data_wr;
    logic [7:0] data_rd;

    modport core (
        output req,
        output wr,
        output ram_sel,
        output addr,
        output data_wr,
        input data_rd
    );

    modport memory (
        input req,
        input wr,
        input ram_sel,
        input addr,
        input data_wr,
        output data_rd
    );
endinterface
