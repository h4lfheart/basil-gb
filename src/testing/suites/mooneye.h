#pragma once

#include "test_suite.h"

struct MooneyeSuite : TestSuite {
    TestStatus detect(const std::string& serial) const override {
        static const std::string passed_bytes = "\x03\x05\x08\x0d\x15\x22";
        static const std::string failed_bytes = "\x42\x42\x42\x42\x42\x42";

        if (serial.size() < passed_bytes.size()) return TestStatus::Inconclusive;

        const std::string tail = serial.substr(serial.size() - passed_bytes.size());

        if (tail == passed_bytes) return TestStatus::Passed;
        if (tail == failed_bytes) return TestStatus::Failed;
        return TestStatus::Inconclusive;
    }

    std::vector<std::string> extract_failure_info(const std::string& serial) const override {
        return {};
    }
};