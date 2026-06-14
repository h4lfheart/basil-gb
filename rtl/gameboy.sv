module gameboy(
    input logic clk,
    input logic rst
);
    bus cpu_bus();
    cpu cpu(
        .clk(clk),
        .rst(rst),
        .bus(cpu_bus)
    );

    bus cart_bus();
    cart cart(
        .clk(clk),
        .rst(rst),
        .bus(cart_bus)
    );
    
    bus boot_rom_bus();
    mem_boot_rom boot_rom(
        .clk(clk),
        .rst(rst),
        .bus(boot_rom_bus)
    );

    bus hram_bus();
    mem_hram hram(
        .clk(clk),
        .rst(rst),
        .bus(hram_bus)
    );

    bus vram_bus();
    mem_vram vram(
        .clk(clk),
        .rst(rst),
        .bus(vram_bus)
    );

    mmu mmu(
        .clk(clk),
        .rst(rst),
        .cpu_bus(cpu_bus),
        .boot_rom_bus(boot_rom_bus),
        .vram_bus(vram_bus),
        .hram_bus(hram_bus),
        .cart_bus(cart_bus)
    );

endmodule