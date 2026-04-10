# =============================================================
# RISC-V Pipeline Hazard Stress Test
# No pseudo-instructions except nop. No load-use. One WFI.
# Success: x31 = 1    Failure: x31 = -1
# =============================================================

# -------------------------
# Init
# -------------------------
    addi  x1,  x0, 1
    addi  x2,  x0, 2
    addi  x3,  x0, 3
    addi  x4,  x0, 10
    addi  x5,  x0, -1      # 0xFFFFFFFF unsigned

# =============================================================
# HAZARD CLASS 1 — EX->EX RAW chain
# =============================================================
    addi  x6,  x0, 7
    addi  x6,  x6, 1       # RAW: x6 = 8
    addi  x6,  x6, 1       # RAW: x6 = 9
    addi  x6,  x6, 1       # RAW: x6 = 10
    addi  x7,  x0, 10
    bne   x6,  x7, BAD

# =============================================================
# HAZARD CLASS 2 — MEM->EX RAW (2-cycle gap)
# =============================================================
    addi  x8,  x0, 5
    addi  x9,  x0, 3       # gap
    add   x10, x8, x9      # RAW on x8: x10 = 8
    addi  x11, x0, 8
    bne   x10, x11, BAD

# =============================================================
# HAZARD CLASS 3 — EX->EX on both rs1 and rs2 simultaneously
# =============================================================
    addi  x12, x0, 6
    addi  x13, x0, 4
    add   x14, x12, x13    # x14 = 10
    add   x15, x14, x14    # RAW on both ports: x15 = 20
    addi  x16, x0, 20
    bne   x15, x16, BAD

# =============================================================
# HAZARD CLASS 4 — 3-deep RAW shift chain
# =============================================================
    addi  x17, x0, 1
    slli  x17, x17, 1      # RAW: x17 = 2
    slli  x17, x17, 1      # RAW: x17 = 4
    slli  x17, x17, 1      # RAW: x17 = 8
    slli  x17, x17, 1      # RAW: x17 = 16
    addi  x18, x0, 16
    bne   x17, x18, BAD

# =============================================================
# HAZARD CLASS 5 — RAW into branch rs1 (EX->branch)
# =============================================================
    addi  x19, x0, 42
    beq   x19, x19, H5_OK  # x19 written one instr ago
    jal   x0,  BAD
H5_OK:
    addi  x20, x0, 55      # canary

# =============================================================
# HAZARD CLASS 6 — RAW into branch rs2 (EX->branch, both operands)
# =============================================================
    addi  x21, x0, 7
    addi  x22, x0, 7       # written, immediately read by beq
    beq   x21, x22, H6_OK
    jal   x0,  BAD
H6_OK:
    addi  x23, x0, 77      # canary

# =============================================================
# HAZARD CLASS 7 — MEM->branch forwarding (2 instrs before branch)
# =============================================================
    addi  x24, x0, 13
    addi  x25, x0, 13      # gap
    beq   x24, x25, H7_OK  # x24 in MEM when branch in ID
    jal   x0,  BAD
H7_OK:
    addi  x26, x0, 88      # canary

# =============================================================
# HAZARD CLASS 8 — RAW into not-taken branch
# =============================================================
    addi  x27, x0, 3
    bne   x27, x3, BAD     # x27 just written; 3==3 so NOT taken
    addi  x28, x0, 44      # canary — must execute

# =============================================================
# HAZARD CLASS 9 — Back-to-back branches
# =============================================================
    beq   x1,  x1, BB1     # taken
    jal   x0,  BAD
BB1:
    bne   x2,  x3, BB2     # taken (2!=3)
    jal   x0,  BAD
BB2:
    beq   x2,  x3, BAD     # NOT taken
    beq   x1,  x1, BB3     # taken
    jal   x0,  BAD
BB3:
    addi  x29, x0, 111     # canary

# =============================================================
# HAZARD CLASS 10 — Branch as first instruction at JAL target
# =============================================================
    jal   x0,  SHADOW_TARGET
    addi  x31, x0, -1      # flushed
SHADOW_TARGET:
    beq   x1,  x1, SH_OK
    jal   x0,  BAD
SH_OK:
    addi  x30, x0, 99      # canary

# =============================================================
# HAZARD CLASS 11 — WAW: two writes to same reg back-to-back
# =============================================================
    addi  x5,  x0, 100
    addi  x5,  x0, 200     # WAW: x5 must be 200
    addi  x6,  x0, 200
    bne   x5,  x6, BAD

# =============================================================
# HAZARD CLASS 12 — WAR: read then immediate overwrite
# =============================================================
    addi  x7,  x0, 50
    add   x8,  x7, x7      # reads x7=50 → x8=100
    addi  x7,  x0, 999     # WAR: overwrites x7; x8 must still = 100
    addi  x9,  x0, 100
    bne   x8,  x9, BAD

# =============================================================
# HAZARD CLASS 13 — Branch to PC+4 (taken, target == next instr)
# =============================================================
    addi  x10, x0, 0
    beq   x0,  x0, PC4     # always taken, target is the very next instr
PC4:
    addi  x10, x10, 1      # must execute exactly once
    addi  x11, x0, 1
    bne   x10, x11, BAD

# =============================================================
# HAZARD CLASS 14 — Writes to x0 must be discarded
# =============================================================
    addi  x0,  x0, 42      # must be suppressed
    addi  x0,  x1, 99      # must be suppressed
    bne   x0,  x0, BAD     # x0 must be 0
    addi  x12, x0, 7       # x12 = 7 (reads x0, must get 0)

# =============================================================
# HAZARD CLASS 15 — JALR with RAW on base register
# =============================================================
    jal   x10, JR_SETUP
    addi  x31, x0, -1      # flushed
    jal   x0,  BAD
JR_SETUP:
    jal   x0,  JR_LAND
JR_LAND:
    addi  x11, x10, 8      # x11 = &JR_LAND
    jalr  x0,  x11, 0      # RAW: x11 written prev instr
    addi  x31, x0, -1      # flushed
    jal   x0,  BAD

# =============================================================
# HAZARD CLASS 16 — Tight loop, count UP, no pseudo-instructions
#   x13 += 2 each iter until x13 == 8; RAW on counter each iter
# =============================================================
    addi  x13, x0, 0       # counter = 0
    addi  x14, x0, 8       # limit = 8
    addi  x15, x0, 2       # step = 2
UP_LOOP:
    add   x13, x13, x15    # RAW if x15 just written: counter += 2
    addi  x15, x15, 0      # RAW on x15 — forces forward path
    bne   x13, x14, UP_LOOP  # exits when x13 == 8 (after 4 iters)
    bne   x13, x14, BAD    # verify

# =============================================================
# CANARY VERIFICATION
#   x20=55  x23=77  x26=88  x28=44  x29=111  x30=99
#   Sum = 474
# =============================================================
    add   x15, x0,  x20
    add   x15, x15, x23
    add   x15, x15, x26
    add   x15, x15, x28
    add   x15, x15, x29
    add   x15, x15, x30
    addi  x16, x0, 474
    bne   x15, x16, BAD

# =============================================================
# SUCCESS
# =============================================================
    addi  x31, x0, 1
    jal   x0,  END

BAD:
    addi  x31, x0, -1
END:
    wfi
