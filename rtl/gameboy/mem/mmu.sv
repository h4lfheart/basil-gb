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
    bus.parent_port wram_bus,
    bus.parent_port hram_bus,
    bus.parent_port ppu_bus,
    bus.parent_port cpu_reg_bus,
    bus.parent_port serial_bus,
    bus.parent_port timer_bus,
    bus.parent_port joypad_bus
);
    logic [7:0] BANK = 'h00;

    logic cs_boot_rom;
    logic cs_cart;
    logic cs_vram;
    logic cs_wram;
    logic cs_hram;
    logic cs_ppu;
    logic cs_cpu_reg;
    logic cs_serial;
    logic cs_timer;
    logic cs_joypad;

    always_comb begin
        cs_boot_rom = (BANK == 'h00) && cpu_bus.addr inside {[BOOT_ROM_START:BOOT_ROM_END]};
        cs_cart = !cs_boot_rom && cpu_bus.addr inside {[CART_ROM_START:CART_ROM_END], [CART_RAM_START:CART_RAM_END]};
        cs_vram = cpu_bus.addr inside {[VRAM_START:VRAM_END]};
        cs_wram = cpu_bus.addr inside {[WRAM_BANK0_START:WRAM_BANK0_END], [WRAM_BANKX_START:WRAM_BANKX_END],
                                       [ECHO_BANK0_START:ECHO_BANK0_END], [ECHO_BANKX_START:ECHO_BANKX_END]};
        cs_hram = cpu_bus.addr inside {[HRAM_START:HRAM_END]};
        cs_ppu = cpu_bus.addr inside {[PPU_REG_START:PPU_REG_END]};
        cs_cpu_reg = cpu_bus.addr inside {REG_IF, REG_IE};
        cs_serial = cpu_bus.addr inside {REG_SB, REG_SC};
        cs_timer = cpu_bus.addr inside {REG_DIV, REG_TIMA, REG_TMA, REG_TAC};
        cs_joypad = cpu_bus.addr inside {REG_JOYP};
        
    end

    `DEF_BUS(boot_rom_bus, cs_boot_rom)
    `DEF_BUS(cart_bus, cs_cart)
    `DEF_BUS(vram_bus, cs_vram)
    `DEF_BUS(wram_bus, cs_wram)
    `DEF_BUS(hram_bus, cs_hram)
    `DEF_BUS(ppu_bus, cs_ppu)
    `DEF_BUS(cpu_reg_bus, cs_cpu_reg)
    `DEF_BUS(serial_bus, cs_serial)
    `DEF_BUS(timer_bus, cs_timer)
    `DEF_BUS(joypad_bus, cs_joypad)

    
    always_ff @(posedge clk) begin
        if (rst) begin
            BANK <= 8'h00;
        end else if (cpu_bus.wr) begin
            if (cpu_bus.addr == REG_BANK)
                BANK <= cpu_bus.data_wr;
        end
    end

    always_comb begin
        cpu_bus.data_rd = 'hFF;

        if (cpu_bus.rd) begin
            if (cs_boot_rom) cpu_bus.data_rd = boot_rom_bus.data_rd;
            else if (cs_cart) cpu_bus.data_rd = cart_bus.data_rd;
            else if (cs_vram) cpu_bus.data_rd = vram_bus.data_rd;
            else if (cs_wram) cpu_bus.data_rd = wram_bus.data_rd;
            else if (cs_hram) cpu_bus.data_rd = hram_bus.data_rd;
            else if (cs_ppu) cpu_bus.data_rd = ppu_bus.data_rd;
            else if (cs_cpu_reg) cpu_bus.data_rd = cpu_reg_bus.data_rd;
            else if (cs_serial) cpu_bus.data_rd = serial_bus.data_rd;
            else if (cs_timer) cpu_bus.data_rd = timer_bus.data_rd;
            else if (cs_joypad) cpu_bus.data_rd = joypad_bus.data_rd;
            //else $display("Invalid read at 0x%0h", cpu_bus.addr);
        end
    end

    always_ff @(posedge cpu_bus.wr) begin
        if (cs_boot_rom);
        else if (cs_cart);
        else if (cs_vram);
        else if (cs_wram);
        else if (cs_hram);
        else if (cs_ppu);
        else if (cs_cpu_reg);
        else if (cs_serial);
        else if (cs_timer);
        else if (cs_joypad);
        //else $display("Invalid write at 0x%0h", cpu_bus.addr);
    end

endmodule