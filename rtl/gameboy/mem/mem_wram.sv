import mem_types::*;

module mem_wram(
    input logic clk,
    input logic rst,
    bus.child_port bus
`ifndef VERILATOR
    ,
    wram_ext_mem.core mem
`endif
);
`ifdef VERILATOR
    logic [7:0] wram [8]['h1000];
`endif

    logic [2:0] bank;

    function automatic logic [2:0] bank_sel(logic [15:0] addr);
        if (addr inside {[WRAM_BANKX_START:WRAM_BANKX_END], [ECHO_BANKX_START:ECHO_BANKX_END]})
            return bank;
        return 0;
    endfunction

`ifdef VERILATOR
    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd) begin
            if (bus.addr == REG_SVBK)
                bus.data_rd = {5'b11111, bank};
            else
                bus.data_rd = wram[bank_sel(bus.addr)][bus.addr[11:0]];
        end
    end
`else
    assign mem.req = bus.cs && bus.rd && (bus.addr != REG_SVBK);
    assign mem.wr = bus.cs && bus.wr && (bus.addr != REG_SVBK);
    assign mem.addr = {bank_sel(bus.addr), bus.addr[11:0]};
    assign mem.data_wr = bus.data_wr;

    always_comb begin
        bus.data_rd = 8'hFF;
        if (bus.cs && bus.rd) begin
            if (bus.addr == REG_SVBK)
                bus.data_rd = {5'b11111, bank};
            else
                bus.data_rd = mem.data_rd;
        end
    end
`endif

    always_ff @(posedge clk) begin
        if (rst)
            bank <= 'd1;
        else if (bus.cs && bus.wr) begin
            if (bus.addr == REG_SVBK)
                bank <= (bus.data_wr[2:0] == 'd0) ? 'd1 : bus.data_wr[2:0];
`ifdef VERILATOR
            else
                wram[bank_sel(bus.addr)][bus.addr[11:0]] <= bus.data_wr;
`endif
        end
    end

endmodule
