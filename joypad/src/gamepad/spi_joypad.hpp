#pragma once

#include <cstdint>

#define BUTTON_UP (1u << 7)
#define BUTTON_DOWN (1u << 6)
#define BUTTON_LEFT (1u << 5)
#define BUTTON_RIGHT (1u << 4)
#define BUTTON_A (1u << 3)
#define BUTTON_B (1u << 2)
#define BUTTON_START (1u << 1)
#define BUTTON_SELECT (1u << 0)

namespace spi_joypad {

    void init();
    void set_buttons(uint8_t buttons);

}
