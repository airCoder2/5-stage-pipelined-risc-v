
# ---------------------------------
# Valid data memory base
# ---------------------------------
lui  x31, 0x10010      # x31 = 0x10010000

# ---------------------------------
# Initialize registers
# ---------------------------------
addi x1, x0, 1
addi x2, x0, 2
addi x3, x0, 3
addi x4, x0, 4

# ---------------------------------
# 1. Store data forwarding
# ---------------------------------
add  x5, x1, x2
sw   x5, 0(x31)

# ---------------------------------
# 2. Forwarding chain into store
# ---------------------------------
add  x6, x1, x2
add  x7, x6, x3
add  x8, x7, x4
sw   x8, 4(x31)

# ---------------------------------
# 3. Dual operand forwarding
# ---------------------------------
add  x9, x1, x2
add  x10, x3, x4
add  x11, x9, x10
sw   x11, 8(x31)

# ---------------------------------
# 4. Overwrite before store
# ---------------------------------
add  x12, x1, x2
add  x12, x12, x3
add  x12, x12, x4
sw   x12, 12(x31)

# ---------------------------------
# 5. Self-dependency chain
# ---------------------------------
add  x13, x1, x2
add  x13, x13, x13
add  x13, x13, x13
sw   x13, 16(x31)

# ---------------------------------
# 6. Alternating dependencies
# ---------------------------------
add  x14, x1, x2
add  x15, x14, x3
add  x16, x15, x4
add  x17, x16, x14
sw   x17, 20(x31)

# ---------------------------------
# 7. Long dependency chain
# ---------------------------------
add  x18, x1, x2
add  x19, x18, x3
add  x20, x19, x4
add  x21, x20, x1
add  x22, x21, x2
add  x23, x22, x3
add  x24, x23, x4
sw   x24, 24(x31)

# ---------------------------------
# 8. Mixed reuse / interleaving
# ---------------------------------
add  x25, x1, x2
add  x26, x25, x25
add  x27, x26, x3
add  x28, x27, x4
sw   x28, 28(x31)

# ---------------------------------
# 9. Repeated overwrite
# ---------------------------------
add  x29, x1, x2
add  x29, x29, x3
add  x29, x29, x4
sw   x29, 32(x31)

# ---------------------------------
# 10. Final mixed stress
# ---------------------------------
add  x30, x1, x2
add  x5,  x3, x4
add  x6,  x30, x5
add  x7,  x6,  x30
add  x8,  x7, x5
sw   x8, 36(x31)
wfi