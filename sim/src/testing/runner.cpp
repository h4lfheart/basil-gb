#include "runner.h"

#include <iostream>
#include <filesystem>
#include <vector>
#include <chrono>
#include <thread>
#include <atomic>
#include <memory>
#include <mutex>
#include <queue>
#include <algorithm>
#include <cstdio>

#include "verilated_vcd_c.h"
#include "../sim/sim.h"
#include "../colors.h"

namespace fs = std::filesystem;

TestRuntimeInfo run_rom(const std::string& bootrom_path, const std::string& rom_path, const TestSuite& suite, const std::string& trace_path, uint64_t trace_start, double timeout_seconds) {
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

    const auto t0 = std::chrono::steady_clock::now();
    TestRuntimeInfo outcome;
    outcome.result = TestResult::Failed;
    while (!sim.finished()) {
        if (timeout_seconds > 0.0) {
            const double elapsed = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
            if (elapsed >= timeout_seconds) {
                outcome.result = TestResult::Skipped;
                break;
            }
        }

        sim.clock_cycle(vcd.get(), trace_start);
        if (serial_dirty) {
            serial_dirty = false;
            switch (suite.detect(serial_buffer)) {
                case TestStatus::Passed: outcome.result = TestResult::Passed; goto done;
                case TestStatus::Failed: outcome.result = TestResult::Failed; goto done;
                default: break;
            }
        }
    }

done:
    if (vcd) vcd->close();
    outcome.serial_output = serial_buffer;
    outcome.elapsed_seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    return outcome;
}

static TestRuntimeInfo run_rom_with_status(const std::string& bootrom_path, const std::string& rom_path, const std::string& name, const TestSuite& suite, const std::string& trace_path, uint64_t trace_start, double timeout_seconds) {
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

    auto outcome = run_rom(bootrom_path, rom_path, suite, trace_path, trace_start, timeout_seconds);

    running.store(false);
    timer.join();

    outcome.elapsed_seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();

    std::cout << "\r\033[K";
    return outcome;
}

struct PendingTest {
    std::string rom_path;
    std::string name;
    std::string trace_path;
};

struct ActiveTest {
    bool running = false;
    std::string name;
    std::chrono::steady_clock::time_point start;
};

[[noreturn]] static void park_until_process_exit() {
    while (true) std::this_thread::sleep_for(std::chrono::hours(24));
}

static std::vector<std::string> build_running_lines(const std::vector<ActiveTest>& active_tests) {
    std::vector<std::string> lines;
    for (const auto& active : active_tests) {
        if (!active.running)
            continue;

        const double elapsed = std::chrono::duration<double>(
            std::chrono::steady_clock::now() - active.start).count();
        char elapsed_str[32];
        std::snprintf(elapsed_str, sizeof(elapsed_str), "%.3fs", elapsed);
        lines.push_back(std::string(Colors::bold) + Colors::yellow + "RUNNING" +
                        Colors::reset + Colors::gray + " [" + elapsed_str + "] " +
                        Colors::reset + active.name);
    }
    return lines;
}

static size_t render_frame(size_t prev_status_lines,
                           const std::vector<std::string>& permanent,
                           const std::vector<std::string>& status) {
    std::string frame;
    if (prev_status_lines > 0)
        frame += "\033[" + std::to_string(prev_status_lines) + "A";
    frame += "\r";

    for (const auto& line : permanent)
        frame += line + "\033[K\n";
    for (const auto& line : status)
        frame += line + "\033[K\n";

    frame += "\033[J";

    std::cout << frame << std::flush;
    return status.size();
}

static std::vector<std::string> format_test_result(const std::string& name, const TestRuntimeInfo& outcome, const TestSuite& suite,
                                                    std::vector<std::string>& passed_roms,
                                                    std::vector<std::string>& failed_roms,
                                                    std::vector<std::string>& skipped_roms) {
    char elapsed_str[32];
    std::snprintf(elapsed_str, sizeof(elapsed_str), "%.3fs", outcome.elapsed_seconds);

    std::vector<std::string> lines;
    if (outcome.result == TestResult::Passed) {
        passed_roms.push_back(name);
        lines.push_back(std::string(Colors::bold) + Colors::green + "PASS" +
                        Colors::reset + Colors::gray + " [" + elapsed_str + "] " +
                        Colors::reset + name);
    } else if (outcome.result == TestResult::Skipped) {
        skipped_roms.push_back(name);
        lines.push_back(std::string(Colors::bold) + Colors::yellow + "SKIP" +
                        Colors::reset + Colors::gray + " [" + elapsed_str + "] " +
                        Colors::reset + name);
    } else {
        failed_roms.push_back(name);
        lines.push_back(std::string(Colors::bold) + Colors::red + "FAIL" +
                        Colors::reset + Colors::gray + " [" + elapsed_str + "] " +
                        Colors::reset + name);

        for (const auto& line : suite.extract_failure_info(outcome.serial_output))
            lines.push_back(std::string(Colors::gray) + "  " + line + Colors::reset);
    }
    return lines;
}

static void print_test_result(const std::string& name, const TestRuntimeInfo& outcome, const TestSuite& suite,
                              std::vector<std::string>& passed_roms,
                              std::vector<std::string>& failed_roms,
                              std::vector<std::string>& skipped_roms) {
    for (const auto& line : format_test_result(name, outcome, suite, passed_roms, failed_roms, skipped_roms))
        std::cout << line << "\n";
}

static void print_summary(double total_elapsed,
                          const std::vector<std::string>& passed_roms,
                          const std::vector<std::string>& failed_roms,
                          const std::vector<std::string>& skipped_roms) {
    char total_str[32];
    std::snprintf(total_str, sizeof(total_str), "%.3fs", total_elapsed);

    int total = static_cast<int>(passed_roms.size() + failed_roms.size() + skipped_roms.size());
    std::cout << "\n"
              << Colors::bold << Colors::cyan << "SUMMARY"
              << Colors::reset
              << Colors::gray << " [" << total_str << "] "
              << Colors::reset
              << total << " tests run, "
              << Colors::green << passed_roms.size() << " passed" << Colors::reset << ", "
              << (failed_roms.empty() ? Colors::gray : Colors::red)
              << failed_roms.size() << " failed" << Colors::reset << ", "
              << (skipped_roms.empty() ? Colors::gray : Colors::yellow)
              << skipped_roms.size() << " skipped" << Colors::reset << "\n";
}

static int run_pending_tests(const std::string& bootrom_path,
                             const std::vector<PendingTest>& tests,
                             const TestSuite& suite,
                             uint64_t trace_start,
                             double timeout_seconds,
                             unsigned test_threads,
                             bool print_summary_line) {
    std::vector<std::string> passed_roms;
    std::vector<std::string> failed_roms;
    std::vector<std::string> skipped_roms;
    auto suite_start = std::chrono::steady_clock::now();

    if (test_threads <= 1) {
        for (const auto& test : tests) {
            auto outcome = run_rom_with_status(bootrom_path, test.rom_path, test.name, suite, test.trace_path, trace_start, timeout_seconds);
            print_test_result(test.name, outcome, suite, passed_roms, failed_roms, skipped_roms);
        }
    } else {
        std::mutex queue_mutex;
        std::mutex display_mutex;
        std::queue<size_t> pending;
        for (size_t i = 0; i < tests.size(); i++)
            pending.push(i);

        const unsigned worker_count = std::min(test_threads, static_cast<unsigned>(std::max<size_t>(tests.size(), 1)));
        std::vector<ActiveTest> active_tests(worker_count);
        size_t rendered_lines = 0;
        std::atomic<bool> workers_running(true);

        std::mutex done_mutex;
        std::condition_variable done_cv;
        size_t completed = 0;

        std::thread status_timer([&]() {
            while (workers_running.load()) {
                {
                    std::lock_guard<std::mutex> lock(display_mutex);
                    rendered_lines = render_frame(rendered_lines, {}, build_running_lines(active_tests));
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
        });

        for (unsigned w = 0; w < worker_count; w++) {
            std::thread worker([&, w]() {
                while (true) {
                    size_t index;
                    {
                        std::lock_guard<std::mutex> lock(queue_mutex);
                        if (pending.empty())
                            break;
                        index = pending.front();
                        pending.pop();
                    }

                    const auto& test = tests[index];
                    const auto start = std::chrono::steady_clock::now();
                    {
                        std::lock_guard<std::mutex> lock(display_mutex);
                        active_tests[w] = {true, test.name, start};
                        rendered_lines = render_frame(rendered_lines, {}, build_running_lines(active_tests));
                    }

                    auto outcome = run_rom(bootrom_path, test.rom_path, suite, test.trace_path, trace_start, timeout_seconds);
                    outcome.elapsed_seconds = std::chrono::duration<double>(
                        std::chrono::steady_clock::now() - start).count();

                    {
                        std::lock_guard<std::mutex> lock(display_mutex);
                        active_tests[w].running = false;
                        auto result_lines = format_test_result(test.name, outcome, suite, passed_roms, failed_roms, skipped_roms);
                        rendered_lines = render_frame(rendered_lines, result_lines, build_running_lines(active_tests));
                    }

                    {
                        std::lock_guard<std::mutex> lock(done_mutex);
                        ++completed;
                    }
                    done_cv.notify_one();
                }

                park_until_process_exit();
            });
            worker.detach();
        }

        {
            std::unique_lock<std::mutex> lock(done_mutex);
            done_cv.wait(lock, [&]() { return completed == tests.size(); });
        }

        workers_running.store(false);
        status_timer.join();
        {
            std::lock_guard<std::mutex> lock(display_mutex);
            if (rendered_lines > 0)
                std::cout << "\033[" << rendered_lines << "A\r\033[J" << std::flush;
        }
    }

    if (print_summary_line) {
        double total_elapsed = std::chrono::duration<double>(std::chrono::steady_clock::now() - suite_start).count();
        print_summary(total_elapsed, passed_roms, failed_roms, skipped_roms);
    }

    return failed_roms.empty() ? 0 : 1;
}

int run_suite(const std::string& bootrom_path, const std::string& test_dir, const std::string& suite_name, const TestSuite& suite, const std::string& trace_dir, uint64_t trace_start, double timeout_seconds, unsigned test_threads) {
    serial_echo = false;

    if (!trace_dir.empty())
        fs::create_directories(trace_dir);

    std::cout << Colors::bold
              << "Running " << suite_name << " tests in " << test_dir
              << Colors::reset << "\n\n";

    std::vector<PendingTest> tests;
    const fs::path test_root(test_dir);
    for (const auto& entry : fs::recursive_directory_iterator(test_root)) {
        const auto& p = entry.path();
        if (!entry.is_regular_file()) continue;
        if (p.extension() != ".gb" && p.extension() != ".gbc") continue;

        const fs::path relative_path = p.lexically_relative(test_root);
        PendingTest test;
        test.rom_path = p.string();
        test.name = relative_path.generic_string();

        if (!trace_dir.empty()) {
            fs::path relative_trace_path = relative_path;
            relative_trace_path.replace_extension(".vcd");
            const fs::path output_path = fs::path(trace_dir) / relative_trace_path;
            fs::create_directories(output_path.parent_path());
            test.trace_path = output_path.string();
        }

        tests.push_back(std::move(test));
    }

    return run_pending_tests(bootrom_path, tests, suite, trace_start, timeout_seconds, test_threads, true);
}

int run_files(const std::string& bootrom_path, const std::vector<std::string>& rom_paths, const std::string& suite_name, const TestSuite& suite, const std::string& trace_dir, uint64_t trace_start, double timeout_seconds, unsigned test_threads) {
    serial_echo = false;

    if (!trace_dir.empty())
        fs::create_directories(trace_dir);

    if (rom_paths.size() == 1) {
        std::cout << Colors::bold
                  << "Running " << suite_name << " test " << fs::path(rom_paths[0]).filename().string()
                  << Colors::reset << "\n\n";
    } else {
        std::cout << Colors::bold
                  << "Running " << suite_name << " tests (" << rom_paths.size() << " files)"
                  << Colors::reset << "\n\n";
    }

    std::vector<PendingTest> tests;
    tests.reserve(rom_paths.size());
    for (const auto& rom_path : rom_paths) {
        PendingTest test;
        test.rom_path = rom_path;
        test.name = fs::path(rom_path).filename().string();
        if (!trace_dir.empty())
            test.trace_path = (fs::path(trace_dir) / (fs::path(rom_path).stem().string() + ".vcd")).string();
        tests.push_back(std::move(test));
    }

    return run_pending_tests(bootrom_path, tests, suite, trace_start, timeout_seconds, test_threads, rom_paths.size() > 1);
}
