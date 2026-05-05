#
# trap_ultimate.s — Every trap edge case in one file
#
# Covers:
#   - Basic ecall + handler setup
#   - Back to back ecalls (no instructions between)
#   - ecall inside inner loop (nested)
#   - Register pressure across trap boundary (all regs live)
#   - Trap counter verification via uscratch
#   - CSR forwarding chain across trap boundary
#   - ecall immediately after handler setup (no padding)
#   - ecall as very last instruction before wfi
#
# x17 (a7) NEVER written — avoids RARS syscall side effects
# x28 = trap counter, expected = 11 at end
# uscratch = trap counter mirror (written by handler each time)
#

     .text
     j main

# ════════════════════════════════════════════════════════════════════════
#  HANDLER
# ════════════════════════════════════════════════════════════════════════
handler:
     csrrw  x10, uepc,  zero      # x10 = faulting PC
     addi   x10, x10, 4           # skip ecall
     csrrw  zero, uepc, x10       # update uepc
     addi   x28, x28, 1           # increment trap counter
     csrrw  zero, uscratch, x28   # mirror counter into uscratch
     uret

# ════════════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════════════
main:
     la     x10, handler
     csrrw  zero, utvec,   x10
     csrrsi zero, ustatus, 0x1
     addi   x28, zero, 0          # trap counter = 0

     # ── Phase 1: ecall immediately after setup (no padding) ─────────
     ecall                        # TRAP 1

     # ── Phase 2: register pressure — all regs live at ecall ─────────
     addi x5,  zero, 5
     addi x6,  zero, 6
     addi x7,  zero, 7
     addi x10, zero, 10
     addi x11, zero, 11
     addi x12, zero, 12
     addi x13, zero, 13
     addi x14, zero, 14
     addi x15, zero, 15
     addi x16, zero, 16
     # x17 skipped
     addi x18, zero, 18
     addi x19, zero, 19
     addi x20, zero, 20
     addi x21, zero, 21
     addi x22, zero, 22
     addi x23, zero, 23
     addi x24, zero, 24
     addi x25, zero, 25
     addi x26, zero, 26
     addi x27, zero, 27
     # x28 = trap counter, x29/x30 used below

     ecall                        # TRAP 2 — all regs live

     # ── Phase 3: back to back ecalls — no instructions between ──────
     ecall                        # TRAP 3
     ecall                        # TRAP 4
     ecall                        # TRAP 5

     # ── Phase 4: arithmetic churn then ecall ────────────────────────
     addi x10, zero, 1
     add  x11, x10, x10           # 2
     add  x12, x11, x10           # 3
     add  x13, x12, x11           # 5
     add  x14, x13, x12           # 8
     add  x15, x14, x13           # 13
     add  x16, x15, x14           # 21
     add  x18, x16, x15           # 34
     add  x19, x18, x16           # 55
     xor  x20, x18, x19
     slli x21, x20, 1
     srli x22, x21, 1
     add  x23, x21, x22

     ecall                        # TRAP 6 — pipeline hot with ALU ops

     # ── Phase 5: CSR forwarding chain across trap boundary ───────────
     addi   x10, zero, 0x5
     csrrw  zero, uscratch, x10   # uscratch = 5
     csrrw  x11, uscratch, zero   # x11 = 5  (fwd)
     addi   x11, x11, 1           # x11 = 6
     csrrw  zero, uscratch, x11   # uscratch = 6

     ecall                        # TRAP 7 — mid CSR chain

     csrrw  x12, uscratch, zero   # x12 = trap count (handler overwrote uscratch)
     # x12 should = 7 (trap count, handler mirrors it into uscratch)

     # ── Phase 6: nested loop with ecall inside ───────────────────────
     addi x25, zero, 3            # outer = 3
_outer:
     beq  x25, zero, _loop_done
     addi x26, zero, 3            # inner = 3
_inner:
     beq  x26, zero, _inner_done
     add  x10, x25, x26
     xor  x11, x10, x28
     ecall                        # TRAP 8,9,10 — 3 outer * 1 inner ecall
     addi x26, x26, -1
     j    _inner
_inner_done:
     addi x25, x25, -1
     j    _outer

_loop_done:
     # ── Phase 7: ecall as very last instruction before wfi ───────────
     addi x10, zero, 99
     addi x11, zero, 88
     addi x12, zero, 77

     ecall                        # TRAP 11 — uret lands on wfi

     # x28 should = 11 here
end:
     wfi
