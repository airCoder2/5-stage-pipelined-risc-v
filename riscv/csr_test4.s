.text
    j main

# ═══════════════════════════════════════════════════════════════════
# BLOCK 1: Zero-gap RAW — result used immediately as rs1
# Every instruction reads the rd written by the instruction
# directly before it. No NOPs. Tests 1-cycle forwarding.
# ═══════════════════════════════════════════════════════════════════
main:
    csrrwi  x0,  uscratch, 0x1      # uscratch = 1
    csrrw   x5,  uscratch, x0       # x5  = 1,  uscratch = 0
    csrrw   x6,  uepc,     x5       # x6  = 0,  uepc     = 1   (x5 fwd)
    csrrw   x7,  ucause,   x6       # x7  = 0,  ucause   = 0   (x6 fwd)
    csrrw   x28, utvec,    x7       # x28 = 0,  utvec    = 0   (x7 fwd)
    csrrw   x29, ustatus,  x28      # x29 = 0,  ustatus  = 0   (x28 fwd)
    csrrw   x5,  uscratch, x29      # x5  = 0,  uscratch = 0   (x29 fwd)
    # expect: x5==0, x6==0, x7==0, x28==0, x29==0

# ═══════════════════════════════════════════════════════════════════
# BLOCK 2: Same rd written then read 1, 2, 3 cycles later —
# all three forwarding distances for the same register
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0xF
    csrrw   x5,  uscratch, x0       # x5 = 0xF
    csrrwi  x6,  uepc,     0x1      # x6 = 0 (old uepc); distance-1 fwd of x5 below:
    csrrs   x0,  ucause,   x5       # ucause |= 0xF  ← x5 fwd dist 1
    csrrwi  x0,  utvec,    0x0
    csrrs   x0,  ucause,   x5       # ucause |= 0xF  ← x5 fwd dist 2
    csrrwi  x0,  utvec,    0x0
    csrrwi  x0,  utvec,    0x0
    csrrs   x0,  ucause,   x5       # ucause |= 0xF  ← x5 fwd dist 3
    csrrw   x7,  ucause,   x0       # x7 = 0xF
    # expect: x7 == 0xF

# ═══════════════════════════════════════════════════════════════════
# BLOCK 3: WAW — same rd written three times in a row,
# only the last write should survive in the reg file
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrwi  x0, uepc,     0x2
    csrrwi  x0, ucause,   0x3
    csrrw   x5, uscratch, x0        # x5 = 1
    csrrw   x5, uepc,     x0        # x5 = 2  (WAW)
    csrrw   x5, ucause,   x0        # x5 = 3  (WAW)
    addi    x6, x5, 0               # x6 = 3
    # expect: x6 == 3

# ═══════════════════════════════════════════════════════════════════
# BLOCK 4: csrrs/csrrc forwarding — rs1 comes from previous
# CSR write, must be correctly forwarded into set/clear mask
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x0
    csrrwi  x5, uscratch, 0xA       # x5 = 0,  uscratch = 0xA
    csrrs   x6, uscratch, x5        # x6 = 0xA, uscratch |= 0  (x5==0, no bits set)
    csrrwi  x0, uscratch, 0xA       # reset
    csrrwi  x5, uepc,     0x3       # x5 = 0,  uepc = 3
    csrrs   x0, uscratch, x5        # uscratch |= 0  (x5==0)
    csrrw   x7, uscratch, x0        # x7 = 0xA (unchanged)
    # now use a nonzero forwarded mask
    csrrwi  x0, uscratch, 0x5
    csrrwi  x5, uepc,     0x3       # x5 = old uepc
    csrrwi  x0, uepc,     0x6       # x5 is now stale... but:
    csrrwi  x5, ucause,   0x3       # x5 = old ucause = 0xA? no — fresh write: x5 = prev ucause
    # let's do a clean forwarded-mask test:
    csrrwi  x0,  uscratch, 0x0
    csrrwi  x5,  uepc,     0x6      # x5 = old uepc (don't care)
    csrrwi  x0,  uepc,     0x0
    li      x5,  0x5
    csrrs   x0,  uscratch, x5       # uscratch |= 5  (x5 forwarded from li)
    csrrw   x28, uscratch, x0       # x28 = 5
    # expect: x7==0xA, x28==5

# ═══════════════════════════════════════════════════════════════════
# BLOCK 5: ALU in the middle of a CSR chain — forward through
# add/sub/xor, then back into CSR
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0x3
    csrrw   x5,  uscratch, x0       # x5 = 3
    addi    x5,  x5,  1             # x5 = 4  (ALU writes x5)
    csrrw   x0,  uepc,    x5        # uepc = 4  (x5 forwarded from ALU)
    csrrw   x6,  uepc,    x0        # x6 = 4
    slli    x6,  x6,  1             # x6 = 8
    csrrw   x0,  ucause, x6         # ucause = 8
    csrrw   x7,  ucause, x0         # x7 = 8
    xor     x7,  x7,  x6            # x7 = 0  (8^8)
    csrrw   x0,  utvec,  x7         # utvec = 0
    csrrwi  x0,  uscratch, 0xF
    csrrw   x28, uscratch, x0       # x28 = 0xF
    or      x29, x28, x7            # x29 = 0xF
    csrrw   x0,  utvec,  x29        # utvec = 0xF
    csrrw   x30, utvec,  x0         # x30 = 0xF
    # expect: x6==8, x7==0, x28==0xF, x29==0xF, x30==0xF

# ═══════════════════════════════════════════════════════════════════
# BLOCK 6: Recursive-style accumulation — read-modify-write
# same CSR 8 times in a row, each time forwarding prev result
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrsi  x5,  uscratch, 0x2      # x5=1,  uscratch=3
    csrrsi  x6,  uscratch, 0x4      # x6=3,  uscratch=7
    csrrsi  x7,  uscratch, 0x8      # x7=7,  uscratch=0xF
    csrrci  x28, uscratch, 0x1      # x28=0xF, uscratch=0xE
    csrrci  x29, uscratch, 0x2      # x29=0xE, uscratch=0xC
    csrrci  x30, uscratch, 0x4      # x30=0xC, uscratch=0x8
    csrrwi  x5,  uscratch, 0x0      # x5=0x8, uscratch=0
    csrrw   x6,  uscratch, x0       # x6=0
    # expect: x5==8, x6==0, x7==7, x28==0xF, x29==0xE, x30==0xC

# ═══════════════════════════════════════════════════════════════════
# BLOCK 7: Interleaved 5-CSR rotate — each CSR's old value
# becomes the next CSR's new value in a rotating chain,
# crossing all five registers twice
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrwi  x0, uepc,     0x2
    csrrwi  x0, ucause,   0x3
    csrrwi  x0, utvec,    0x4
    csrrwi  x0, ustatus,  0x1
    # First rotate pass
    csrrw   x5,  uscratch, x0       # x5=1
    csrrw   x0,  uepc,     x5       # uepc=1       (x5 fwd)
    csrrw   x6,  uepc,     x0       # x6=1
    csrrw   x0,  ucause,   x6       # ucause=1     (x6 fwd)
    csrrw   x7,  ucause,   x0       # x7=1
    csrrw   x0,  utvec,    x7       # utvec=1      (x7 fwd)
    csrrw   x28, utvec,    x0       # x28=1
    csrrw   x0,  ustatus,  x28      # ustatus=1    (x28 fwd — masked to bit0)
    csrrw   x29, ustatus,  x0       # x29=1
    csrrw   x0,  uscratch, x29      # uscratch=1   (x29 fwd)
    # Second rotate pass — now read them all back
    csrrw   x5,  uscratch, x0       # x5=1
    csrrw   x6,  uepc,     x0       # x6=1
    csrrw   x7,  ucause,   x0       # x7=1
    csrrw   x28, utvec,    x0       # x28=1
    csrrw   x29, ustatus,  x0       # x29=1
    # expect: x5==1, x6==1, x7==1, x28==1, x29==1

# ═══════════════════════════════════════════════════════════════════
# BLOCK 8: x0-as-rs1 must never modify CSR (RISC-V spec),
# but x0-as-rd must still cause CSR write
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0xB
    csrrs   x5, uscratch, x0        # x5=0xB, uscratch unchanged (rs1=x0)
    csrrc   x6, uscratch, x0        # x6=0xB, uscratch unchanged (rs1=x0)
    csrrw   x7, uscratch, x0        # x7=0xB, uscratch=0
    csrrw   x28, uscratch, x0       # x28=0
    # expect: x5==0xB, x6==0xB, x7==0xB, x28==0

# ═══════════════════════════════════════════════════════════════════
# BLOCK 9: imm=0 on csrrsi/csrrci must not modify CSR
# even when rd is x0 (tests both corners together)
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0xD
    csrrsi  x0, uscratch, 0x0       # imm=0, x0 rd — no write
    csrrci  x0, uscratch, 0x0       # imm=0, x0 rd — no write
    csrrsi  x5, uscratch, 0x0       # imm=0, x5 rd — CSR unchanged, x5 gets old value
    csrrci  x6, uscratch, 0x0       # imm=0, x6 rd — CSR unchanged, x6 gets old value
    csrrw   x7, uscratch, x0        # x7 = 0xD (CSR must still be 0xD)
    # expect: x5==0xD, x6==0xD, x7==0xD

# ═══════════════════════════════════════════════════════════════════
# BLOCK 10: Deep 10-instruction RAW chain — no ALU, pure CSR
# each rd immediately becomes rs1 of next instruction
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x7
    csrrwi  x0, uepc,     0x0
    csrrwi  x0, ucause,   0x0
    csrrwi  x0, utvec,    0x0
    csrrw   x5,  uscratch, x0       # x5=7
    csrrw   x0,  uepc,     x5       # uepc=7        (dist-1 fwd)
    csrrw   x6,  uepc,     x0       # x6=7
    csrrw   x0,  ucause,   x6       # ucause=7      (dist-1 fwd)
    csrrw   x7,  ucause,   x0       # x7=7
    csrrw   x0,  utvec,    x7       # utvec=7       (dist-1 fwd)
    csrrw   x28, utvec,    x0       # x28=7
    csrrw   x0,  uscratch, x28      # uscratch=7    (dist-1 fwd)
    csrrw   x29, uscratch, x0       # x29=7
    csrrw   x0,  uepc,     x29      # uepc=7        (dist-1 fwd)
    csrrw   x30, uepc,     x0       # x30=7
    # expect: x5==7, x6==7, x7==7, x28==7, x29==7, x30==7

# ═══════════════════════════════════════════════════════════════════
# BLOCK 11: ustatus mask exhaustive — only bit 0 writable,
# attempts to set bits 1-4 silently ignored
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, ustatus, 0x0
    csrrwi  x0, ustatus, 0x1F       # try to set bits 0-4; only bit0 survives
    csrrw   x5, ustatus, x0         # x5 = 1
    csrrwi  x0, ustatus, 0x1E       # try to set bits 1-4; none survive
    csrrw   x6, ustatus, x0         # x6 = 0
    csrrsi  x0, ustatus, 0x1        # set bit 0
    csrrci  x7, ustatus, 0x1        # x7=1, clear bit0
    csrrw   x28, ustatus, x0        # x28=0
    csrrwi  x0, ustatus, 0x1        # set again
    csrrci  x0, ustatus, 0x1F       # clear all — only bit0 can be cleared
    csrrw   x29, ustatus, x0        # x29=0
    # expect: x5==1, x6==0, x7==1, x28==0, x29==0

# ═══════════════════════════════════════════════════════════════════
# BLOCK 12: csrrwi with imm=0 — writes 0 to CSR, reads old value
# back-to-back on same CSR, all five registers
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0xC
    csrrwi  x5,  uscratch, 0x0      # x5=0xC, uscratch=0
    csrrwi  x6,  uscratch, 0x0      # x6=0,   uscratch=0
    csrrwi  x0,  uepc,     0xA
    csrrwi  x7,  uepc,     0x0      # x7=0xA, uepc=0
    csrrwi  x28, uepc,     0x0      # x28=0,  uepc=0
    csrrwi  x0,  ucause,   0x5
    csrrwi  x29, ucause,   0x0      # x29=5,  ucause=0
    csrrwi  x30, ucause,   0x0      # x30=0,  ucause=0
    # expect: x5==0xC, x6==0, x7==0xA, x28==0, x29==5, x30==0

# ═══════════════════════════════════════════════════════════════════
# BLOCK 13: ALU→CSR→ALU→CSR 6-deep — alternating, result
# of each stage forwarded into next with no gaps
# ═══════════════════════════════════════════════════════════════════
    li      x5,  1
    addi    x5,  x5,  1             # x5=2
    csrrw   x0,  uscratch, x5       # uscratch=2    (x5 fwd from ALU)
    csrrw   x6,  uscratch, x0       # x6=2
    slli    x6,  x6,  2             # x6=8          (ALU on CSR result)
    csrrw   x0,  uepc,  x6          # uepc=8        (x6 fwd from ALU)
    csrrw   x7,  uepc,  x0          # x7=8
    addi    x7,  x7,  7             # x7=15
    csrrw   x0,  ucause, x7         # ucause=15     (x7 fwd from ALU)
    csrrw   x28, ucause, x0         # x28=15
    srli    x28, x28, 1             # x28=7
    csrrw   x0,  utvec,  x28        # utvec=7       (x28 fwd from ALU)
    csrrw   x29, utvec,  x0         # x29=7
    add     x30, x29,  x28          # x30=14
    # expect: x6==2, x7==8 (before addi), wait:
    # after slli x6=8, after addi x7=15, x28=7 after srli, x29=7, x30=14
    # let's track: x6 written by csrrw(uscratch)=2, then slli→8. final x6=8
    # x7 written by csrrw(uepc)=8, then addi→15. final x7=15
    # expect: x6==8, x7==15, x28==7, x29==7, x30==14

# ═══════════════════════════════════════════════════════════════════
# BLOCK 14: Stress — all hazard types simultaneously,
# 20 instructions, 5 CSRs, ALU interspersed,
# every instruction depends on the previous one
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0x2
    csrrwi  x0,  uepc,     0x3
    csrrwi  x0,  ucause,   0x4
    csrrwi  x0,  utvec,    0x5
    csrrwi  x0,  ustatus,  0x1
    csrrw   x5,  uscratch, x0       # x5=2
    csrrw   x6,  uepc,     x5       # x6=3,  uepc=2    (x5 fwd)
    addi    x5,  x5,  1             # x5=3              (ALU on x5 — WAR with above)
    csrrw   x7,  ucause,   x6       # x7=4,  ucause=3  (x6 fwd)
    add     x6,  x6,  x5            # x6=6              (ALU — x6 WAR, x5 RAW)
    csrrw   x28, utvec,    x7       # x28=5, utvec=4   (x7 fwd)
    xor     x7,  x7,  x6            # x7=4^6=2          (ALU)
    csrrs   x29, ustatus,  x28      # x29=1, ustatus|=5→masked→1  (x28 fwd)
    and     x28, x28, x7            # x28=5&2=0         (ALU)
    csrrci  x30, ustatus,  0x1      # x30=1, ustatus=0
    csrrw   x0,  uscratch, x30      # uscratch=1  (x30 fwd)
    csrrw   x0,  uepc,     x28      # uepc=0      (x28 fwd)
    csrrw   x5,  uscratch, x0       # x5=1
    csrrw   x6,  uepc,     x0       # x6=0
    add     x7,  x5,  x6            # x7=1
    # expect: x5==1, x6==0, x7==1, x28==0, x29==1, x30==1

done:
    wfi
