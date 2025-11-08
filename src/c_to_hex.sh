USAGE_MESSAGE="Usage: Arg1: C source file"

if [[ $# -ne 1 ]] ; then
	echo "$USAGE_MESSAGE"
	exit 1
fi

OBJFILE=$(mktemp)

# REFACTOR Manually referencing every input file, not great practice.
if ! riscv32-unknown-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -Og -g -nostartfiles -nodefaultlibs -nolibc -nostdlib -ffreestanding -Wall -T "link.ld" "_start.s" "riscv.h" "riscv.c" "quokka_rv.h" "quokka_rv.c" "systemrdl/quokka_rv_regs.h" "$1" -o "$OBJFILE"; then
	echo "ERROR: Compiler error"
	exit 1
fi

# For inspection of assembly.
cp "$OBJFILE" "./a.out"

BINFILE_IMEM=$(mktemp)

if ! riscv32-unknown-elf-objcopy -j .text -O binary "$OBJFILE" "$BINFILE_IMEM"; then
	echo "ERROR: Objcopy error"
fi

BINFILE_DMEM=$(mktemp)

# FIXME Section order doesn't match linker script, still works at present but should be fixed.
if ! riscv32-unknown-elf-objcopy -j .srodata -j .sdata -j .sbss -j .rodata -j .data -j .bss -O binary "$OBJFILE" "$BINFILE_DMEM"; then
	echo "ERROR: Objcopy error"
fi

# REFACTOR Objcopy might have a flag to directly output as hex.
# TODO This function is horribly optimized and takes far too long.
convert_bin_to_hex() {
    local BINFILE="$1"
    local OUTFILE="$2"
    local PAD_BYTES="$3"
    local BYTES_PER_LINE="$4"

    if [[ -z "$BINFILE" || -z "$OUTFILE" || -z "$PAD_BYTES" || -z "$BYTES_PER_LINE" ]]; then
        echo "Usage: convert_bin_to_hex <binary_file> <output_hex_file> <padding_bytes> <bytes_per_line>"
        return 1
    fi

    # Convert binary to hex string
    local HEX
    HEX=$(xxd -p "$BINFILE")

    # Remove any existing newlines
    HEX=$(echo "$HEX" | tr -d '\n')

    local HEX_LENGTH="${#HEX}"
    local DESIRED_LENGTH=$((PAD_BYTES * 2))  # each byte = 2 hex chars

    if [[ HEX_LENGTH -gt $DESIRED_LENGTH ]]; then
        echo "ERROR: Length of binary exceeds padding ($HEX_LENGTH > $DESIRED_LENGTH)"
        return 1
    fi

    # Pad with zeros
    while [[ $HEX_LENGTH -lt $DESIRED_LENGTH ]]; do
        HEX+="00"
        HEX_LENGTH="${#HEX}"
    done
    
    local HEX_LE=""

    local i=0
    local WORD_BYTES=$BYTES_PER_LINE
    local WORD_CHARS=$((WORD_BYTES * 2))

    while [[ $i -lt ${#HEX} ]]; do
        # Grab one word
        local WORD=${HEX:$i:$WORD_CHARS}

        # Reverse bytes in this word
        local REV=""
        local j
        for (( j=$WORD_CHARS-2; j>=0; j-=2 )); do
            REV+=${WORD:$j:2}
        done

        HEX_LE+="$REV"
        i=$((i + WORD_CHARS))
    done

    # Calculate chars per line (bytes * 2)
    local CHARS_PER_LINE=$((BYTES_PER_LINE * 2))

    # Add newline every CHARS_PER_LINE
    HEX_LE=$(echo "$HEX_LE" | fold -w "$CHARS_PER_LINE")

    echo "$HEX_LE" > "$OUTFILE"
}

# TODO Using the memory sizes as constants here is bad, if filling blockram the initial begin block should be
# performing the zero extension, not here.
convert_bin_to_hex "$BINFILE_IMEM" "inst_mem.mem" "8192" "1"
convert_bin_to_hex "$BINFILE_DMEM" "data_mem.mem" "65536" "4"

exit 0

