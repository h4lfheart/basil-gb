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
    
    bus boot_rom_bus();
    mem_boot_rom boot_rom(
        .clk(clk),
        .rst(rst),
        .bus(boot_rom_bus)
    );

    mmu mmu(
        .clk(clk),
        .rst(rst),
        .cpu_bus(cpu_bus),
        .boot_rom_bus(boot_rom_bus)
    );

endmodule