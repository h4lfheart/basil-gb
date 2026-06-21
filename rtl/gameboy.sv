module gameboy(
    input logic clk,
    input logic rst
);
    bus cpu_bus();
    bus cpu_reg_bus();
    cpu cpu(
        .clk(clk),
        .rst(rst),
        .bus(cpu_bus),
        .reg_bus(cpu_reg_bus),
        .interrupts('{
            joypad: 0,
            serial: 0,
            timer: timer_interrupt,
            stat: stat_interrupt,
            vblank: vblank_interrupt
        })

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
        .bus(vram_bus),
        .ppu_bus(ppu_vram_bus)
    );

    bus wram_bus();
    mem_wram wram(
        .clk(clk),
        .rst(rst),
        .bus(wram_bus)
    );

    logic vblank_interrupt;
    logic stat_interrupt;
    bus ppu_bus();
    bus ppu_vram_bus();
    ppu ppu(
        .clk(clk),
        .rst(rst),
        .bus(ppu_bus),
        .vblank_interrupt(vblank_interrupt),
        .vram_bus(ppu_vram_bus)
    );

    bus serial_bus();
    serial serial(
        .clk(clk),
        .rst(rst),
        .bus(serial_bus)
    );

    logic timer_interrupt;
    bus timer_bus();
    timer timer(
        .clk(clk),
        .rst(rst),
        .bus(timer_bus),
        .interrupt(timer_interrupt)
    );

    mmu mmu(
        .clk(clk),
        .rst(rst),
        .cpu_bus(cpu_bus),
        .boot_rom_bus(boot_rom_bus),
        .vram_bus(vram_bus),
        .hram_bus(hram_bus),
        .wram_bus(wram_bus),
        .cart_bus(cart_bus),
        .ppu_bus(ppu_bus),
        .cpu_reg_bus(cpu_reg_bus),
        .serial_bus(serial_bus),
        .timer_bus(timer_bus)
    );

endmodule