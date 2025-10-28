#include <stddef.h>

#include "quokka_rv.h"

// REFACTOR Find a library that provides all these RISC-V specific functionality e.g. CSR manipulation.
// ========== Interrupts.

void EnableGlobalInterrupts()
{
    asm volatile("csrs mstatus, %0" ::"r"(CSR_MSTATUS_MIE));
}

void DisableGlobalInterrupts()
{
    asm volatile("csrc mstatus, %0" ::"r"(CSR_MSTATUS_MIE));
}

void EnableTimerInterrupts()
{
    asm volatile("csrs mie, %0" ::"r"(CSR_MIE_MTIE));
}

void DisableTimerInterrupts()
{
    asm volatile("csrc mie, %0" ::"r"(CSR_MIE_MTIE));
}

void EnableSoftwareInterrupts()
{
    asm volatile("csrs mie, %0" ::"r"(CSR_MIE_MSIE));
}

void DisableSoftwareInterrupts()
{
    asm volatile("csrc mie, %0" ::"r"(CSR_MIE_MSIE));
}

void EnableExternalInterrupts()
{
    asm volatile("csrs mie, %0" ::"r"(CSR_MIE_MEIE));
}

void DisableExternalInterrupts()
{
    asm volatile("csrc mie, %0" ::"r"(CSR_MIE_MEIE));
}

uint32_t GetMcause()
{
    uint32_t value;
    asm volatile("csrr %0, mcause" : "=r"(value));

    return value;
}

// ========== Character display.

void CharDisplayClear(volatile char *display_base, char clear_char)
{
    for (size_t i = 0; i < (CHAR_DISPLAY_WIDTH_CHARS * CHAR_DISPLAY_HEIGHT_CHARS); i++)
    {
        (display_base + CHAR_DISPLAY_OFFSET_CHAR_MEM)[i] = clear_char;
    }
}

void CharDisplayWriteString(volatile char *display_base, char *str, uint32_t x_offset, uint32_t y_offset)
{
    for (size_t i = 0; str[i] != '\0'; i++)
    {
        (display_base + CHAR_DISPLAY_OFFSET_CHAR_MEM)[i + x_offset + (CHAR_DISPLAY_WIDTH_CHARS * y_offset)] = str[i];
    }
}

void CharDisplaySetBackgroundColour(volatile void *display_base, uint8_t red, uint8_t green, uint8_t blue)
{
    uint32_t w_data = (uint32_t)red | ((uint32_t)green << 8) | ((uint32_t)blue << 16);
    *((uint32_t *)(display_base + CHAR_DISPLAY_OFFSET_BACKGROUND_COLOUR)) = w_data;
}

void CharDisplaySetFontColour(volatile void *display_base, uint8_t red, uint8_t green, uint8_t blue)
{
    uint32_t w_data = (uint32_t)red | ((uint32_t)green << 8) | ((uint32_t)blue << 16);
    *((uint32_t *)(display_base + CHAR_DISPLAY_OFFSET_FONT_COLOUR)) = w_data;
}

// ========== Cpu timer.

uint64_t CpuTimerGetMtime()
{
    uint32_t mtime, mtimeh, mtimeh2;

    // The loop ensures that the lower part (mtime) didn't wrap between reads.
    do
    {
        mtimeh = *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMEH);
        mtime = *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIME);
        mtimeh2 = *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMEH);
    } while (mtimeh != mtimeh2);

    return ((uint64_t)mtimeh << 32) | mtime;
}

uint64_t CpuTimerGetMtimecmp()
{
    uint32_t mtime, mtimeh;

    mtime = *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMECMP);
    mtimeh = *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMECMPH);

    return ((uint64_t)mtimeh << 32) | mtime;
}

void CpuTimerSetMtime(uint64_t value)
{
    uint32_t value_low = (uint32_t)(value);
    uint32_t value_high = (uint32_t)(value >> 32);

    *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMEH) = 0;
    *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIME) = value_low;
    *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMEH) = value_high;
}

void CpuTimerSetMtimecmp(uint64_t value)
{
    uint32_t value_low = (uint32_t)(value);
    uint32_t value_high = (uint32_t)(value >> 32);

    *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMECMPH) = 0xFFFFFFFF;
    *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMECMP) = value_low;
    *(volatile uint32_t *)(CPU_TIMER_BASE + CPU_TIMER_OFFSET_MTIMECMPH) = value_high;
}

// ==========