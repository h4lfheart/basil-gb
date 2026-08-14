#include "gamepad/spi_joypad.hpp"
#include "gamepad/usb_joypad.hpp"

extern "C" void app_main()
{
    spi_joypad::init();
    usb_joypad::init();
}
