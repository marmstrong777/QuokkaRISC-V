#ifndef QUOKKA_RV_H
#define QUOKKA_RV_H

#include <stdint.h>

// ========== Interrupts.

#define CSR_MCAUSE_SOFTWARE_M 0x80000003
#define CSR_MCAUSE_TIMER_M 0x80000007
#define CSR_MCAUSE_EXTERNAL_M 0x8000000B

#define CSR_MIE_MSIE (1 << 3)
#define CSR_MIE_MTIE (1 << 7)
#define CSR_MIE_MEIE (1 << 11)
#define CSR_MSTATUS_MIE (1 << 3)

void EnableGlobalInterrupts();
void DisableGlobalInterrupts();
void EnableTimerInterrupts();
void DisableTimerInterrupts();
void EnableSoftwareInterrupts();
void DisableSoftwareInterrupts();
void EnableExternalInterrupts();
void DisableExternalInterrupts();

uint32_t GetMcause();

// REFACTOR Replace much of this peripheral code with that generated from systemrdl.
// ========== Interrupt controller.

#define INT_CTL_BASE 0xA0000000
#define INT_CTL_OFFSET_EN 0x0
#define INT_CTL_OFFSET_PENDING 0x4

uint32_t ReadIntCtlEn();
uint32_t ReadIntCtlPending();

void WriteIntCtlEn(uint32_t value);
void ClearIntCtlPending(uint32_t value);

// ========== Character display.

#define CHAR_DISPLAY_BASE 0x80000000
#define CHAR_DISPLAY_OFFSET_CHAR_MEM 0x0
#define CHAR_DISPLAY_OFFSET_BACKGROUND_COLOUR 0x8000
#define CHAR_DISPLAY_OFFSET_FONT_COLOUR 0x8004
#define CHAR_DISPLAY_WIDTH_CHARS 80
#define CHAR_DISPLAY_HEIGHT_CHARS 30

// REFACTOR Change these functions to just have display base hardcoded, there won't ever be more than 1 display.
void CharDisplayClear(volatile char *display_base, char clear_char);
void CharDisplayWriteString(volatile char *display_base, char *str, uint32_t x_offset, uint32_t y_offset);
void CharDisplaySetBackgroundColour(volatile void *display_base, uint8_t red, uint8_t green, uint8_t blue);
void CharDisplaySetFontColour(volatile void *display_base, uint8_t red, uint8_t green, uint8_t blue);

// ========== Cpu timer.

#define CPU_TIMER_BASE 0x90000000
#define CPU_TIMER_OFFSET_MTIME 0x00000000
#define CPU_TIMER_OFFSET_MTIMEH 0x00000004
#define CPU_TIMER_OFFSET_MTIMECMP 0x00000008
#define CPU_TIMER_OFFSET_MTIMECMPH 0x0000000C

uint64_t CpuTimerGetMtime();
uint64_t CpuTimerGetMtimecmp();
void CpuTimerSetMtime(uint64_t value);
void CpuTimerSetMtimecmp(uint64_t value);

// ==========

#endif
