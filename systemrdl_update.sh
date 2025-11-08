#!/usr/bin/bash

# -x arg prevents top level addrmap from being generated as a struct; it's just for documentation and would be several gigabytes in length as a struct.
# -i arg generates instances for direct access.
peakrdl c-header regs/quokka_rv.rdl -o src/systemrdl/quokka_rv_regs.h -xi

peakrdl html regs/quokka_rv.rdl -o docs/systemrdl/
