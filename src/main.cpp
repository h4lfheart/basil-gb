#include <iostream>
#include <memory>
#include <string>

#include "verilated_vcd_c.h"
#include "argparse/argparse.hpp"

#include "sim/sim.h"
#include "testing/runner.h"
#include "testing/suites/blargg.h"

int main(int argc, char **argv) {
    argparse::ArgumentParser arguments("basil-gb");

    arguments.add_argument("bootrom")
        .help("Path to the Game Boy boot ROM.")
        .required();

    arguments.add_argument("rom")
        .help("Path to the Game Boy ROM (single-ROM mode).")
        .nargs(argparse::nargs_pattern::optional);

    arguments.add_argument("--test")
        .help("Test suite type: blargg");

    arguments.add_argument("--test-dir")
        .help("Directory of ROMs to run as a test suite (requires --test).");

    arguments.add_argument("--trace")
        .help("Path to write a VCD trace file (single-ROM mode only).");

    arguments.add_argument("--trace-start")
        .help("Cycle time at which to start tracing.")
        .scan<'u', uint64_t>()
        .default_value(static_cast<uint64_t>(0));

    try {
        arguments.parse_args(argc, argv);
    }
    catch (const std::exception& err) {
        std::cerr << err.what() << "\n" << arguments;
        return 1;
    }

    auto bootrom_path = arguments.get<std::string>("bootrom");
    auto test_type = arguments.present<std::string>("--test");
    auto test_dir  = arguments.present<std::string>("--test-dir");

    // ── Test suite mode ──────────────────────────────────────────────────────
    if (test_type || test_dir) {
        if (!test_type || !test_dir) {
            std::cerr << "Error: --test and --test-dir must be used together\n";
            return 1;
        }

        std::unique_ptr<TestSuite> suite;
        if (*test_type == "blargg")
            suite = std::make_unique<BlarggSuite>();
        else {
            std::cerr << "Error: unknown test suite '" << *test_type << "'\n";
            return 1;
        }

        return run_suite(bootrom_path, *test_dir, *test_type, *suite);
    }

    // ── Single ROM mode ──────────────────────────────────────────────────────
    auto rom_path_opt = arguments.present<std::string>("rom");
    if (!rom_path_opt) {
        std::cerr << "Error: a rom path is required when not using --test\n" << arguments;
        return 1;
    }

    Simulation sim;
    sim.load_bootrom(bootrom_path);
    sim.load_rom(*rom_path_opt);

    std::unique_ptr<VerilatedVcdC> vcd;
    if (auto trace_path = arguments.present<std::string>("--trace")) {
        vcd = std::make_unique<VerilatedVcdC>();
        sim.open_trace(*trace_path, *vcd);
    }

    auto trace_start = arguments.get<uint64_t>("--trace-start");

    sim.reset();

    while (!sim.finished())
        sim.clock_cycle(vcd.get(), trace_start);

    if (vcd)
        vcd->close();

    std::cout << "Elapsed cycles: " << sim.clk_time << "\n";
    return 0;
}