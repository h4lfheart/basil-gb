interface vram_ppu_bus;
    logic [12:0] addr;
    logic [7:0] bank0_data;
    logic [7:0] bank1_data;
    logic rd;
    logic cs;

    modport parent_port (
        output addr,
        input bank0_data,
        input bank1_data,
        output rd,
        output cs
    );

    modport child_port (
        input addr,
        output bank0_data,
        output bank1_data,
        input rd,
        input cs
    );
endinterface
