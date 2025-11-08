#include <stddef.h>

#include "systemrdl/quokka_rv_regs.h"
#include "quokka_rv.h"

// ========== Interrupt controller.

uint32_t ReadIntCtlEn()
{
    return interrupt_controller.enable;
}

uint32_t ReadIntCtlPending()
{
    return interrupt_controller.pending;
}

void WriteIntCtlEn(uint32_t value)
{
    interrupt_controller.enable = value;
}

// Write one to clear.
void ClearIntCtlPending(uint32_t value)
{
    interrupt_controller.pending = value;
}

// ========== Character display.

void CharDisplayClear(char clear_char)
{
    for (size_t i = 0; i < (CHAR_DISPLAY_WIDTH_CHARS * CHAR_DISPLAY_HEIGHT_CHARS); i++)
    {
        char_display.char_mem[i] = clear_char;
    }
}

void CharDisplayWriteString(char *str, uint32_t x_offset, uint32_t y_offset)
{
    for (size_t i = 0; str[i] != '\0'; i++)
    {
        char_display.char_mem[i + x_offset + (CHAR_DISPLAY_WIDTH_CHARS * y_offset)] = str[i];
    }
}

void CharDisplaySetBackgroundColour(uint8_t red, uint8_t green, uint8_t blue)
{
    uint32_t w_data = (uint32_t)red | ((uint32_t)green << 8) | ((uint32_t)blue << 16);
    char_display.background_colour = w_data;
}

void CharDisplaySetFontColour(uint8_t red, uint8_t green, uint8_t blue)
{
    uint32_t w_data = (uint32_t)red | ((uint32_t)green << 8) | ((uint32_t)blue << 16);
    char_display.font_colour = w_data;
}

// ========== Cpu timer.

uint64_t CpuTimerGetMtime()
{
    uint32_t mtime, mtimeh, mtimeh2;

    // The loop ensures that the lower part (mtime) didn't overflow between reads.
    do
    {
        mtimeh = riscv_timer.mtimeh;
        mtime = riscv_timer.mtime;
        mtimeh2 = riscv_timer.mtimeh;
    } while (mtimeh != mtimeh2);

    return ((uint64_t)mtimeh << 32) | mtime;
}

uint64_t CpuTimerGetMtimecmp()
{
    uint32_t mtime, mtimeh;

    mtime = riscv_timer.mtime;
    mtimeh = riscv_timer.mtimeh;

    return ((uint64_t)mtimeh << 32) | mtime;
}

void CpuTimerSetMtime(uint64_t value)
{
    uint32_t value_low = (uint32_t)(value);
    uint32_t value_high = (uint32_t)(value >> 32);

    riscv_timer.mtimeh = 0;
    riscv_timer.mtime = value_low;
    riscv_timer.mtimeh = value_high;
}

void CpuTimerSetMtimecmp(uint64_t value)
{
    uint32_t value_low = (uint32_t)(value);
    uint32_t value_high = (uint32_t)(value >> 32);

    riscv_timer.mtimecmph = 0xFFFFFFFF;
    riscv_timer.mtimecmp = value_low;
    riscv_timer.mtimecmph = value_high;
}

// ==========