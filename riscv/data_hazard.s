# Base init
addi x1, x0, 1
addi x2, x0, 2
addi x3, x0, 3
addi x4, x0, 4

# ---------------------------------
# 1. 15-deep RAW chain (no breaks)
# ---------------------------------
add  x5,  x1, x2
add  x6,  x5, x3
add  x7,  x6, x4
add  x8,  x7, x5
add  x9,  x8, x6
add  x10, x9, x7
add  x11, x10, x8
add  x12, x11, x9
add  x13, x12, x10
add  x14, x13, x11
add  x15, x14, x12
add  x16, x15, x13
add  x17, x16, x14
add  x18, x17, x15
add  x19, x18, x16

# ---------------------------------
# 2. Constant overwrite same reg
# ---------------------------------
add  x20, x1, x2
add  x20, x20, x3
add  x20, x20, x4
add  x20, x20, x5
add  x20, x20, x6
add  x20, x20, x7
add  x20, x20, x8
add  x20, x20, x9

# ---------------------------------
# 3. Dual operand every cycle
# ---------------------------------
add  x21, x1, x2
add  x22, x21, x21
add  x23, x22, x22
add  x24, x23, x23
add  x25, x24, x24
add  x26, x25, x25

# ---------------------------------
# 4. Alternating rs1 / rs2 hazards
# ---------------------------------
add  x27, x1, x2
sub  x28, x3, x27
add  x29, x28, x4
sub  x30, x5, x29
add  x5,  x30, x6
sub  x6,  x7, x5
add  x7,  x6, x8
sub  x8,  x9, x7

# ---------------------------------
# 5. Priority test (EX/MEM vs MEM/WB)
# ---------------------------------
add  x9,  x1, x2
add  x10, x9, x3
add  x11, x10, x4
add  x12, x9, x11   # MUST use newest x9 (not stale)

# ---------------------------------
# 6. Fake rs2 hazards (addi spam)
# ---------------------------------
add  x13, x1, x2
addi x14, x13, 1
addi x15, x14, 1
addi x16, x15, 1
addi x17, x16, 1
addi x18, x17, 1
addi x19, x18, 1

# ---------------------------------
# 7. Cross-chain interference
# ---------------------------------
add  x21, x1, x2
add  x22, x3, x4
add  x23, x21, x22
add  x24, x23, x21
add  x25, x24, x22
add  x26, x25, x23
add  x27, x26, x24
add  x28, x27, x25

# ---------------------------------
# 8. Reuse old regs deep in pipe
# ---------------------------------
add  x29, x1, x2
add  x30, x3, x4
add  x5,  x29, x30
add  x6,  x5,  x29
add  x7,  x6,  x30
add  x8,  x7,  x5
add  x9,  x8,  x6
add  x10, x9,  x7

# ---------------------------------
# 9. Self-forward loop chain
# ---------------------------------
add  x11, x1, x2
add  x11, x11, x11
add  x11, x11, x11
add  x11, x11, x11
add  x11, x11, x11

# ---------------------------------
# 10. FINAL BOSS: everything mixed
# ---------------------------------
add  x12, x1, x2
add  x13, x12, x3
add  x14, x13, x4
add  x15, x14, x12
add  x16, x15, x13
add  x17, x16, x14
add  x18, x17, x15
add  x19, x18, x16
add  x20, x19, x17
add  x21, x20, x18
add  x22, x21, x19
add  x23, x22, x20
add  x24, x23, x21
add  x25, x24, x22
add  x26, x25, x23
wfi
