#
# trap_gauntlet_hard.s — The Long Haul (scaled for 30s timeout)
#
# 8 outer * 8 inner = 64 traps total
# x17 (a7) NEVER written
# x28 = trap counter, expected = 64 (0x40) at end
#

     .text
     j main

handler:
     csrrw  t0, uepc, zero
     addi   t0, t0, 4
     csrrw  zero, uepc, t0
     addi   x28, x28, 1
     uret

main:
     la     t0, handler
     csrrw  zero, utvec, t0
     csrrsi zero, ustatus, 0x1

     addi x28, zero, 0         # trap counter = 0
     addi x27, zero, 1         # fib a = 1
     addi x29, zero, 1         # fib b = 1
     addi x25, zero, 8         # outer counter = 8

_outer:
     beq  x25, zero, _done

     # --- Fibonacci burn (8 steps) ---
     add  x30, x27, x29
     mv   x27, x29
     mv   x29, x30
     add  x30, x27, x29
     mv   x27, x29
     mv   x29, x30
     add  x30, x27, x29
     mv   x27, x29
     mv   x29, x30
     add  x30, x27, x29
     mv   x27, x29
     mv   x29, x30
     add  x30, x27, x29
     mv   x27, x29
     mv   x29, x30
     add  x30, x27, x29
     mv   x27, x29
     mv   x29, x30
     add  x30, x27, x29
     mv   x27, x29
     mv   x29, x30
     add  x30, x27, x29
     mv   x27, x29
     mv   x29, x30

     # --- Inner loop: 8 ecalls per outer iteration ---
     addi x26, zero, 8

_inner:
     beq  x26, zero, _inner_done

     add  x10, x27, x26
     add  x11, x29, x25
     xor  x12, x10, x11
     add  x13, x12, x28
     slli x14, x13, 1
     srli x15, x14, 1
     add  x16, x14, x15

     ecall                     # TRAP — 8*8 = 64 total

     addi x26, x26, -1
     j    _inner

_inner_done:
     addi x25, x25, -1
     j    _outer

_done:
     # x28 should = 64 = 0x40
     wfi
