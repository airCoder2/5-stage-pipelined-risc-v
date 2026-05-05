.text
    j main

# ═══════════════════════════════════════════════════════════════════
# BLOCK 1: Zero-gap RAW — result used immediately as rs1
# Every instruction reads the rd written by the instruction
# directly before it. No NOPs. Tests 1-cycle forwarding.
# Now includes uie in the chain.
# ═══════════════════════════════════════════════════════════════════
main:
    csrrwi  x0,  uscratch, 0x1      # uscratch = 1
    csrrw   x5,  uscratch, x0       # x5  = 1,  uscratch = 0
    csrrw   x6,  uepc,     x5       # x6  = 0,  uepc     = 1   (x5 fwd)
    csrrw   x7,  ucause,   x6       # x7  = 0,  ucause   = 0   (x6 fwd)
    csrrw   x28, utvec,    x7       # x28 = 0,  utvec    = 0   (x7 fwd)
    csrrw   x29, uie,      x28      # x29 = 0,  uie      = 0   (x28 fwd)
    csrrw   x30, ustatus,  x29      # x30 = 0,  ustatus  = 0   (x29 fwd)
    csrrw   x5,  uscratch, x30      # x5  = 0,  uscratch = 0   (x30 fwd)
    # expect: x5==0, x6==0, x7==0, x28==0, x29==0, x30==0

# ═══════════════════════════════════════════════════════════════════
# BLOCK 2: Same rd written then read at distances 1, 2, 3 —
# all three forwarding distances for the same register
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0xF
    csrrw   x5,  uscratch, x0       # x5 = 0xF
    csrrs   x0,  uie,      x5       # uie |= 0xF  ← x5 fwd dist 1
    csrrwi  x0,  utvec,    0x0
    csrrs   x0,  uie,      x5       # uie |= 0xF  ← x5 fwd dist 2
    csrrwi  x0,  utvec,    0x0
    csrrwi  x0,  utvec,    0x0
    csrrs   x0,  uie,      x5       # uie |= 0xF  ← x5 fwd dist 3
    csrrw   x7,  uie,      x0       # x7 = 0xF
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
# BLOCK 4: csrrs/csrrc forwarding — rs1 from previous CSR write
# forwarded into set/clear mask, tested on uie
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uie, 0x0
    li      x5, 0x5
    csrrs   x0, uie, x5             # uie |= 5   (x5 fwd from li)
    csrrw   x28, uie, x0            # x28 = 5
    csrrc   x0, uie, x5             # uie &= ~5  (x5 fwd)
    csrrw   x29, uie, x0            # x29 = 0
    csrrwi  x0,  uie, 0x3
    li      x5,  0x4
    csrrc   x0,  uie, x5            # uie &= ~4; uie was 3, bit2 not set, result=3
    csrrw   x30, uie, x0            # x30 = 3
    # expect: x28==5, x29==0, x30==3

# ═══════════════════════════════════════════════════════════════════
# BLOCK 5: ALU in the middle of a CSR chain — forward through
# add/sub/xor, then back into CSR, now touching uie
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0x3
    csrrw   x5,  uscratch, x0       # x5 = 3
    addi    x5,  x5,  1             # x5 = 4
    csrrw   x0,  uie,     x5        # uie = 4   (x5 fwd from ALU)
    csrrw   x6,  uie,     x0        # x6 = 4
    slli    x6,  x6,  1             # x6 = 8
    csrrw   x0,  ucause,  x6        # ucause = 8
    csrrw   x7,  ucause,  x0        # x7 = 8
    xor     x7,  x7,  x6            # x7 = 0
    csrrw   x0,  uie,     x7        # uie = 0
    csrrwi  x0,  uscratch, 0xF
    csrrw   x28, uscratch, x0       # x28 = 0xF
    or      x29, x28, x7            # x29 = 0xF
    csrrw   x0,  uie,     x29       # uie = 0xF
    csrrw   x30, uie,     x0        # x30 = 0xF
    # expect: x6==8, x7==0, x28==0xF, x29==0xF, x30==0xF

# ═══════════════════════════════════════════════════════════════════
# BLOCK 6: Recursive-style accumulation — read-modify-write
# same CSR 8 times in a row on uie
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uie, 0x1
    csrrsi  x5,  uie, 0x2           # x5=1,    uie=3
    csrrsi  x6,  uie, 0x4           # x6=3,    uie=7
    csrrsi  x7,  uie, 0x8           # x7=7,    uie=0xF
    csrrci  x28, uie, 0x1           # x28=0xF, uie=0xE
    csrrci  x29, uie, 0x2           # x29=0xE, uie=0xC
    csrrci  x30, uie, 0x4           # x30=0xC, uie=0x8
    csrrwi  x5,  uie, 0x0           # x5=0x8,  uie=0
    csrrw   x6,  uie, x0            # x6=0
    # expect: x5==8, x6==0, x7==7, x28==0xF, x29==0xE, x30==0xC

# ═══════════════════════════════════════════════════════════════════
# BLOCK 7: Interleaved 6-CSR rotate — each CSR's old value
# becomes the next CSR's new value, crossing all six registers twice
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrwi  x0, uepc,     0x2
    csrrwi  x0, ucause,   0x3
    csrrwi  x0, utvec,    0x4
    csrrwi  x0, uie,      0x5
    csrrwi  x0, ustatus,  0x1
    # Rotate pass — thread value 1 through all six CSRs
    csrrw   x5,  uscratch, x0       # x5=1
    csrrw   x0,  uepc,     x5       # uepc=1       (x5 fwd)
    csrrw   x6,  uepc,     x0       # x6=1
    csrrw   x0,  ucause,   x6       # ucause=1     (x6 fwd)
    csrrw   x7,  ucause,   x0       # x7=1
    csrrw   x0,  utvec,    x7       # utvec=1      (x7 fwd)
    csrrw   x28, utvec,    x0       # x28=1
    csrrw   x0,  uie,      x28      # uie=1        (x28 fwd)
    csrrw   x29, uie,      x0       # x29=1
    csrrw   x0,  ustatus,  x29      # ustatus=1    (x29 fwd, masked to bit0)
    csrrw   x30, ustatus,  x0       # x30=1
    csrrw   x0,  uscratch, x30      # uscratch=1   (x30 fwd)
    # Read all back
    csrrw   x5,  uscratch, x0       # x5=1
    csrrw   x6,  uepc,     x0       # x6=1
    csrrw   x7,  ucause,   x0       # x7=1
    csrrw   x28, utvec,    x0       # x28=1
    csrrw   x29, uie,      x0       # x29=1
    csrrw   x30, ustatus,  x0       # x30=1
    # expect: x5==1, x6==1, x7==1, x28==1, x29==1, x30==1

# ═══════════════════════════════════════════════════════════════════
# BLOCK 8: x0-as-rs1 must never modify CSR, tested on uie
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uie, 0xB
    csrrs   x5,  uie, x0            # x5=0xB, uie unchanged (rs1=x0)
    csrrc   x6,  uie, x0            # x6=0xB, uie unchanged (rs1=x0)
    csrrw   x7,  uie, x0            # x7=0xB, uie=0
    csrrw   x28, uie, x0            # x28=0
    # expect: x5==0xB, x6==0xB, x7==0xB, x28==0

# ═══════════════════════════════════════════════════════════════════
# BLOCK 9: imm=0 on csrrsi/csrrci must not modify CSR
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uie, 0xD
    csrrsi  x0, uie, 0x0            # imm=0, x0 rd — no write
    csrrci  x0, uie, 0x0            # imm=0, x0 rd — no write
    csrrsi  x5, uie, 0x0            # imm=0, x5 rd — CSR unchanged, x5=old
    csrrci  x6, uie, 0x0            # imm=0, x6 rd — CSR unchanged, x6=old
    csrrw   x7, uie, x0             # x7=0xD (must still be 0xD)
    # expect: x5==0xD, x6==0xD, x7==0xD

# ═══════════════════════════════════════════════════════════════════
# BLOCK 10: Deep 12-instruction RAW chain — no ALU, pure CSR,
# threading through all 6 CSRs including uie
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x7
    csrrwi  x0, uepc,     0x0
    csrrwi  x0, ucause,   0x0
    csrrwi  x0, utvec,    0x0
    csrrwi  x0, uie,      0x0
    csrrw   x5,  uscratch, x0       # x5=7
    csrrw   x0,  uepc,     x5       # uepc=7        (dist-1 fwd)
    csrrw   x6,  uepc,     x0       # x6=7
    csrrw   x0,  ucause,   x6       # ucause=7      (dist-1 fwd)
    csrrw   x7,  ucause,   x0       # x7=7
    csrrw   x0,  utvec,    x7       # utvec=7       (dist-1 fwd)
    csrrw   x28, utvec,    x0       # x28=7
    csrrw   x0,  uie,      x28      # uie=7         (dist-1 fwd)
    csrrw   x29, uie,      x0       # x29=7
    csrrw   x0,  uscratch, x29      # uscratch=7    (dist-1 fwd)
    csrrw   x30, uscratch, x0       # x30=7
    # expect: x5==7, x6==7, x7==7, x28==7, x29==7, x30==7

# ═══════════════════════════════════════════════════════════════════
# BLOCK 11: ustatus mask + uie independence — writes to uie
# must not bleed into ustatus and vice versa
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0, ustatus, 0x0
    csrrwi  x0, uie,     0x0
    csrrwi  x0, ustatus, 0x1F       # only bit0 survives in ustatus
    csrrwi  x0, uie,     0x1F       # uie holds full value (no masking)
    csrrw   x5, ustatus, x0         # x5=1  (only bit0)
    csrrw   x6, uie,     x0         # x6=0x1F
    csrrwi  x0, ustatus, 0x0
    csrrwi  x0, uie,     0x0
    csrrsi  x0, uie,     0x1        # set bit0 of uie
    csrrsi  x0, ustatus, 0x1        # set bit0 of ustatus
    csrrw   x7,  uie,     x0        # x7=1
    csrrw   x28, ustatus, x0        # x28=1
    csrrci  x0,  uie,     0x1       # clear bit0 of uie only
    csrrw   x29, uie,     x0        # x29=0
    csrrw   x30, ustatus, x0        # x30=1  (ustatus must be unchanged)
    # expect: x5==1, x6==0x1F, x7==1, x28==1, x29==0, x30==1

# ═══════════════════════════════════════════════════════════════════
# BLOCK 12: csrrwi imm=0 back-to-back on all six CSRs
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0xC
    csrrwi  x5,  uscratch, 0x0      # x5=0xC, uscratch=0
    csrrwi  x6,  uscratch, 0x0      # x6=0,   uscratch=0
    csrrwi  x0,  uepc,     0xA
    csrrwi  x7,  uepc,     0x0      # x7=0xA, uepc=0
    csrrwi  x28, uepc,     0x0      # x28=0,  uepc=0
    csrrwi  x0,  uie,      0x9
    csrrwi  x29, uie,      0x0      # x29=9,  uie=0
    csrrwi  x30, uie,      0x0      # x30=0,  uie=0
    # expect: x5==0xC, x6==0, x7==0xA, x28==0, x29==9, x30==0

# ═══════════════════════════════════════════════════════════════════
# BLOCK 13: ALU→CSR→ALU→CSR 6-deep including uie
# ═══════════════════════════════════════════════════════════════════
    li      x5,  1
    addi    x5,  x5,  1             # x5=2
    csrrw   x0,  uie,      x5       # uie=2         (x5 fwd from ALU)
    csrrw   x6,  uie,      x0       # x6=2
    slli    x6,  x6,  2             # x6=8
    csrrw   x0,  uepc,     x6       # uepc=8        (x6 fwd from ALU)
    csrrw   x7,  uepc,     x0       # x7=8
    addi    x7,  x7,  7             # x7=15
    csrrw   x0,  ucause,   x7       # ucause=15     (x7 fwd from ALU)
    csrrw   x28, ucause,   x0       # x28=15
    srli    x28, x28, 1             # x28=7
    csrrw   x0,  uie,      x28      # uie=7         (x28 fwd from ALU)
    csrrw   x29, uie,      x0       # x29=7
    add     x30, x29,  x28          # x30=14
    # expect: x6==8, x7==15, x28==7, x29==7, x30==14

# ═══════════════════════════════════════════════════════════════════
# BLOCK 14: Ultimate stress — all 6 CSRs, all hazard types,
# ALU interspersed, every instruction depends on previous,
# uie woven throughout the chain
# ═══════════════════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0x2
    csrrwi  x0,  uepc,     0x3
    csrrwi  x0,  ucause,   0x4
    csrrwi  x0,  utvec,    0x5
    csrrwi  x0,  uie,      0x6
    csrrwi  x0,  ustatus,  0x1
    csrrw   x5,  uscratch, x0       # x5=2
    csrrw   x6,  uepc,     x5       # x6=3,  uepc=2    (x5 fwd)
    addi    x5,  x5,  1             # x5=3              (WAR on x5)
    csrrw   x7,  ucause,   x6       # x7=4,  ucause=3  (x6 fwd)
    add     x6,  x6,  x5            # x6=6              (x6 WAR, x5 RAW)
    csrrw   x28, utvec,    x7       # x28=5, utvec=4   (x7 fwd)
    xor     x7,  x7,  x6            # x7=4^6=2
    csrrw   x29, uie,      x28      # x29=6, uie=5     (x28 fwd)
    and     x28, x28, x7            # x28=5&2=0
    csrrs   x30, ustatus,  x29      # x30=1, ustatus|=6→masked→1  (x29 fwd)
    csrrci  x5,  ustatus,  0x1      # x5=1,  ustatus=0
    csrrw   x0,  uie,      x30      # uie=1            (x30 fwd)
    csrrw   x0,  uscratch, x28      # uscratch=0       (x28 fwd)
    csrrw   x6,  uie,      x0       # x6=1
    csrrw   x7,  uscratch, x0       # x7=0
    add     x28, x6,  x7            # x28=1
    # expect: x5==1, x6==1, x7==0, x28==1, x29==6, x30==1

done:
    wfi
