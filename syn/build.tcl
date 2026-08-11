set here [file dirname [file normalize [info script]]]
cd $here

set_device -device_version C GW2AR-LV18QN88C8/I7

add_file src/gw_ide_define.sv
add_file src/pll/TMDS_rPLL.v
add_file src/pll/SDRAM_rPLL.v
add_file src/mem/sdram_bus.sv
add_file src/mem/spi_flash_bus.sv
add_file src/mem/sdram.v
add_file src/mem/spi_flash_read.sv
add_file src/mem/rom_loader.sv
add_file src/mem/sdram_bridge.sv
add_file src/video/gb_scaler.sv
add_file src/audio_cdc.sv

add_file external/hdmi/src/tmds_channel.sv
add_file external/hdmi/src/packet_assembler.sv
add_file external/hdmi/src/audio_clock_regeneration_packet.sv
add_file external/hdmi/src/audio_sample_packet.sv
add_file external/hdmi/src/audio_info_frame.sv
add_file external/hdmi/src/auxiliary_video_information_info_frame.sv
add_file external/hdmi/src/source_product_description_info_frame.sv
add_file external/hdmi/src/packet_picker.sv
add_file external/hdmi/src/serializer.sv
add_file external/hdmi/src/hdmi.sv

add_file ../rtl/util/edge_detect.sv
add_file ../rtl/bus.sv
add_file ../rtl/ext/cart_ext_mem.sv
add_file ../rtl/ext/wram_ext_mem.sv
add_file ../rtl/ext/fb_rd_bus.sv
add_file ../rtl/cart/cart_types.sv
add_file ../rtl/gameboy/cpu/cpu_types.sv
add_file ../rtl/gameboy/ppu/ppu_types.sv
add_file ../rtl/gameboy/mem/mem_types.sv
add_file ../rtl/gameboy/apu/apu_types.sv
add_file ../rtl/gameboy/io/joypad.sv
add_file ../rtl/cart/mbc0.sv
add_file ../rtl/cart/mbc1.sv
add_file ../rtl/cart/mbc3.sv
add_file ../rtl/cart/mbc5.sv
add_file ../rtl/cart/cart.sv
add_file ../rtl/gameboy/cpu/cpu_bus_controller.sv
add_file ../rtl/gameboy/cpu/cpu_regfile.sv
add_file ../rtl/gameboy/cpu/cpu_alu.sv
add_file ../rtl/gameboy/cpu/cpu_idu.sv
add_file ../rtl/gameboy/cpu/cpu_control.sv
add_file ../rtl/gameboy/cpu/cpu_clock.sv
add_file ../rtl/gameboy/cpu/cpu.sv
add_file ../rtl/gameboy/io/serial.sv
add_file ../rtl/gameboy/timer/timer.sv
add_file ../rtl/gameboy/apu/components/apu_length.sv
add_file ../rtl/gameboy/apu/components/apu_envelope.sv
add_file ../rtl/gameboy/apu/components/apu_freq_timer.sv
add_file ../rtl/gameboy/apu/components/apu_duty.sv
add_file ../rtl/gameboy/apu/components/apu_sweep.sv
add_file ../rtl/gameboy/apu/components/apu_lfsr.sv
add_file ../rtl/gameboy/apu/components/apu_highpass.sv
add_file ../rtl/gameboy/apu/apu_ch1.sv
add_file ../rtl/gameboy/apu/apu_ch2.sv
add_file ../rtl/gameboy/apu/apu_ch3.sv
add_file ../rtl/gameboy/apu/apu_ch4.sv
add_file ../rtl/gameboy/apu/apu.sv
add_file ../rtl/gameboy/ppu/oam_ppu_bus.sv
add_file ../rtl/gameboy/ppu/vram_ppu_bus.sv
add_file ../rtl/gameboy/ppu/ppu_fifo.sv
add_file ../rtl/gameboy/ppu/ppu_bg_win_fetcher.sv
add_file ../rtl/gameboy/ppu/ppu_oam_scan.sv
add_file ../rtl/gameboy/ppu/ppu_obj_fetcher.sv
add_file ../rtl/gameboy/ppu/ppu_shifter.sv
add_file ../rtl/gameboy/ppu/ppu_state.sv
add_file ../rtl/gameboy/ppu/ppu.sv
add_file ../rtl/gameboy/mem/mem_boot_rom.sv
add_file ../rtl/gameboy/mem/mem_hram.sv
add_file ../rtl/gameboy/mem/mem_vram.sv
add_file ../rtl/gameboy/mem/mem_wram.sv
add_file ../rtl/gameboy/mem/mem_oam.sv
add_file ../rtl/gameboy/mem/dma/oam_dma.sv
add_file ../rtl/gameboy/mem/dma/vdma.sv
add_file ../rtl/gameboy/mem/mmu.sv
add_file ../rtl/gameboy/gameboy.sv
add_file ../rtl/console.sv
add_file src/top.sv

add_file src/constr/tang_nano_20k.cst
add_file src/constr/tang_nano_20k.sdc

set_option -top_module top
set_option -verilog_std sysv2017
set_option -output_base_name basil_gb
set_option -rw_check_on_ram 1
set_option -use_mspi_as_gpio 1

run all
