#include "runner.h"

#include <iostream>
#include <sstream>
#include <filesystem>
#include <vector>
#include <chrono>
#include <thread>
#include <atomic>

#include "../sim/sim.h"
#include "../colors.h"

namespace fs = std::filesystem;

TestResult run_rom(const std::string& bootrom_path, const std::string& rom_path, const TestSuite& suite) {
    serial_buffer.clear();
    serial_dirty = false;

    Simulation sim;
    sim.load_bootrom(bootrom_path);
    sim.load_rom(rom_path);
    sim.reset();

    while (!sim.finished()) {
        sim.clock_cycle();
        if (serial_dirty) {
            serial_dirty = false;
            switch (suite.detect(serial_buffer)) {
                case TestStatus::Passed: return TestResult::Passed;
                case TestStatus::Failed: return TestResult::Failed;
                default: break;
            }
        }
    }

    return TestResult::Failed;
}

int run_suite(const std::string& bootrom_path, const std::string& test_dir, const std::string& suite_name, const TestSuite& suite) {
    serial_echo = false;

    std::cout << Colors::bold
              << "Running " << suite_name << " tests in " << test_dir
              << Colors::reset << "\n\n";

    std::vector<std::string> passed_roms;
    std::vector<std::string> failed_roms;
    auto suite_start = std::chrono::steady_clock::now();

    for (const auto& entry : fs::directory_iterator(test_dir)) {
        const auto& p = entry.path();
        if (!entry.is_regular_file()) continue;
        if (p.extension() != ".gb" && p.extension() != ".gbc") continue;

        const std::string name = p.filename().string();

        std::atomic<bool> running(true);
        auto t0 = std::chrono::steady_clock::now();

        std::thread timer([&]() {
            while (running.load()) {
                double elapsed = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
                char elapsed_str[32];
                std::snprintf(elapsed_str, sizeof(elapsed_str), "%.3fs", elapsed);
                std::cout << "\r" << Colors::bold << Colors::yellow << "RUNNING"
                          << Colors::reset
                          << Colors::gray << " [" << elapsed_str << "] "
                          << Colors::reset << name << std::flush;
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
        });

        auto result = run_rom(bootrom_path, p.string(), suite);

        running.store(false);
        timer.join();

        double elapsed = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();

        char elapsed_str[32];
        std::snprintf(elapsed_str, sizeof(elapsed_str), "%.3fs", elapsed);

        std::cout << "\r";

        if (result == TestResult::Passed) {
            passed_roms.push_back(name);
            std::cout << Colors::bold << Colors::green << "PASS"
                      << Colors::reset
                      << Colors::gray << " [" << elapsed_str << "] "
                      << Colors::reset << name << "\n";
        } else {
            failed_roms.push_back(name);
            std::cout << Colors::bold << Colors::red << "FAIL"
                      << Colors::reset
                      << Colors::gray << " [" << elapsed_str << "] "
                      << Colors::reset << name << "\n";

            for (const auto& line : suite.extract_failure_info(serial_buffer))
                std::cout << Colors::gray << "  " << line << Colors::reset << "\n";
        }
    }

    double total_elapsed = std::chrono::duration<double>(std::chrono::steady_clock::now() - suite_start).count();
    char total_str[32];
    std::snprintf(total_str, sizeof(total_str), "%.3fs", total_elapsed);

    int total = static_cast<int>(passed_roms.size() + failed_roms.size());
    std::cout << "\n"
              << Colors::bold << Colors::cyan << "SUMMARY"
              << Colors::reset
              << Colors::gray << " [" << total_str << "] "
              << Colors::reset
              << total << " tests run, "
              << Colors::green << passed_roms.size() << " passed" << Colors::reset << ", "
              << (failed_roms.empty() ? Colors::gray : Colors::red)
              << failed_roms.size() << " failed" << Colors::reset << "\n";

    return failed_roms.empty() ? 0 : 1;
}