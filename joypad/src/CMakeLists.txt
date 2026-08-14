idf_component_register(SRCS "main.cpp" "gamepad/usb_joypad.cpp" "gamepad/spi_joypad.cpp"
                       INCLUDE_DIRS "."
                       REQUIRES usb usb_host_hid driver)
