cmake_minimum_required(VERSION 3.20)
project(basil_gb CXX)

set(CMAKE_CXX_STANDARD 23)

find_package(SDL2 REQUIRED)
find_package(OpenGL REQUIRED)

if(WIN32)
    set(APP_RC src/app.rc)
endif()

add_executable(basil_gb
    src/main.cpp
    src/sim/sim.cpp
    src/testing/runner.cpp
    src/debug/debug_ui.cpp
    ${APP_RC}
)

set(IMGUI_DIR ${CMAKE_SOURCE_DIR}/external/imgui)

target_sources(basil_gb PRIVATE
    ${IMGUI_DIR}/imgui.cpp
    ${IMGUI_DIR}/imgui_draw.cpp
    ${IMGUI_DIR}/imgui_tables.cpp
    ${IMGUI_DIR}/imgui_widgets.cpp
    ${IMGUI_DIR}/backends/imgui_impl_sdl2.cpp
    ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
)

target_include_directories(basil_gb PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/external/argparse/include
    ${IMGUI_DIR}
    ${IMGUI_DIR}/backends
    ${SDL2_INCLUDE_DIRS}
)

target_link_libraries(basil_gb PRIVATE
    ${SDL2_LIBRARIES}
    OpenGL::GL
)

target_compile_options(basil_gb PRIVATE -O3)

set(VERILATOR_ROOT $ENV{VERILATOR_ROOT})
set(VERILATOR_BIN $ENV{VERILATOR_BIN})
find_package(verilator HINTS ${VERILATOR_ROOT} REQUIRED)

verilate(basil_gb
    SOURCES
        ../rtl/util/edge_detect.sv

        ../rtl/bus.sv
        ../rtl/ext/cart_ext_mem.sv
        ../rtl/ext/wram_ext_mem.sv
        ../rtl/ext/fb_rd_bus.sv

        ../rtl/cart/cart_types.sv
        ../rtl/cart/mbc0.sv
        ../rtl/cart/mbc1.sv
        ../rtl/cart/mbc3.sv
        ../rtl/cart/mbc5.sv
        ../rtl/cart/cart.sv

        ../rtl/gameboy/cpu/cpu_types.sv
        ../rtl/gameboy/cpu/cpu_bus_controller.sv
        ../rtl/gameboy/cpu/cpu_regfile.sv
        ../rtl/gameboy/cpu/cpu_alu.sv
        ../rtl/gameboy/cpu/cpu_idu.sv
        ../rtl/gameboy/cpu/cpu_control.sv
        ../rtl/gameboy/cpu/cpu_clock.sv
        ../rtl/gameboy/cpu/cpu.sv

        ../rtl/gameboy/io/joypad.sv
        ../rtl/gameboy/io/serial.sv

        ../rtl/gameboy/timer/timer.sv

        ../rtl/gameboy/apu/apu_types.sv
        ../rtl/gameboy/apu/components/apu_length.sv
        ../rtl/gameboy/apu/components/apu_envelope.sv
        ../rtl/gameboy/apu/components/apu_freq_timer.sv
        ../rtl/gameboy/apu/components/apu_duty.sv
        ../rtl/gameboy/apu/components/apu_sweep.sv
        ../rtl/gameboy/apu/components/apu_lfsr.sv
        ../rtl/gameboy/apu/components/apu_highpass.sv
        ../rtl/gameboy/apu/apu_ch1.sv
        ../rtl/gameboy/apu/apu_ch2.sv
        ../rtl/gameboy/apu/apu_ch3.sv
        ../rtl/gameboy/apu/apu_ch4.sv
        ../rtl/gameboy/apu/apu.sv

        ../rtl/gameboy/ppu/oam_ppu_bus.sv
        ../rtl/gameboy/ppu/vram_ppu_bus.sv
        ../rtl/gameboy/ppu/ppu_types.sv
        ../rtl/gameboy/ppu/ppu_fifo.sv
        ../rtl/gameboy/ppu/ppu_bg_win_fetcher.sv
        ../rtl/gameboy/ppu/ppu_oam_scan.sv
        ../rtl/gameboy/ppu/ppu_obj_fetcher.sv
        ../rtl/gameboy/ppu/ppu_shifter.sv
        ../rtl/gameboy/ppu/ppu_state.sv
        ../rtl/gameboy/ppu/ppu.sv

        ../rtl/gameboy/mem/mem_types.sv
        ../rtl/gameboy/mem/mem_boot_rom.sv
        ../rtl/gameboy/mem/mem_hram.sv
        ../rtl/gameboy/mem/mem_vram.sv
        ../rtl/gameboy/mem/mem_wram.sv
        ../rtl/gameboy/mem/mem_oam.sv
        ../rtl/gameboy/mem/dma/oam_dma.sv
        ../rtl/gameboy/mem/dma/vdma.sv
        ../rtl/gameboy/mem/mmu.sv

        ../rtl/gameboy/gameboy.sv
        ../rtl/console.sv

    TOP_MODULE console
    PREFIX Vconsole
    TRACE_VCD
    OPT_FAST "-O3"
    OPT_SLOW "-O2"
    OPT_GLOBAL "-O2"
    VERILATOR_ARGS
        --cc --sv --Wall -Wno-fatal
        -O3 --x-assign fast --x-initial fast --no-timing
)
