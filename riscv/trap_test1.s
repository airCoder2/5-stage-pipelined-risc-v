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
     li t0, 0x800
     csrrw zero, uie, t0

     addi x10, zero, 0x8 
     addi x11, zero, 0x9

     addi x10, zero, 0xA
     addi x11, zero, 0xB
                        
     addi x10, zero, 0xC
     addi x11, zero, 0xD
                        
     addi x10, zero, 0xE
     addi x11, zero, 0xF

end:
     wfi
