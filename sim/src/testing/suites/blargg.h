#pragma once

#include "test_suite.h"

struct BlarggSuite : TestSuite {
    TestStatus detect(const std::string& serial) const override {
        if (serial.find("Passed") != std::string::npos) return TestStatus::Passed;
        if (serial.find("Failed") != std::string::npos) return TestStatus::Failed;
        return TestStatus::Inconclusive;
    }

    std::vector<std::string> extract_failure_info(const std::string& serial) const override {
        auto lines = TestSuite::extract_failure_info(serial);

        if (!lines.empty())
            lines.erase(lines.begin());

        if (!lines.empty() && (lines.back() == "Passed" || lines.back() == "Failed"))
            lines.pop_back();

        auto is_blank = [](const std::string& s) {
            return std::all_of(s.begin(), s.end(), [](unsigned char c) { return std::isspace(c); });
        };

        while (!lines.empty() && is_blank(lines.front())) 
            lines.erase(lines.begin());
            
        while (!lines.empty() && is_blank(lines.back())) 
            lines.pop_back();

        return lines;
    }
};