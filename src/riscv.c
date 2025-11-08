#include "riscv.h"

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

void SetMtvec(void (*trap_handler)(void))
{
    asm volatile("csrw mtvec, %0" ::"r"(trap_handler));
}

uint32_t GetMcause()
{
    uint32_t value;
    asm volatile("csrr %0, mcause" : "=r"(value));

    return value;
}