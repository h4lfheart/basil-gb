import mem_types::*;

module mem_wram(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] wram [8]['h1000];

    logic [2:0] bank = 'd1; // TODO CGB Bank Switching

    function automatic logic [2:0] bank_sel(logic [15:0] addr);
        if (addr inside {[WRAM_BANKX_START:WRAM_BANKX_END],
                         [ECHO_BANKX_START:ECHO_BANKX_END]})
            return bank;
        return 0;
    endfunction

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd)
            bus.data_rd = wram[bank_sel(bus.addr)][bus.addr[11:0]];
    end

    always_ff @(posedge clk)
        if (bus.cs && bus.wr)
            wram[bank_sel(bus.addr)][bus.addr[11:0]] <= bus.data_wr;

endmodule