#include "usb_joypad.hpp"

#include <cstdint>

#include "esp_err.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "spi_joypad.hpp"
#include "usb/hid_host.h"
#include "usb/usb_host.h"

#define REPORT_MAX_SIZE 64
#define REPORT_MIN_SIZE 5
#define BUTTONS_LOW_INDEX 0
#define BUTTONS_HIGH_INDEX 1
#define AXIS_X_INDEX 3
#define AXIS_Y_INDEX 4

#define HID_A_MASK 0x02
#define HID_B_MASK 0x04
#define HID_SELECT_MASK 0x01
#define HID_START_MASK 0x02

#define AXIS_CENTER 0x80
#define AXIS_DEADZONE 0x40

namespace
{

    QueueHandle_t event_queue;

    uint8_t buttons_from_report(const uint8_t* report, size_t size)
    {
        if (size < REPORT_MIN_SIZE)
            return 0;

        uint8_t buttons = 0;
        const uint8_t buttons_low = report[BUTTONS_LOW_INDEX];
        const uint8_t buttons_high = report[BUTTONS_HIGH_INDEX];

        if (buttons_low & HID_A_MASK)
        {
            buttons |= BUTTON_A;
        }
        if (buttons_low & HID_B_MASK)
        {
            buttons |= BUTTON_B;
        }
        if (buttons_high & HID_SELECT_MASK)
        {
            buttons |= BUTTON_SELECT;
        }
        if (buttons_high & HID_START_MASK)
        {
            buttons |= BUTTON_START;
        }

        const uint8_t axis_x = report[AXIS_X_INDEX];
        const uint8_t axis_y = report[AXIS_Y_INDEX];

        if (axis_x <= AXIS_CENTER - AXIS_DEADZONE)
        {
            buttons |= BUTTON_LEFT;
        }
        else if (axis_x >= AXIS_CENTER + AXIS_DEADZONE)
        {
            buttons |= BUTTON_RIGHT;
        }
        if (axis_y <= AXIS_CENTER - AXIS_DEADZONE)
        {
            buttons |= BUTTON_UP;
        }
        else if (axis_y >= AXIS_CENTER + AXIS_DEADZONE)
        {
            buttons |= BUTTON_DOWN;
        }

        return buttons;
    }

    void on_interface_event(const hid_host_device_handle_t device, const hid_host_interface_event_t event, void*)
    {
        if (event == HID_HOST_INTERFACE_EVENT_INPUT_REPORT)
        {
            uint8_t report[REPORT_MAX_SIZE];
            size_t report_size = 0;
            if (hid_host_device_get_raw_input_report_data(device, report, sizeof(report), &report_size) != ESP_OK)
                return;

            spi_joypad::set_buttons(buttons_from_report(report, report_size));
            return;
        }

        if (event == HID_HOST_INTERFACE_EVENT_DISCONNECTED)
        {
            spi_joypad::set_buttons(0);
            hid_host_device_close(device);
        }
    }

    void open_device(const hid_host_device_handle_t device)
    {
        constexpr hid_host_device_config_t config = {
            .callback = on_interface_event,
            .callback_arg = nullptr,
        };

        if (hid_host_device_open(device, &config) != ESP_OK)
            return;

        size_t descriptor_size = 0;
        if (hid_host_get_report_descriptor(device, &descriptor_size) == nullptr)
        {
            hid_host_device_close(device);
            return;
        }

        spi_joypad::set_buttons(0);

        if (hid_host_device_start(device) != ESP_OK)
        {
            hid_host_device_close(device);
        }
    }

    void on_driver_event(hid_host_device_handle_t device,
                         const hid_host_driver_event_t,
                         void*)
    {
        xQueueSend(event_queue, &device, 0);
    }

    [[noreturn]] void hid_event_task(void*)
    {
        hid_host_device_handle_t device;
        while (true)
        {
            if (xQueueReceive(event_queue, &device, portMAX_DELAY) == pdTRUE)
            {
                open_device(device);
            }
        }
    }

    [[noreturn]] void usb_event_task(void*)
    {
        while (true)
        {
            uint32_t event_flags = 0;
            if (const esp_err_t error = usb_host_lib_handle_events(portMAX_DELAY, &event_flags); error != ESP_OK && error != ESP_ERR_TIMEOUT)
            {
                continue;
            }

            if (event_flags & USB_HOST_LIB_EVENT_FLAGS_NO_CLIENTS)
            {
                usb_host_device_free_all();
            }
        }
    }

}

namespace usb_joypad
{

    void init()
    {
        event_queue = xQueueCreate(8, sizeof(hid_host_device_handle_t));

        constexpr usb_host_config_t host_config = {
            .skip_phy_setup = false,
            .intr_flags = ESP_INTR_FLAG_LEVEL1,
        };
        ESP_ERROR_CHECK(usb_host_install(&host_config));
        xTaskCreatePinnedToCore(usb_event_task, "usb_events", 4096, nullptr, 2, nullptr, 0);

        constexpr hid_host_driver_config_t hid_config = {
            .create_background_task = true,
            .task_priority = 5,
            .stack_size = 4096,
            .core_id = 0,
            .callback = on_driver_event,
            .callback_arg = nullptr,
        };
        ESP_ERROR_CHECK(hid_host_install(&hid_config));
        xTaskCreate(hid_event_task, "hid_events", 4096, nullptr, 3, nullptr);
    }

}
