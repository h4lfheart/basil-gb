#pragma once

#include <string>
#include "suites/test_suite.h"

enum class TestResult { Passed, Failed };

TestResult run_rom(const std::string& bootrom_path, const std::string& rom_path, const TestSuite& suite);

int run_suite(const std::string& bootrom_path, const std::string& test_dir, const std::string& suite_name, const TestSuite& suite);