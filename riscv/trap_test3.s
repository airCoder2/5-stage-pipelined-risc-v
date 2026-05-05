#
# trap_gauntlet.s — Comprehensive trap stress test (fixed)
#
# x17 (a7) NEVER written — avoids RARS syscall side effects
# x28 = trap counter, expected value = 5 at end
#

     .text
     j main

handler:
     csrrw  t0, uepc, zero
     addi   t0, t0, 4
     csrrw  zero, uepc, t0
     addi   x28, x28, 1        # increment trap counter
     uret

main:
     la     t0, handler
     csrrw  zero, utvec, t0
     csrrsi zero, ustatus, 0x1
     addi   x28, zero, 0       # trap counter = 0

     # ── Phase 1: Register fill, then trap ───────────────────────────
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
     # x17 intentionally skipped
     addi x18, zero, 18
     addi x19, zero, 19
     addi x20, zero, 20
     addi x21, zero, 21

     ecall                     # TRAP 1

     # ── Phase 2: Fibonacci-like accumulation, then trap ─────────────
     addi x10, zero, 1
     add  x11, x10, x10        # 2
     add  x12, x11, x10        # 3
     add  x13, x12, x11        # 5
     add  x14, x13, x12        # 8
     add  x15, x14, x13        # 13
     add  x16, x15, x14        # 21
     add  x18, x16, x15        # 34
     add  x19, x18, x16        # 55
     add  x20, x19, x18        # 89
     add  x21, x20, x19        # 144
     add  x22, x21, x20        # 233
     add  x23, x22, x21        # 377

     ecall                     # TRAP 2

     # ── Phase 3: Nested loop (bounded, no infinite risk) ────────────
     addi x5, zero, 0          # i = 0
_outer:
     addi x6, zero, 0          # j = 0
_inner:
     add  x10, x5, x6          # x10 = i + j
     addi x6, x6, 1
     slti x7, x6, 3
     bne  x7, zero, _inner
     addi x5, x5, 1
     slti x7, x5, 3
     bne  x7, zero, _outer

     ecall                     # TRAP 3

     # ── Phase 4: Inlined multiply-by-shift (no loop, no subroutine) ─
     # 3*3 = 9: x10 = 3, x11 = 3<<1=6, x12 = x10+x11+... use shifts
     addi x10, zero, 3
     slli x11, x10, 1          # 6
     add  x12, x10, x11        # 9  (3*3)

     addi x10, zero, 5
     slli x11, x10, 2          # 20
     add  x13, x10, x11        # 25 (5*5)

     addi x10, zero, 7
     slli x11, x10, 3          # 56
     sub  x14, x11, x10        # 49 (7*7 = 8*7 - 7)

     add  x15, x12, x13        # 9+25 = 34
     add  x15, x15, x14        # 34+49 = 83

     ecall                     # TRAP 4

     # ── Phase 5: Long epilogue, final trap before halt ───────────────
     addi x10, zero, 10
     addi x11, zero, 20
     addi x12, zero, 30
     addi x13, zero, 40
     addi x14, zero, 50
     addi x15, zero, 60
     addi x16, zero, 70
     addi x18, zero, 80
     addi x19, zero, 90
     addi x20, zero, 100
     addi x21, zero, 110
     addi x22, zero, 120
     addi x23, zero, 130
     addi x24, zero, 140

     ecall                     # TRAP 5

     # x28 should = 5 here
end:
     wfi
