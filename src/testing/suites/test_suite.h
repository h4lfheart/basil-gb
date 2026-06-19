#pragma once

#include <vector>
#include <string>

enum class TestStatus {
    Passed,
    Failed,
    Inconclusive
};

struct TestSuite {
    virtual ~TestSuite() = default;

    virtual TestStatus detect(const std::string& serial) const = 0;
    virtual std::vector<std::string> extract_failure_info(const std::string& serial) const {
        std::vector<std::string> lines;
        std::string current;

        for (char c : serial) {
            if (c == '\n' || c == '\r') {
                if (!current.empty()) {
                    lines.push_back(current);
                    current.clear();
                }
            } else {
                current += c;
            }
        }
        if (!current.empty())
            lines.push_back(current);

        return lines;
    }
};