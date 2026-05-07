# Proj1_cf_test.s
# Tests all control flow instructions with call depth of 5

.text
.globl main

main:
    addi x5, x0, 3
    addi x6, x0, 7

    # beq
    beq x5, x5, skip1
    addi x7, x0, 99
skip1:

    # bne
    bne x5, x6, skip2
    addi x7, x0, 99
skip2:

    # blt
    blt x5, x6, skip3
    addi x7, x0, 99
skip3:

    # bge
    bge x6, x5, skip4
    addi x7, x0, 99
skip4:

    # bltu
    bltu x5, x6, skip5
    addi x7, x0, 99
skip5:

    # bgeu
    bgeu x6, x5, skip6
    addi x7, x0, 99
skip6:

    jal ra, level1
    li a7, 10
    ecall

level1:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi x10, x0, 1
    jal ra, level2
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, ra, 0

level2:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi x11, x0, 2
    jal ra, level3
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, ra, 0

level3:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi x12, x0, 3
    jal ra, level4
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, ra, 0

level4:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi x13, x0, 4
    jal ra, level5
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, ra, 0

level5:
    addi x14, x0, 5
    jalr zero, ra, 0
