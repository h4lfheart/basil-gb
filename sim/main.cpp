#include <cstdio>
#include <cstdint>
#include <memory>
#include <iostream>
#include <fstream>

#include <Vgameboy.h>
#include <Vgameboy_gameboy.h>
#include <Vgameboy_mem_boot_rom.h>
#include "verilated.h"
#include "verilated_vcd_c.h"

#include "argparse/argparse.hpp"

uint64_t clk_time = 0;

double sc_time_stamp() {
    return clk_time;
}

void clock_cycle(const std::unique_ptr<Vgameboy>& gb, const std::unique_ptr<VerilatedVcdC>& vcd) {
    gb->clk = 1;
    gb->eval();
    if (vcd) vcd->dump(clk_time);
    clk_time++;

    gb->clk = 0;
    gb->eval();
    if (vcd) vcd->dump(clk_time);
    clk_time++;
}


template <typename T>
void load_rom(const std::string& path, T& mem, size_t mem_size) {
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

int main(int argc, char **argv)
{
    argparse::ArgumentParser arguments("basil-gb");

    arguments.add_argument("bootrom")
        .help("The path for your gameboy boot rom file.")
        .required();

    arguments.add_argument("rom")
        .help("The path for your gameboy rom file.")
        .required();

    arguments.add_argument("--trace")
        .help("Path to write a VCD trace file.");

    try {
        arguments.parse_args(argc, argv);
    }
    catch (const std::exception& err) {
        std::cerr << err.what() << std::endl;
        std::cerr << arguments;
        return 1;
    }

    auto bootrom_path = arguments.get<std::string>("bootrom");
    auto rom_path = arguments.get<std::string>("rom");

    const auto ctx = std::make_unique<VerilatedContext>();
    ctx->commandArgs(argc, argv);

    const auto gb = std::make_unique<Vgameboy>(ctx.get());

    load_rom(bootrom_path, gb->gameboy->boot_rom->rom, 256);

    std::unique_ptr<VerilatedVcdC> vcd;
    if (auto trace_path = arguments.present<std::string>("--trace")) {
        ctx->traceEverOn(true);
        vcd = std::make_unique<VerilatedVcdC>();
        gb->trace(vcd.get(), 99);
        vcd->open(trace_path->c_str());
    }

    gb->rst = 1;
    clock_cycle(gb, vcd);
    clock_cycle(gb, vcd);

    gb->rst = 0;
    clock_cycle(gb, vcd);

    while (!ctx->gotFinish()) {
        clock_cycle(gb, vcd);
    }

    if (vcd != nullptr) 
        vcd->close();
}