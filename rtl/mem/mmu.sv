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
    bus.parent_port boot_rom_bus
);

    logic cs_boot_rom;

    always_comb begin
        cs_boot_rom = cpu_bus.addr inside {[BOOT_ROM_START:BOOT_ROM_END]};
    end

    `DEF_BUS(boot_rom_bus, cs_boot_rom)

    always_comb begin
        cpu_bus.data_rd = 'hFF;

        if (cpu_bus.rd) begin
            if (cs_boot_rom)
                cpu_bus.data_rd = boot_rom_bus.data_rd;
            else
                $display("Invalid read at 0x%0h", cpu_bus.addr);
        end
    end

endmodule