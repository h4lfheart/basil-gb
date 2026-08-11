import apu_types::*;

module gameboy(
    input logic clk,
    input logic rst,
    input joypad_buttons_t buttons,
    bus.parent_port cart_bus,
    output mix_sample_t audio_sample_left,
    output mix_sample_t audio_sample_right
`ifndef VERILATOR
    ,
    fb_rd_bus.ppu fb_rd,
    wram_ext_mem.core wram_mem
`endif
);
    logic hdma_cpu_stall;
    logic cpu_stalled;
    
    logic vblank_interrupt;
    logic stat_interrupt;
    logic timer_interrupt;

    logic boot_disable;

    logic cgb_mode;
    logic cpu_oam_blocked;
    logic cpu_vram_bank;
    logic hblank_pulse;
    logic lcd_on;

    logic [15:0] div;

    logic dma_active;
    logic [15:0] dma_src_addr;

    logic hdma_active;
    logic [15:0] hdma_src_addr;

    bus cpu_bus();
    bus cpu_reg_bus();
    bus boot_rom_bus();
    bus hram_bus();
    bus vram_bus();
    bus wram_bus();
    bus oam_bus();
    bus ppu_bus();
    bus serial_bus();
    bus joypad_bus();
    bus timer_bus();
    bus apu_bus();
    bus dma_reg_bus();
    bus dma_mem_bus();
    bus hdma_reg_bus();
    bus hdma_mem_bus();
    vram_ppu_bus ppu_vram_bus();
    oam_ppu_bus ppu_oam_bus();

    cpu cpu(
        .clk(clk),
        .rst(rst),
        .stall(hdma_cpu_stall),
        .stall_ack(cpu_stalled),
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

    mem_boot_rom boot_rom(
        .clk(clk),
        .rst(rst),
        .bus(boot_rom_bus)
    );

    mem_hram hram(
        .clk(clk),
        .rst(rst),
        .bus(hram_bus)
    );

    mem_vram vram(
        .clk(clk),
        .rst(rst),
        .cpu_bank(cpu_vram_bank),
        .bus(vram_bus),
        .ppu_bus(ppu_vram_bus)
    );

    mem_wram wram(
        .clk(clk),
        .rst(rst),
        .bus(wram_bus)
`ifndef VERILATOR
        ,
        .mem(wram_mem)
`endif
    );

    mem_oam oam(
        .clk(clk),
        .rst(rst),
        .bus(oam_bus),
        .ppu_bus(ppu_oam_bus)
    );

    ppu ppu(
        .clk(clk),
        .rst(rst),
        .cgb_mode(cgb_mode),
        .boot_disable(boot_disable),
        .bus(ppu_bus),
        .vblank_interrupt(vblank_interrupt),
        .stat_interrupt(stat_interrupt),
        .vram_bus(ppu_vram_bus),
        .oam_bus(ppu_oam_bus),
        .cpu_vram_bank(cpu_vram_bank),
        .cpu_oam_blocked(cpu_oam_blocked),
        .hblank_pulse(hblank_pulse),
        .lcd_on(lcd_on)
`ifndef VERILATOR
        ,
        .fb_rd(fb_rd)
`endif
    );

    serial serial(
        .clk(clk),
        .rst(rst),
        .bus(serial_bus)
    );

    joypad joypad(
        .clk(clk),
        .rst(rst),
        .bus(joypad_bus),
        .buttons(buttons)
    );

    timer timer(
        .clk(clk),
        .rst(rst),
        .bus(timer_bus),
        .interrupt(timer_interrupt),
        .div(div)
    );

    apu apu(
        .clk(clk),
        .rst(rst),
        .reg_bus(apu_bus),
        .div(div),
        .sample_left(audio_sample_left),
        .sample_right(audio_sample_right)
    );

    oam_dma oam_dma(
        .clk(clk),
        .rst(rst),
        .reg_bus(dma_reg_bus),
        .mem_bus(dma_mem_bus),
        .active(dma_active),
        .src_addr(dma_src_addr)
    );

    vdma hdma(
        .clk(clk),
        .rst(rst),
        .hblank_pulse(hblank_pulse),
        .lcd_on(lcd_on),
        .cpu_stalled(cpu_stalled),
        .reg_bus(hdma_reg_bus),
        .mem_bus(hdma_mem_bus),
        .active(hdma_active),
        .cpu_stall(hdma_cpu_stall),
        .src_addr(hdma_src_addr)
    );

    mmu mmu(
        .clk(clk),
        .rst(rst),
        .dma_active(dma_active),
        .dma_src_addr(dma_src_addr),
        .hdma_active(hdma_active),
        .hdma_src_addr(hdma_src_addr),
        .cpu_oam_blocked(cpu_oam_blocked),
        .cpu_bus(cpu_bus),
        .dma_bus(dma_mem_bus),
        .hdma_bus(hdma_mem_bus),
        .dma_reg_bus(dma_reg_bus),
        .hdma_reg_bus(hdma_reg_bus),
        .boot_rom_bus(boot_rom_bus),
        .vram_bus(vram_bus),
        .hram_bus(hram_bus),
        .wram_bus(wram_bus),
        .oam_bus(oam_bus),
        .cart_bus(cart_bus),
        .ppu_bus(ppu_bus),
        .cpu_reg_bus(cpu_reg_bus),
        .serial_bus(serial_bus),
        .timer_bus(timer_bus),
        .joypad_bus(joypad_bus),
        .apu_bus(apu_bus),
        .cgb_mode(cgb_mode),
        .boot_disable(boot_disable)
    );

endmodule
