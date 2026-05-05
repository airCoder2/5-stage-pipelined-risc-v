#
# traps.s — Full CSR stress test
#
# x17 (a7) NEVER written
# x28 = trap counter, expected = 10 at end
#

     .text
     j main

handler:
     csrrw  x10, uepc,  zero
     addi   x10, x10, 4
     csrrw  zero, uepc, x10
     csrrw  x11, ucause,   zero
     addi   x28, x28, 1
     csrrw  zero, uscratch, x28
     csrrsi zero, ustatus,  0x1   # re-enable before uret
     uret

main:
     la     x10, handler
     csrrw  zero, utvec,    x10
     csrrsi zero, ustatus,  0x1
     csrrwi zero, uscratch, 0x0
     csrrwi zero, ucause,   0x0
     csrrwi zero, uepc,     0x0
     addi   x28, zero, 0

     ecall                        # TRAP 1

     csrrw  x10, ucause,   zero   # x10 = 8
     csrrw  x11, uscratch, zero   # x11 = 1

     addi   x10, zero, 0xAB
     csrrw  zero, uscratch, x10

     ecall                        # TRAP 2

     csrrw  x12, uscratch, zero   # x12 = 2

     ecall                        # TRAP 3
     ecall                        # TRAP 4
     ecall                        # TRAP 5

     la     x10, handler
     csrrw  x11, utvec, x10
     csrrw  x12, utvec, zero
     csrrw  zero, utvec, x12

     ecall                        # TRAP 6

     csrrw  x10, ucause,    zero
     csrrw  zero, uscratch, x10
     csrrw  x11, uscratch,  zero

     ecall                        # TRAP 7

     csrrwi zero, uie, 0x0
     csrrw  x10,  uie, zero
     csrrsi zero, uie, 0x0
     csrrw  x11,  uie, zero
     csrrwi zero, uie, 0x0

     ecall                        # TRAP 8

     csrrw  x11, uscratch, zero
     csrrw  x12, uepc,     zero
     csrrw  x13, ucause,   zero
     csrrw  x14, utvec,    zero
     csrrw  x15, ustatus,  zero
     csrrw  x16, uie,      zero

     ecall                        # TRAP 9

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

     ecall                        # TRAP 10 — uret lands on wfi

     # x28 should = 10
end:
     wfi