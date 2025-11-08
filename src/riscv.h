#ifndef RISCV_H
#define RISCV_H

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

void SetMtvec(void (*trap_handler)(void));

uint32_t GetMcause();

#endif