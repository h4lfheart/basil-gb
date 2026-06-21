#include "sim.h"

#include <fstream>
#include <vector>
#include <cstdio>

#include <Vconsole.h>
#include <Vconsole_console.h>
#include <Vconsole_gameboy.h>
#include <Vconsole_cart.h>
#include <Vconsole_mem_boot_rom.h>
#include "Vconsole__Dpi.h"

std::string serial_buffer;
bool serial_echo = false;
bool serial_dirty = false;

extern "C" void serial_putchar(unsigned char c) {
    serial_buffer += static_cast<char>(c);
    serial_dirty = true;
    if (serial_echo)
        std::putchar(static_cast<char>(c));
}

double sc_time_stamp() {
    return 0;
}

Simulation::Simulation()
    : ctx(std::make_unique<VerilatedContext>())
    , system(std::make_unique<Vconsole>(ctx.get()))
{}

template <typename T>
static void load_file(const std::string& path, T& mem, size_t mem_size) {
    std::ifstream file(path, std::ios::binary | std::ios::ate);
    if (!file) return;

    const auto size = static_cast<size_t>(file.tellg());
    if (size > mem_size) return;

    file.seekg(0);

    std::vector<uint8_t> buf(size);
    if (!file.read(reinterpret_cast<char*>(buf.data()), static_cast<std::streamsize>(size))) return;

    for (size_t i = 0; i < size; i++)
        mem[i] = buf[i];
}

void Simulation::load_bootrom(const std::string& path) {
    load_file(path, system->console->gameboy->boot_rom->rom, 256);
}

void Simulation::load_rom(const std::string& path) {
    load_file(path, system->console->cart->rom, 32768);
}

void Simulation::reset(VerilatedVcdC* vcd, uint64_t trace_start) {
    system->rst = 1;
    clock_cycle(vcd, trace_start);
    clock_cycle(vcd, trace_start);
    system->rst = 0;

    system->buttons = 0xFF;
}

void Simulation::clock_cycle(VerilatedVcdC* vcd, uint64_t trace_start) {
    system->clk = 1;
    system->eval();
    if (vcd && clk_time >= trace_start) vcd->dump(clk_time - trace_start);
    clk_time++;

    system->clk = 0;
    system->eval();
    if (vcd && clk_time >= trace_start) vcd->dump(clk_time - trace_start);
    clk_time++;
}

bool Simulation::finished() const {
    return ctx->gotFinish();
}

void Simulation::open_trace(const std::string& path, VerilatedVcdC& vcd, int depth) {
    ctx->traceEverOn(true);
    system->trace(&vcd, depth);
    vcd.open(path.c_str());
}