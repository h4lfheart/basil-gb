#pragma once

#include <SDL.h>
#include <SDL_opengl.h>
#include <cstdint>

#include "imgui.h"
#include "imgui_impl_sdl2.h"
#include "imgui_impl_opengl3.h"

#include "../sim/sim.h"

struct JoypadState {
    bool up = false;
    bool down = false;
    bool left = false;
    bool right = false;
    bool a = false;
    bool b = false;
    bool start = false;
    bool select = false;
};

struct DebugUI {
    SDL_Window* window = nullptr;
    SDL_GLContext gl_ctx = nullptr;

    GLuint lcd_tex = 0;
    GLuint tile_tex = 0;
    GLuint map0_tex = 0;
    GLuint map1_tex = 0;

    bool paused = false;
    bool step_mcycle = false;

    JoypadState joypad;

    static constexpr int LCD_W = 160;
    static constexpr int LCD_H = 144;

    static constexpr int TILE_COUNT = 384;
    static constexpr int TILES_PER_ROW = 16;
    static constexpr int TILE_ROWS = TILE_COUNT / TILES_PER_ROW;
    static constexpr int TILE_ATLAS_W = TILES_PER_ROW * 8;
    static constexpr int TILE_ATLAS_H = TILE_ROWS * 8;

    static constexpr int MAP_TILES = 32;
    static constexpr int MAP_PX = MAP_TILES * 8;

    static constexpr uint32_t PALETTE[4] = {
        0xe5e8c9FF, 0xb8cc94FF, 0x759b62FF, 0x3e5b34FF
    };

    bool init(const char* title, int w, int h);
    void shutdown();

    bool poll_events(Simulation& sim);
    void update_textures(const Simulation& sim);
    void render(const Simulation& sim);

private:
    void apply_theme();
    void upload_rgba(GLuint tex, int w, int h, const uint32_t* pixels);
    uint32_t dmg_color(uint8_t index) const;
    void decode_tile(const uint8_t* vram, int tile_id, uint32_t* out, int atlas_w) const;
    void build_tile_atlas(const uint8_t* vram, uint32_t* pixels) const;
    void build_tilemap(const uint8_t* vram, bool use_9c00, bool signed_addr, uint32_t* pixels) const;
    void build_lcd(const uint8_t* framebuffer, uint32_t* pixels) const;
};