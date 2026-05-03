.text
     j main

# ─────────────────────────────────────────────
# Test CSR registers: ustatus, utvec, uscratch,
#                     uepc, ucause
# Tests: csrrw, csrrs, csrrc, csrrwi, csrrsi, csrrci
# ─────────────────────────────────────────────

main:
    # ── CSRRW: write & read back ──────────────
    li   t0, 0xDEAD
    csrrw zero, uscratch, t0     # uscratch = 0xDEAD, discard old
    csrrw t1, uscratch, zero     # t1 = 0xDEAD, uscratch = 0
    # expect: t1 == 0xDEAD

    # ── CSRRWI: write immediate & read back ───
    csrrwi zero, uscratch, 7     # uscratch = 7 (5-bit imm)
    csrrw  t1, uscratch, zero    # t1 = 7
    # expect: t1 == 7

    # ── CSRRS: set bits ───────────────────────
    li   t0, 0xF0
    csrrw zero, uscratch, t0     # uscratch = 0xF0
    li   t0, 0x0F
    csrrs t1, uscratch, t0       # t1 = 0xF0 (old), uscratch |= 0x0F
    csrrw t2, uscratch, zero     # t2 = 0xFF
    # expect: t1 == 0xF0, t2 == 0xFF

    # ── CSRRSI: set bits immediate ────────────
    li   t0, 0x10
    csrrw  zero, uscratch, t0   # uscratch = 0x10
    csrrsi t1, uscratch, 0x5    # t1 = 0x10 (old), uscratch |= 0x5
    csrrw  t2, uscratch, zero   # t2 = 0x15
    # expect: t1 == 0x10, t2 == 0x15

    # ── CSRRC: clear bits ─────────────────────
    li   t0, 0xFF
    csrrw zero, uscratch, t0     # uscratch = 0xFF
    li   t0, 0x0F
    csrrc t1, uscratch, t0       # t1 = 0xFF (old), uscratch &= ~0x0F
    csrrw t2, uscratch, zero     # t2 = 0xF0
    # expect: t1 == 0xFF, t2 == 0xF0

    # ── CSRRCI: clear bits immediate ──────────
    li   t0, 0x1F
    csrrw  zero, uscratch, t0   # uscratch = 0x1F
    csrrci t1, uscratch, 0xF    # t1 = 0x1F (old), uscratch &= ~0xF
    csrrw  t2, uscratch, zero   # t2 = 0x10
    # expect: t1 == 0x1F, t2 == 0x10

    # ── UTVEC: set trap vector ────────────────
    la   t0, trap_handler
    csrrw zero, utvec, t0        # utvec = &trap_handler
    csrrw t1, utvec, zero        # t1 = &trap_handler
    # expect: t1 == address of trap_handler

    # ── UEPC / UCAUSE: write and read back ────
    li   t0, 0xCAFE
    csrrw zero, uepc, t0         # uepc = 0xCAFE
    csrrw t1, uepc, zero         # t1 = 0xCAFE
    # expect: t1 == 0xCAFE

    li   t0, 0xB
    csrrw zero, ucause, t0       # ucause = 11
    csrrw t1, ucause, zero       # t1 = 11
    # expect: t1 == 0xB

    # ── USTATUS: set/clear a bit ──────────────
    csrrsi zero, ustatus, 0x1    # set bit 0
    csrrw  t1, ustatus, zero     # t1 should have bit 0 set
    csrrci zero, ustatus, 0x1    # clear bit 0
    csrrw  t2, ustatus, zero     # t2 should have bit 0 clear
    # expect: t1 & 1 == 1, t2 & 1 == 0

done:
    nop
    wfi

trap_handler:
    csrrw t3, uepc,   zero       # read faulting PC
    csrrw t4, ucause, zero       # read cause
    nop
    wfi
