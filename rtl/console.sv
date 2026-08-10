import apu_types::*;

module console(
    input logic clk,
    input logic rst,
    input joypad_buttons_t buttons,
    output mix_sample_t audio_sample_left,
    output mix_sample_t audio_sample_right
`ifndef VERILATOR
    ,
    fb_rd_bus.ppu fb_rd,
    input logic [7:0] header_cart_type,
    cart_ext_mem.core cart_mem,
    wram_ext_mem.core wram_mem
`endif
);
    bus cart_bus();
    cart cart(
        .clk(clk),
        .rst(rst),
        .bus(cart_bus)
`ifndef VERILATOR
        ,
        .header_cart_type(header_cart_type),
        .mem(cart_mem)
`endif
    );

    gameboy gameboy(
        .clk(clk),
        .rst(rst),
        .buttons(buttons),
        .cart_bus(cart_bus),
        .audio_sample_left(audio_sample_left),
        .audio_sample_right(audio_sample_right)
`ifndef VERILATOR
        ,
        .fb_rd(fb_rd),
        .wram_mem(wram_mem)
`endif
    );

endmodule
