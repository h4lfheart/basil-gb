#include "spi_joypad.hpp"

#include <atomic>

#include "driver/gpio.h"
#include "driver/spi_slave.h"
#include "esp_err.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define CLOCK_PIN GPIO_NUM_41
#define CHIP_SELECT_PIN GPIO_NUM_40
#define MOSI_PIN GPIO_NUM_39
#define MISO_PIN GPIO_NUM_38
#define TRANSFER_COUNT 2

namespace
{

    std::atomic<uint8_t> current_buttons = {0};

    WORD_ALIGNED_ATTR uint8_t tx_data[TRANSFER_COUNT];
    WORD_ALIGNED_ATTR uint8_t rx_data[TRANSFER_COUNT];
    spi_slave_transaction_t transfers[TRANSFER_COUNT];

    void queue_transfer(spi_slave_transaction_t* transfer)
    {
        const auto user_ptr = static_cast<uint8_t*>(transfer->user);
        *user_ptr = current_buttons.load(std::memory_order_relaxed);
        ESP_ERROR_CHECK(spi_slave_queue_trans(SPI2_HOST, transfer, portMAX_DELAY));
    }

    [[noreturn]] void spi_task(void*)
    {
        for (int index = 0; index < TRANSFER_COUNT; index++)
        {
            transfers[index] = {};
            transfers[index].length = 8;
            transfers[index].tx_buffer = &tx_data[index];
            transfers[index].rx_buffer = &rx_data[index];
            transfers[index].user = &tx_data[index];
            queue_transfer(&transfers[index]);
        }

        while (true)
        {
            spi_slave_transaction_t* completed = nullptr;
            if (const esp_err_t error = spi_slave_get_trans_result(SPI2_HOST, &completed, portMAX_DELAY); error != ESP_OK || completed == nullptr)
            {
                vTaskDelay(pdMS_TO_TICKS(10));
                continue;
            }

            queue_transfer(completed);
        }
    }

}

namespace spi_joypad
{

    void set_buttons(const uint8_t buttons)
    {
        current_buttons.store(buttons, std::memory_order_relaxed);
    }

    void init()
    {
        current_buttons.store(0, std::memory_order_relaxed);

        constexpr spi_bus_config_t bus_config = {
            .mosi_io_num = MOSI_PIN,
            .miso_io_num = MISO_PIN,
            .sclk_io_num = CLOCK_PIN,
            .quadwp_io_num = -1,
            .quadhd_io_num = -1,
            .max_transfer_sz = 1,
        };

        constexpr spi_slave_interface_config_t slave_config = {
            .spics_io_num = CHIP_SELECT_PIN,
            .flags = 0,
            .queue_size = TRANSFER_COUNT,
            .mode = 0,
            .post_setup_cb = nullptr,
            .post_trans_cb = nullptr,
        };

        ESP_ERROR_CHECK(spi_slave_initialize(SPI2_HOST, &bus_config, &slave_config, SPI_DMA_DISABLED));
        gpio_set_pull_mode(CHIP_SELECT_PIN, GPIO_PULLUP_ONLY);
        xTaskCreate(spi_task, "spi_joypad", 3072, nullptr, 5, nullptr);
    }

}
