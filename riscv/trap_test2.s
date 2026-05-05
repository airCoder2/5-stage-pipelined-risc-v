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

     # === Phase 1: long preamble, fill registers ===
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
     # x17 (a7) intentionally skipped — avoid RARS syscall side effects
     addi x18, zero, 18
     addi x19, zero, 19
     addi x20, zero, 20
     addi x21, zero, 21
     addi x22, zero, 22
     addi x23, zero, 23
     addi x24, zero, 24

     # === Trap 1: ecall immediately after register fill ===
     ecall

     # === Phase 2: post-trap-1 activity ===
     addi x10, zero, 31
     addi x11, zero, 32
     addi x12, zero, 33
     addi x13, zero, 34
     addi x14, zero, 35
     addi x15, zero, 36
     addi x16, zero, 37

     # === Trap 2: ecall after some work ===
     ecall

     # === Phase 3: more register activity ===
     addi x18, zero, 41
     addi x19, zero, 42
     addi x20, zero, 43
     addi x21, zero, 44
     addi x22, zero, 45
     addi x23, zero, 46
     addi x24, zero, 47
     addi x5,  zero, 50
     addi x6,  zero, 51
     addi x7,  zero, 52

     # === Trap 3: ecall deep in stream ===
     ecall

     # === Phase 4: epilogue, verify flow continues cleanly ===
     addi x10, zero, 61
     addi x11, zero, 62
     addi x12, zero, 63
     addi x13, zero, 64
     addi x14, zero, 65
     addi x15, zero, 66
     addi x16, zero, 67
     addi x18, zero, 68
     addi x19, zero, 69
     addi x20, zero, 70

end:
     wfi
