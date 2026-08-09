import mem_types::*;

module mem_wram(
    input logic clk,
    input logic rst,
    bus.child_port bus
);
    logic [7:0] wram [8]['h1000];

    logic [2:0] bank;

    function automatic logic [2:0] bank_sel(logic [15:0] addr);
        if (addr inside {[WRAM_BANKX_START:WRAM_BANKX_END], [ECHO_BANKX_START:ECHO_BANKX_END]})
            return bank;
        return 0;
    endfunction

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd) begin
            if (bus.addr == REG_SVBK)
                bus.data_rd = {5'b11111, bank};
            else
                bus.data_rd = wram[bank_sel(bus.addr)][bus.addr[11:0]];
        end
    end

    always_ff @(posedge clk) begin
        if (rst)
            bank <= 'd1;
        else if (bus.cs && bus.wr) begin
            if (bus.addr == REG_SVBK)
                bank <= (bus.data_wr[2:0] == 'd0) ? 'd1 : bus.data_wr[2:0];
            else
                wram[bank_sel(bus.addr)][bus.addr[11:0]] <= bus.data_wr;
        end
    end

endmodule
