import apu_types::*;

module console(
    input logic clk,
    input logic rst,
    input joypad_buttons_t buttons,
    output mix_sample_t audio_sample_left,
    output mix_sample_t audio_sample_right
);
    bus cart_bus();
    cart cart(
        .clk(clk),
        .rst(rst),
        .bus(cart_bus)
    );

    gameboy gameboy(
        .clk(clk),
        .rst(rst),
        .buttons(buttons),
        .cart_bus(cart_bus),
        .audio_sample_left(audio_sample_left),
        .audio_sample_right(audio_sample_right)
    );

endmodule