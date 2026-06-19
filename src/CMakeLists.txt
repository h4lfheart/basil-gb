cmake_minimum_required(VERSION 3.20)
project(basil_gb CXX)

set(CMAKE_CXX_STANDARD 23)

add_executable(basil_gb
    main.cpp
    sim/sim.cpp
    testing/runner.cpp
)

target_include_directories(basil_gb PRIVATE
    ${CMAKE_SOURCE_DIR}/../external/argparse/include
)

target_compile_options(basil_gb PRIVATE -O3)

set(VERILATOR_ROOT $ENV{VERILATOR_ROOT})
set(VERILATOR_BIN $ENV{VERILATOR_BIN})
find_package(verilator HINTS ${VERILATOR_ROOT} REQUIRED)

verilate(basil_gb
    SOURCES
        ../rtl/util/edge_detect.sv

        ../rtl/bus.sv

        ../rtl/cart/cart.sv

        ../rtl/cpu/cpu_types.sv
        ../rtl/cpu/cpu_bus_controller.sv
        ../rtl/cpu/cpu_regfile.sv
        ../rtl/cpu/cpu_alu.sv
        ../rtl/cpu/cpu_idu.sv
        ../rtl/cpu/cpu_control.sv
        ../rtl/cpu/cpu_clock.sv
        ../rtl/cpu/cpu.sv

        ../rtl/io/serial.sv

        ../rtl/timer/timer.sv

        ../rtl/ppu/ppu.sv

        ../rtl/mem/mem_types.sv
        ../rtl/mem/mem_boot_rom.sv
        ../rtl/mem/mem_hram.sv
        ../rtl/mem/mem_vram.sv
        ../rtl/mem/mem_wram.sv
        ../rtl/mem/mmu.sv

        ../rtl/gameboy.sv
    TOP_MODULE gameboy
    PREFIX Vgameboy
    TRACE_VCD
    OPT_FAST "-O3"
    OPT_SLOW "-O2"
    OPT_GLOBAL "-O2"
    VERILATOR_ARGS
        --cc --sv --Wall -Wno-fatal
        -O3 --x-assign fast --x-initial fast --no-timing
)