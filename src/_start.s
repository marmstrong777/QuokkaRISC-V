    .section .text
    .globl _start
    .align 2
_start:
    # Setup stack pointer.
    la      sp, _stack_top

# REFACTOR Faster bss/sbss clearing using sw, need to be mindful of alignment issues however as length may not be
# integer multiple of word size.

# Zero bss.
    la      t0, _sbss       
    la      t1, _ebss
bss_loop:
    beq     t0, t1, bss_done
    sb      zero, 0(t0)
    addi    t0, t0, 1
    j       bss_loop
bss_done:

# Zero sbss.
    la      t0, _ssbss
    la      t1, _esbss
sbss_loop:
    beq     t0, t1, sbss_done
    sb      zero, 0(t0)
    addi    t0, t0, 1
    j       sbss_loop
sbss_done:

    call    main

infinite_loop:
    j       infinite_loop


