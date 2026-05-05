.text
     j main
handler:
     csrrw  t0, uepc, zero
     addi   t0, t0, 4
     csrrw  zero, uepc, t0
     uret

main:
     la     t0, handler
     csrrw  zero, utvec, t0
     csrrsi zero, ustatus, 0x1

     addi x10, zero, 1
     addi x11, zero, 2
     ecall                    # trap 1

     addi x10, zero, 3
     addi x11, zero, 4
     ecall                    # trap 2

     addi x10, zero, 5
     addi x11, zero, 6
     ecall                    # trap 3

     addi x10, zero, 7
     addi x11, zero, 8

end:
     wfi
