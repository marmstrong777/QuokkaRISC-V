ENTRY(_start)

MEMORY {
  DMEM (rw) : ORIGIN = 0x10000000, LENGTH = 64K
  IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 8K
}
/* TODO Is there a need to guarantee natural alignment? */

SECTIONS {
  .text : {
    _stext = .;
    *(.text*)
    _etext = .;
  } > IMEM

  .rodata : {
    _srodata = .;
    *(.rodata*)
    _erodata = .;
  } > DMEM

  .srodata : {
    _ssrodata = .;
    *(.srodata*)
    _esrodata = .;
  } > DMEM

  .data : {
    _sdata = .;
    *(.data*)
    _edata = .;
  } > DMEM

  .sdata : {
    _ssdata = .;
    *(.sdata*)
    _esdata = .;
  } > DMEM

  .bss : {
    _sbss = .;
    *(.bss*)
    *(COMMON)
    _ebss = .;
  } > DMEM

  .sbss : {
    _ssbss = .;
    *(.sbss*)
    _esbss = .;
  } > DMEM

  _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);

  /DISCARD/ : {
    *(.comment)
  }
}

