#pragma once

#include <cstdint>
#include <string>
#include "suites/test_suite.h"

enum class TestResult { Passed, Failed };

TestResult run_rom(const std::string& bootrom_path, const std::string& rom_path, const TestSuite& suite, const std::string& trace_path = "", uint64_t trace_start = 0);

int run_suite(const std::string& bootrom_path, const std::string& test_dir, const std::string& suite_name, const TestSuite& suite, const std::string& trace_dir = "", uint64_t trace_start = 0);

int run_single(const std::string& bootrom_path, const std::string& rom_path, const std::string& suite_name, const TestSuite& suite, const std::string& trace_dir = "", uint64_t trace_start = 0);