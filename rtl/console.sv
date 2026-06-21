module console(
    input logic clk,
    input logic rst,
    input joypad_buttons_t buttons
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
        .cart_bus(cart_bus)
    );

endmodule