#ifndef QUOKKA_RV_H
#define QUOKKA_RV_H

#include <stdint.h>

// ========== Interrupt controller.

uint32_t ReadIntCtlEn();
uint32_t ReadIntCtlPending();

void WriteIntCtlEn(uint32_t value);
void ClearIntCtlPending(uint32_t value);

// ========== Character display.

#define CHAR_DISPLAY_WIDTH_CHARS 80
#define CHAR_DISPLAY_HEIGHT_CHARS 30

void CharDisplayClear(char clear_char);
void CharDisplayWriteString(char *str, uint32_t x_offset, uint32_t y_offset);
void CharDisplaySetBackgroundColour(uint8_t red, uint8_t green, uint8_t blue);
void CharDisplaySetFontColour(uint8_t red, uint8_t green, uint8_t blue);

// ========== Cpu timer.

uint64_t CpuTimerGetMtime();
uint64_t CpuTimerGetMtimecmp();
void CpuTimerSetMtime(uint64_t value);
void CpuTimerSetMtimecmp(uint64_t value);

// ==========

#endif
