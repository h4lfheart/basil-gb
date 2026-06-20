#include "runner.h"

#include <iostream>
#include <sstream>
#include <filesystem>
#include <vector>
#include <chrono>
#include <thread>
#include <atomic>
#include <memory>

#include "verilated_vcd_c.h"
#include "../sim/sim.h"
#include "../colors.h"

namespace fs = std::filesystem;

TestResult run_rom(const std::string& bootrom_path, const std::string& rom_path, const TestSuite& suite, const std::string& trace_path, uint64_t trace_start) {
    serial_buffer.clear();
    serial_dirty = false;

    Simulation sim;
    sim.load_bootrom(bootrom_path);
    sim.load_rom(rom_path);

    std::unique_ptr<VerilatedVcdC> vcd;
    if (!trace_path.empty()) {
        vcd = std::make_unique<VerilatedVcdC>();
        sim.open_trace(trace_path, *vcd);
    }

    sim.reset(vcd.get(), trace_start);

    TestResult result = TestResult::Failed;
    while (!sim.finished()) {
        sim.clock_cycle(vcd.get(), trace_start);
        if (serial_dirty) {
            serial_dirty = false;
            switch (suite.detect(serial_buffer)) {
                case TestStatus::Passed: result = TestResult::Passed; goto done;
                case TestStatus::Failed: result = TestResult::Failed; goto done;
                default: break;
            }
        }
        
    }

done:
    if (vcd) vcd->close();
    return result;
}

static TestResult run_rom_with_status(const std::string& bootrom_path, const std::string& rom_path, const std::string& name, const TestSuite& suite, double& elapsed_out, const std::string& trace_path, uint64_t trace_start) {
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

    auto result = run_rom(bootrom_path, rom_path, suite, trace_path, trace_start);

    running.store(false);
    timer.join();

    elapsed_out = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();

    std::cout << "\r\033[K";
    return result;
}

int run_suite(const std::string& bootrom_path, const std::string& test_dir, const std::string& suite_name, const TestSuite& suite, const std::string& trace_dir, uint64_t trace_start) {
    serial_echo = false;

    if (!trace_dir.empty())
        fs::create_directories(trace_dir);

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

        std::string trace_path;
        if (!trace_dir.empty())
            trace_path = (fs::path(trace_dir) / (p.stem().string() + ".vcd")).string();

        double elapsed = 0.0;
        auto result = run_rom_with_status(bootrom_path, p.string(), name, suite, elapsed, trace_path, trace_start);

        char elapsed_str[32];
        std::snprintf(elapsed_str, sizeof(elapsed_str), "%.3fs", elapsed);

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

int run_single(const std::string& bootrom_path, const std::string& rom_path, const std::string& suite_name, const TestSuite& suite, const std::string& trace_dir, uint64_t trace_start) {
    serial_echo = false;

    const std::string name = fs::path(rom_path).filename().string();

    std::string trace_path;
    if (!trace_dir.empty()) {
        fs::create_directories(trace_dir);
        trace_path = (fs::path(trace_dir) / (fs::path(rom_path).stem().string() + ".vcd")).string();
    }

    std::cout << Colors::bold
              << "Running " << suite_name << " test " << name
              << Colors::reset << "\n\n";

    double elapsed = 0.0;
    auto result = run_rom_with_status(bootrom_path, rom_path, name, suite, elapsed, trace_path, trace_start);

    char elapsed_str[32];
    std::snprintf(elapsed_str, sizeof(elapsed_str), "%.3fs", elapsed);

    if (result == TestResult::Passed) {
        std::cout << Colors::bold << Colors::green << "PASS"
                  << Colors::reset
                  << Colors::gray << " [" << elapsed_str << "] "
                  << Colors::reset << name << "\n";
        return 0;
    }

    std::cout << Colors::bold << Colors::red << "FAIL"
              << Colors::reset
              << Colors::gray << " [" << elapsed_str << "] "
              << Colors::reset << name << "\n";

    for (const auto& line : suite.extract_failure_info(serial_buffer))
        std::cout << Colors::gray << "  " << line << Colors::reset << "\n";

    return 1;
}