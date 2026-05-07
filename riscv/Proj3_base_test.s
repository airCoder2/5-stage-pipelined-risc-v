# Proj1_base_test.s
# Tests arithmetic + logical instructions

.text
.globl _start

_start:
    # Initialize registers
    addi x1, x0, 10
    addi x2, x0, 5

    # ADD / SUB
    add x3, x1, x2      # x3 = 15
    sub x4, x1, x2      # x4 = 5

    # AND / OR / XOR
    and x5, x1, x2
    or  x6, x1, x2
    xor x7, x1, x2

    # Immediate versions
    andi x8, x1, 3
    ori  x9, x1, 3
    xori x10, x1, 3

    # SLT / SLTI / SLTIU
    slt x11, x2, x1     # 1
    slti x12, x2, 10    # 1
    sltiu x13, x2, -1   # unsigned compare

    # Shifts
    sll x14, x2, x2
    srl x15, x1, x2
    sra x16, x1, x2

    slli x17, x2, 2
    srli x18, x1, 1
    srai x19, x1, 1

    # LUI / AUIPC
    lui x20, 0x12345
    auipc x21, 0

    # Memory test
    la x22, data
    sw x3, 0(x22)
    lw x23, 0(x22)

    # Byte / half loads
    lb x24, 0(x22)
    lh x25, 0(x22)
    lbu x26, 0(x22)
    lhu x27, 0(x22)


    wfi

.data
data: .word 0
