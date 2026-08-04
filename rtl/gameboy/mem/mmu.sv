import mem_types::*;

`define MMU_CONNECT_CPU(child, sel) \
    always_comb begin \
        child.addr = cpu_bus.addr; \
        child.data_wr = cpu_bus.data_wr; \
        child.rd = cpu_bus.rd; \
        child.wr = cpu_bus.wr; \
        child.cs = (sel); \
    end

`define MMU_CONNECT_ARB(child, cpu_sel, dma_sel, dma_can_wr) \
    always_comb begin \
        if (dma_active && dma_bus.cs && (dma_sel)) begin \
            child.addr = dma_bus.addr; \
            child.data_wr = dma_bus.data_wr; \
            child.rd = dma_bus.rd; \
            child.wr = (dma_can_wr) && dma_bus.wr; \
            child.cs = 1; \
        end else begin \
            child.addr = cpu_bus.addr; \
            child.data_wr = cpu_bus.data_wr; \
            child.rd = cpu_bus.rd; \
            child.wr = cpu_bus.wr; \
            child.cs = cpu_ok && (cpu_sel); \
        end \
    end

module mmu (
    input logic clk,
    input logic rst,
    input logic dma_active,
    input logic [15:0] dma_src_addr,
    bus.child_port cpu_bus,
    bus.child_port dma_bus,
    bus.parent_port dma_reg_bus,
    bus.parent_port boot_rom_bus,
    bus.parent_port cart_bus,
    bus.parent_port vram_bus,
    bus.parent_port wram_bus,
    bus.parent_port oam_bus,
    bus.parent_port hram_bus,
    bus.parent_port ppu_bus,
    bus.parent_port cpu_reg_bus,
    bus.parent_port serial_bus,
    bus.parent_port timer_bus,
    bus.parent_port joypad_bus
);
    typedef struct packed {
        logic boot_rom;
        logic cart;
        logic vram;
        logic wram;
        logic oam;
        logic hram;
        logic ppu;
        logic dma;
        logic cpu_reg;
        logic serial;
        logic timer;
        logic joypad;
    } cs_t;

    function automatic cs_t decode(input logic [15:0] addr, input logic [7:0] bank);
        cs_t cs;
        cs = '0;
        cs.dma = addr == REG_DMA;
        cs.boot_rom = (bank == 'h00) && addr inside {[BOOT_ROM_START:BOOT_ROM_END]};
        cs.cart = !cs.boot_rom && addr inside {[CART_ROM_START:CART_ROM_END], [CART_RAM_START:CART_RAM_END]};
        cs.vram = addr inside {[VRAM_START:VRAM_END]};
        cs.wram = addr inside {[WRAM_BANK0_START:WRAM_BANK0_END], [WRAM_BANKX_START:WRAM_BANKX_END], [ECHO_BANK0_START:ECHO_BANK0_END], [ECHO_BANKX_START:ECHO_BANKX_END]};
        cs.oam = addr inside {[OAM_START:OAM_END]};
        cs.hram = addr inside {[HRAM_START:HRAM_END]};
        cs.ppu = addr inside {[PPU_REG_START:PPU_REG_END]} && !cs.dma;
        cs.cpu_reg = addr inside {REG_IF, REG_IE};
        cs.serial = addr inside {REG_SB, REG_SC};
        cs.timer = addr inside {REG_DIV, REG_TIMA, REG_TMA, REG_TAC};
        cs.joypad = addr inside {REG_JOYP};
        return cs;
    endfunction

    typedef enum logic [1:0] {
        BUS_CPU = 2'd0,
        BUS_MAIN = 2'd1,
        BUS_VRAM = 2'd2
    } ext_bus_t;

    function automatic ext_bus_t ext_bus(input logic [15:0] addr);
        if (addr inside {[VRAM_START:VRAM_END]})
            return BUS_VRAM;
        if (addr inside {[ECHO_BANK0_START:'hFFFF]})
            return BUS_CPU;
        return BUS_MAIN;
    endfunction

    logic [7:0] BANK = 'h00;
    cs_t cpu_cs;
    cs_t dma_cs;
    ext_bus_t dma_src_bus;
    ext_bus_t cpu_access_bus;
    logic dma_src_bus_conflict;
    logic dma_blocks_oam;
    logic cpu_ok;

    assign cpu_cs = decode(cpu_bus.addr, BANK);
    assign dma_cs = decode(dma_bus.addr, BANK);

    assign dma_src_bus = ext_bus(dma_src_addr);
    assign cpu_access_bus = ext_bus(cpu_bus.addr);

    assign dma_src_bus_conflict = dma_active
        && (dma_src_bus != BUS_CPU)
        && (dma_src_bus == cpu_access_bus);

    assign dma_blocks_oam = dma_active && cpu_cs.oam;

    assign cpu_ok = !(dma_blocks_oam || dma_src_bus_conflict);

    `MMU_CONNECT_CPU(dma_reg_bus, cpu_cs.dma)
    `MMU_CONNECT_CPU(hram_bus, cpu_cs.hram)
    `MMU_CONNECT_CPU(cpu_reg_bus, cpu_cs.cpu_reg)
    `MMU_CONNECT_CPU(ppu_bus, cpu_ok && cpu_cs.ppu)
    `MMU_CONNECT_CPU(serial_bus, cpu_ok && cpu_cs.serial)
    `MMU_CONNECT_CPU(timer_bus, cpu_ok && cpu_cs.timer)
    `MMU_CONNECT_CPU(joypad_bus, cpu_ok && cpu_cs.joypad)

    `MMU_CONNECT_ARB(boot_rom_bus, cpu_cs.boot_rom, dma_cs.boot_rom, 0)
    `MMU_CONNECT_ARB(cart_bus, cpu_cs.cart, dma_cs.cart, 0)
    `MMU_CONNECT_ARB(vram_bus, cpu_cs.vram, dma_cs.vram, 0)
    `MMU_CONNECT_ARB(wram_bus, cpu_cs.wram, dma_cs.wram, 0)
    `MMU_CONNECT_ARB(oam_bus, cpu_cs.oam, dma_cs.oam, 1)

    always_ff @(posedge clk) begin
        if (rst)
            BANK <= 'h00;
        else if (cpu_bus.wr && cpu_ok && cpu_bus.addr == REG_BANK)
            BANK <= cpu_bus.data_wr;
    end

    always_comb begin
        dma_bus.data_rd = 'hFF;
        if (dma_bus.rd) begin
            if (dma_cs.boot_rom) dma_bus.data_rd = boot_rom_bus.data_rd;
            else if (dma_cs.cart) dma_bus.data_rd = cart_bus.data_rd;
            else if (dma_cs.vram) dma_bus.data_rd = vram_bus.data_rd;
            else if (dma_cs.wram) dma_bus.data_rd = wram_bus.data_rd;
            else if (dma_cs.oam) dma_bus.data_rd = oam_bus.data_rd;
        end
    end

    always_comb begin
        cpu_bus.data_rd = 'hFF;
        if (cpu_bus.rd) begin
            if (cpu_cs.dma) cpu_bus.data_rd = dma_reg_bus.data_rd;
            else if (cpu_cs.hram) cpu_bus.data_rd = hram_bus.data_rd;
            else if (cpu_cs.cpu_reg) cpu_bus.data_rd = cpu_reg_bus.data_rd;
            else if (cpu_ok) begin
                if (cpu_cs.boot_rom) cpu_bus.data_rd = boot_rom_bus.data_rd;
                else if (cpu_cs.cart) cpu_bus.data_rd = cart_bus.data_rd;
                else if (cpu_cs.vram) cpu_bus.data_rd = vram_bus.data_rd;
                else if (cpu_cs.wram) cpu_bus.data_rd = wram_bus.data_rd;
                else if (cpu_cs.oam) cpu_bus.data_rd = oam_bus.data_rd;
                else if (cpu_cs.ppu) cpu_bus.data_rd = ppu_bus.data_rd;
                else if (cpu_cs.serial) cpu_bus.data_rd = serial_bus.data_rd;
                else if (cpu_cs.timer) cpu_bus.data_rd = timer_bus.data_rd;
                else if (cpu_cs.joypad) cpu_bus.data_rd = joypad_bus.data_rd;
            end
        end
    end

endmodule
