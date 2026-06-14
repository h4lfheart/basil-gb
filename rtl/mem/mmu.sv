import mem_types::*;

`define DEF_BUS(child, cs_sig) \
    always_comb begin \
        child.addr = cpu_bus.addr; \
        child.data_wr = cpu_bus.data_wr; \
        child.rd = cpu_bus.rd; \
        child.wr = cpu_bus.wr; \
        child.cs = cs_sig; \
    end

module mmu (
    input logic clk,
    input logic rst,
    bus.child_port cpu_bus,
    bus.parent_port boot_rom_bus,
    bus.parent_port cart_bus,
    bus.parent_port vram_bus,
    bus.parent_port hram_bus,
    bus.parent_port ppu_bus
);
    logic [7:0] BANK = 'h00;

    logic cs_boot_rom;
    logic cs_cart;
    logic cs_vram;
    logic cs_hram;
    logic cs_ppu;

    always_comb begin
        cs_boot_rom = (BANK == 'h00) && cpu_bus.addr inside {[BOOT_ROM_START:BOOT_ROM_END]};
        cs_cart = !cs_boot_rom && cpu_bus.addr inside {[CART_ROM_START:CART_ROM_END], [CART_RAM_START:CART_RAM_END]};
        cs_vram = cpu_bus.addr inside{[VRAM_START:VRAM_END]};
        cs_hram = cpu_bus.addr inside{[HRAM_START:HRAM_END]};
        cs_ppu = cpu_bus.addr inside{[PPU_REG_START:PPU_REG_END]};
    end

    `DEF_BUS(boot_rom_bus, cs_boot_rom)
    `DEF_BUS(cart_bus, cs_cart)
    `DEF_BUS(vram_bus, cs_vram)
    `DEF_BUS(hram_bus, cs_hram)
    `DEF_BUS(ppu_bus, cs_ppu)

    always_comb begin
        cpu_bus.data_rd = 'hFF;

        if (cpu_bus.rd) begin
            if (cs_boot_rom) cpu_bus.data_rd = boot_rom_bus.data_rd;
            else if (cs_cart) cpu_bus.data_rd = cart_bus.data_rd;
            else if (cs_vram) cpu_bus.data_rd = vram_bus.data_rd;
            else if (cs_hram) cpu_bus.data_rd = hram_bus.data_rd;
            else if (cs_ppu) cpu_bus.data_rd = ppu_bus.data_rd;
            else $display("Invalid read at 0x%0h", cpu_bus.addr);
        end
    end

    always_comb begin
        if (cpu_bus.wr) begin
            if (cs_boot_rom);
            else if (cs_vram);
            else if (cs_cart);
            else if (cs_hram);
            else if (cs_ppu);
            else $display("Invalid write at 0x%0h", cpu_bus.addr);
        end
    end

endmodule