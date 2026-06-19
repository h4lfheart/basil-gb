#pragma once

#include <cstdint>
#include <memory>
#include <string>

#include <Vgameboy.h>
#include "verilated.h"
#include "verilated_vcd_c.h"

extern std::string serial_buffer;
extern bool serial_echo;
extern bool serial_dirty;

extern "C" void serial_putchar(unsigned char c);

double sc_time_stamp();

struct Simulation {
    std::unique_ptr<VerilatedContext> ctx;
    std::unique_ptr<Vgameboy> gb;
    uint64_t clk_time = 0;

    Simulation();

    void load_bootrom(const std::string& path);
    void load_rom(const std::string& path);
    void reset();
    void clock_cycle(VerilatedVcdC* vcd = nullptr, uint64_t trace_start = 0);
    bool finished() const;
    void open_trace(const std::string& path, VerilatedVcdC& vcd, int depth = 99);
};