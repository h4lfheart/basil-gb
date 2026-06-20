#include "debug_ui.h"

#include <cstring>
#include <Vgameboy_ppu.h>
#include <Vgameboy_cpu.h>
#include <Vgameboy_gameboy.h>
#include <Vgameboy_mem_vram.h>

static uint32_t abgr(uint32_t rgba) {
    uint8_t r = (rgba >> 24) & 0xFF;
    uint8_t g = (rgba >> 16) & 0xFF;
    uint8_t b = (rgba >> 8) & 0xFF;
    uint8_t a = rgba & 0xFF;
    return (a << 24) | (b << 16) | (g << 8) | r;
}

bool DebugUI::init(const char* title, int w, int h) {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    window = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w, h,
        SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    if (!window) return false;

    gl_ctx = SDL_GL_CreateContext(window);
    SDL_GL_MakeCurrent(window, gl_ctx);
    SDL_GL_SetSwapInterval(1);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::GetIO().IniFilename = nullptr;
    ImGui::GetIO().LogFilename = nullptr;
    ImGui_ImplSDL2_InitForOpenGL(window, gl_ctx);
    ImGui_ImplOpenGL3_Init("#version 330 core");

    apply_theme();

    glGenTextures(1, &tile_tex);
    glGenTextures(1, &map0_tex);
    glGenTextures(1, &map1_tex);

    auto setup_tex = [](GLuint t, int w, int h) {
        glBindTexture(GL_TEXTURE_2D, t);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    };

    setup_tex(tile_tex, TILE_ATLAS_W, TILE_ATLAS_H);
    setup_tex(map0_tex, MAP_PX, MAP_PX);
    setup_tex(map1_tex, MAP_PX, MAP_PX);

    return true;
}

void DebugUI::shutdown() {
    glDeleteTextures(1, &tile_tex);
    glDeleteTextures(1, &map0_tex);
    glDeleteTextures(1, &map1_tex);

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();

    SDL_GL_DeleteContext(gl_ctx);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

bool DebugUI::poll_events() {
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        ImGui_ImplSDL2_ProcessEvent(&e);
        if (e.type == SDL_QUIT) return false;
        if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_ESCAPE) return false;
    }
    return true;
}

void DebugUI::update_textures(const Simulation& sim) {
    uint8_t vram[0x2000];
    for (int i = 0; i < 0x2000; i++)
        vram[i] = sim.gb->gameboy->vram->vram[i];

    uint8_t lcdc_raw = sim.gb->gameboy->ppu->LCDC;
    bool signed_addr = !(lcdc_raw & 0x10);

    uint32_t tile_pixels[TILE_ATLAS_W * TILE_ATLAS_H];
    build_tile_atlas(vram, tile_pixels);
    upload_rgba(tile_tex, TILE_ATLAS_W, TILE_ATLAS_H, tile_pixels);

    uint32_t map0_pixels[MAP_PX * MAP_PX];
    build_tilemap(vram, false, signed_addr, map0_pixels);
    upload_rgba(map0_tex, MAP_PX, MAP_PX, map0_pixels);

    uint32_t map1_pixels[MAP_PX * MAP_PX];
    build_tilemap(vram, true, signed_addr, map1_pixels);
    upload_rgba(map1_tex, MAP_PX, MAP_PX, map1_pixels);
}

void DebugUI::render(const Simulation& sim) {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame();
    ImGui::NewFrame();
    
    ImGui::SetNextWindowPos({8, 8}, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize({260, 0}, ImGuiCond_Always);
    if (ImGui::Begin("CPU", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::Text("PC  $%04X", sim.gb->gameboy->cpu->PC);
        ImGui::Text("IR  $%02X", sim.gb->gameboy->cpu->IR);
        ImGui::Separator();
        ImGui::Text("IME %d", sim.gb->gameboy->cpu->IME);
        ImGui::Text("IE  %s", std::bitset<8>(sim.gb->gameboy->cpu->IE).to_string().c_str());
        ImGui::Text("IF  %s",  std::bitset<8>(sim.gb->gameboy->cpu->IF).to_string().c_str());
        ImGui::Separator();
        if (paused) {
            if (ImGui::Button("Resume")) paused = false;
            ImGui::SameLine();
            if (ImGui::Button("Step M-Cycle")) step_mcycle = true;
        } else {
            if (ImGui::Button("Pause")) paused = true;
        }
    }
    ImGui::End();

    ImGui::SetNextWindowPos({8, 164}, ImGuiCond_FirstUseEver);
    if (ImGui::Begin("Tile Data")) {
        ImGui::Image((ImTextureID)(intptr_t)tile_tex, {(float)TILE_ATLAS_W, (float)TILE_ATLAS_H});
    }
    ImGui::End();

    ImGui::SetNextWindowPos({8 + TILE_ATLAS_W + 24, 164}, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize({(float)MAP_PX + 16, 0}, ImGuiCond_Always);
    if (ImGui::Begin("Tilemap $9800", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::Image((ImTextureID)(intptr_t)map0_tex, {(float)MAP_PX, (float)MAP_PX});
    }
    ImGui::End();

    ImGui::SetNextWindowPos({8 + TILE_ATLAS_W + 24 + MAP_PX + 24, 164}, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize({(float)MAP_PX + 16, 0}, ImGuiCond_Always);
    if (ImGui::Begin("Tilemap $9C00", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::Image((ImTextureID)(intptr_t)map1_tex, {(float)MAP_PX, (float)MAP_PX});
    }
    ImGui::End();

    ImGui::SetNextWindowPos({8 + TILE_ATLAS_W + 24 + MAP_PX + 24 + MAP_PX + 24, 164}, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize({260, 160}, ImGuiCond_FirstUseEver);
    if (ImGui::Begin("Serial Output")) {
        std::string display;
        display.reserve(serial_buffer.size());
        for (unsigned char ch : serial_buffer) {
            if (ch == '\n' || ch == '\r' || ch == '\t') {
                display += static_cast<char>(ch);
            } else if (ch >= 0x20 && ch < 0x7F) {
                display += static_cast<char>(ch);
            }
        }

         if (display.empty()) {
            ImGui::TextDisabled("(no output yet)");
        } else {
            ImGui::TextWrapped("%s", display.c_str());
        }

        if (serial_dirty) {
            ImGui::SetScrollHereY(1.0f);
            serial_dirty = false;
        }
    }
    ImGui::End();

    ImGui::Render();

    int dw, dh;
    SDL_GetWindowSize(window, &dw, &dh);
    glViewport(0, 0, dw, dh);
    glClearColor(0.08f, 0.09f, 0.10f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    SDL_GL_SwapWindow(window);
}

void DebugUI::apply_theme() {
    ImGuiStyle& s = ImGui::GetStyle();
    s.WindowRounding = 4.0f;
    s.FrameRounding = 3.0f;
    s.GrabRounding = 3.0f;
    s.WindowBorderSize = 1.0f;
    s.FrameBorderSize = 0.0f;
    s.WindowPadding = {8, 8};
    s.FramePadding = {6, 3};
    s.ItemSpacing = {6, 4};
    s.CellPadding = {4, 2};

    ImVec4* c = s.Colors;
    c[ImGuiCol_WindowBg] = {0.10f, 0.11f, 0.12f, 1.0f};
    c[ImGuiCol_ChildBg] = {0.10f, 0.11f, 0.12f, 1.0f};
    c[ImGuiCol_PopupBg] = {0.12f, 0.13f, 0.14f, 1.0f};
    c[ImGuiCol_Border] = {0.25f, 0.27f, 0.30f, 1.0f};
    c[ImGuiCol_FrameBg] = {0.18f, 0.20f, 0.22f, 1.0f};
    c[ImGuiCol_FrameBgHovered] = {0.22f, 0.24f, 0.27f, 1.0f};
    c[ImGuiCol_FrameBgActive] = {0.26f, 0.28f, 0.32f, 1.0f};
    c[ImGuiCol_TitleBg] = {0.08f, 0.09f, 0.10f, 1.0f};
    c[ImGuiCol_TitleBgActive] = {0.08f, 0.09f, 0.10f, 1.0f};
    c[ImGuiCol_TitleBgCollapsed] = {0.08f, 0.09f, 0.10f, 1.0f};
    c[ImGuiCol_ScrollbarBg] = {0.08f, 0.09f, 0.10f, 1.0f};
    c[ImGuiCol_ScrollbarGrab] = {0.30f, 0.40f, 0.32f, 1.0f};
    c[ImGuiCol_ScrollbarGrabHovered] = {0.38f, 0.50f, 0.40f, 1.0f};
    c[ImGuiCol_ScrollbarGrabActive] = {0.46f, 0.60f, 0.48f, 1.0f};
    c[ImGuiCol_CheckMark] = {0.46f, 0.72f, 0.50f, 1.0f};
    c[ImGuiCol_SliderGrab] = {0.36f, 0.58f, 0.40f, 1.0f};
    c[ImGuiCol_SliderGrabActive] = {0.46f, 0.70f, 0.50f, 1.0f};
    c[ImGuiCol_Button] = {0.22f, 0.32f, 0.24f, 1.0f};
    c[ImGuiCol_ButtonHovered] = {0.30f, 0.44f, 0.33f, 1.0f};
    c[ImGuiCol_ButtonActive] = {0.38f, 0.56f, 0.42f, 1.0f};
    c[ImGuiCol_Header] = {0.22f, 0.32f, 0.24f, 1.0f};
    c[ImGuiCol_HeaderHovered] = {0.28f, 0.42f, 0.31f, 1.0f};
    c[ImGuiCol_HeaderActive] = {0.34f, 0.52f, 0.38f, 1.0f};
    c[ImGuiCol_Separator] = {0.25f, 0.27f, 0.30f, 1.0f};
    c[ImGuiCol_Text] = {0.88f, 0.91f, 0.86f, 1.0f};
    c[ImGuiCol_TextDisabled] = {0.45f, 0.48f, 0.44f, 1.0f};
    c[ImGuiCol_Tab] = {0.14f, 0.18f, 0.15f, 1.0f};
    c[ImGuiCol_TabHovered] = {0.30f, 0.44f, 0.33f, 1.0f};
    c[ImGuiCol_TabActive] = {0.28f, 0.48f, 0.32f, 1.0f};
}

void DebugUI::upload_rgba(GLuint tex, int w, int h, const uint32_t* pixels) {
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
}

uint32_t DebugUI::dmg_color(uint8_t index) const {
    return abgr(PALETTE[index & 3]);
}

void DebugUI::decode_tile(const uint8_t* vram, int tile_id, uint32_t* out, int atlas_w) const {
    int tile_col = tile_id % TILES_PER_ROW;
    int tile_row = tile_id / TILES_PER_ROW;
    int base_x = tile_col * 8;
    int base_y = tile_row * 8;

    for (int row = 0; row < 8; row++) {
        int addr = tile_id * 16 + row * 2;
        uint8_t lo = vram[addr];
        uint8_t hi = vram[addr + 1];
        for (int bit = 7; bit >= 0; bit--) {
            int col_index = ((hi >> bit) & 1) << 1 | ((lo >> bit) & 1);
            int px = base_x + (7 - bit);
            int py = base_y + row;
            out[py * atlas_w + px] = dmg_color(col_index);
        }
    }
}

void DebugUI::build_tile_atlas(const uint8_t* vram, uint32_t* pixels) const {
    for (int i = 0; i < TILE_COUNT; i++)
        decode_tile(vram, i, pixels, TILE_ATLAS_W);
}

void DebugUI::build_tilemap(const uint8_t* vram, bool use_9c00, bool signed_addr, uint32_t* pixels) const {
    int map_base = use_9c00 ? 0x1C00 : 0x1800;

    for (int ty = 0; ty < 32; ty++) {
        for (int tx = 0; tx < 32; tx++) {
            uint8_t tile_id_raw = vram[map_base + ty * 32 + tx];

            int tile_id;
            if (signed_addr) {
                tile_id = 256 + static_cast<int8_t>(tile_id_raw);
            } else {
                tile_id = tile_id_raw;
            }

            for (int row = 0; row < 8; row++) {
                int addr = tile_id * 16 + row * 2;
                uint8_t lo = vram[addr];
                uint8_t hi = vram[addr + 1];
                for (int bit = 7; bit >= 0; bit--) {
                    int col_index = ((hi >> bit) & 1) << 1 | ((lo >> bit) & 1);
                    int px = tx * 8 + (7 - bit);
                    int py = ty * 8 + row;
                    pixels[py * MAP_PX + px] = dmg_color(col_index);
                }
            }
        }
    }
}