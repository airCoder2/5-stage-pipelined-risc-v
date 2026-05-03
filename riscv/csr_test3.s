.text
    j main

main:
    # ═══════════════════════════════════════════════════════
    # BLOCK 1: x0 rd discards but CSR still writes
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0xF
    csrrwi  x0, uscratch, 0x0
    csrrsi  x0, uscratch, 0x5
    csrrci  x0, uscratch, 0x1
    csrrw   x6, uscratch, x0
    # expect: x6 == 4

    # ═══════════════════════════════════════════════════════
    # BLOCK 2: csrrs/csrrc rs1=x0 must not modify CSR
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0xA
    csrrs   x5, uscratch, x0
    csrrc   x6, uscratch, x0
    csrrw   x7, uscratch, x0
    # expect: x5==0xA, x6==0xA, x7==0xA

    # ═══════════════════════════════════════════════════════
    # BLOCK 3: csrrsi/csrrci imm=0 must not modify CSR
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x7
    csrrsi  x5, uscratch, 0x0
    csrrci  x6, uscratch, 0x0
    csrrw   x7, uscratch, x0
    # expect: x5==7, x6==7, x7==7

    # ═══════════════════════════════════════════════════════
    # BLOCK 4: rd==rs1 same register
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0xB
    csrrwi  x0, uepc,     0x0
    csrrw   x5, uscratch, x0        # x5 = 0xB, uscratch = 0
    csrrw   x5, uepc,     x5        # x5 = old uepc = 0, uepc = 0xB
    csrrw   x6, uepc,     x0        # x6 = 0xB
    # expect: x5==0, x6==0xB

    # ═══════════════════════════════════════════════════════
    # BLOCK 5: two consecutive writes to same rd, latest wins
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x7
    csrrwi  x0, uepc,     0x3
    csrrw   x5, uscratch, x0        # x5 = 7
    csrrw   x5, uepc,     x0        # x5 = 3  (must overwrite)
    addi    x6, x5, 0x0             # x6 = 3
    # expect: x6 == 3

    # ═══════════════════════════════════════════════════════
    # BLOCK 6: WAR chain — rd of N is rs1 of N+1 is rd of N+2
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrwi  x0, uepc,     0x2
    csrrwi  x0, ucause,   0x3
    csrrw   x5, uscratch, x0        # x5=1,  uscratch=0
    csrrw   x6, uepc,     x5        # x6=2,  uepc=1
    csrrw   x7, ucause,   x6        # x7=3,  ucause=2
    csrrw   x28, uscratch, x7       # x28=0, uscratch=3
    csrrw   x29, uepc,    x0        # x29=1
    csrrw   x30, ucause,  x0        # x30=2
    csrrw   x5,  uscratch, x0       # x5=3
    # expect: x6==2, x7==3, x28==0, x29==1, x30==2, x5==3

    # ═══════════════════════════════════════════════════════
    # BLOCK 7: ping pong all five CSRs, swap values
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrwi  x0, uepc,     0x2
    csrrwi  x0, ucause,   0x3
    csrrwi  x0, utvec,    0x4
    csrrwi  x0, ustatus,  0x1
    csrrw   x5,  uscratch, x0
    csrrw   x6,  uepc,     x0
    csrrw   x7,  ucause,   x0
    csrrw   x28, utvec,    x0
    csrrw   x29, ustatus,  x0
    csrrw   x0,  uscratch, x6       # uscratch = 2
    csrrw   x0,  uepc,     x7       # uepc = 3
    csrrw   x0,  ucause,   x28      # ucause = 4
    csrrw   x0,  utvec,    x29      # utvec = 1
    csrrw   x0,  ustatus,  x5       # ustatus = 1 (bit0 of x5=1)
    csrrw   x5,  uscratch, x0
    csrrw   x6,  uepc,     x0
    csrrw   x7,  ucause,   x0
    csrrw   x28, utvec,    x0
    csrrw   x29, ustatus,  x0
    # expect: x5==2, x6==3, x7==4, x28==1, x29==1

    # ═══════════════════════════════════════════════════════
    # BLOCK 8: triple RMW chain same CSR all six instructions
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x0
    csrrwi  x5, uscratch, 0x1       # x5=0,  uscratch=1
    csrrsi  x6, uscratch, 0x2       # x6=1,  uscratch=3
    csrrsi  x7, uscratch, 0x4       # x7=3,  uscratch=7
    csrrci  x28, uscratch, 0x3      # x28=7, uscratch=4
    csrrci  x29, uscratch, 0x4      # x29=4, uscratch=0
    csrrw   x30, uscratch, x0       # x30=0
    # expect: x5==0, x6==1, x7==3, x28==7, x29==4, x30==0

    # ═══════════════════════════════════════════════════════
    # BLOCK 9: CSR->ALU->CSR->ALU->CSR 5 deep
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrw   x5, uscratch, x0        # x5=1
    addi    x5, x5, 0x1             # x5=2
    csrrw   x0, uepc,     x5        # uepc=2
    csrrw   x6, uepc,     x0        # x6=2
    addi    x6, x6, 0x1             # x6=3
    csrrw   x0, ucause,   x6        # ucause=3
    csrrw   x7, ucause,   x0        # x7=3
    addi    x7, x7, 0x1             # x7=4
    csrrw   x0, utvec,    x7        # utvec=4
    csrrw   x28, utvec,   x0        # x28=4
    addi    x28, x28, 0x1           # x28=5
    csrrwi  x0, ustatus,  0x1
    csrrw   x29, ustatus, x0        # x29=1
    add     x30, x28, x29           # x30=6
    # expect: x5==2, x6==3, x7==4, x28==5, x29==1, x30==6

    # ═══════════════════════════════════════════════════════
    # BLOCK 10: four consecutive overwrites same CSR,
    #           collect all old values, sum them
    # ═══════════════════════════════════════════════════════
    csrrwi  x0,  uscratch, 0x1
    csrrwi  x5,  uscratch, 0x2      # x5=1
    csrrwi  x6,  uscratch, 0x3      # x6=2
    csrrwi  x7,  uscratch, 0x4      # x7=3
    csrrw   x28, uscratch, x0       # x28=4, uscratch=0
    add     x29, x5,  x6            # x29=3
    add     x29, x29, x7            # x29=6
    add     x29, x29, x28           # x29=10
    # expect: x5==1, x6==2, x7==3, x28==4, x29==10

    # ═══════════════════════════════════════════════════════
    # BLOCK 11: interleave all five CSRs with ALU ops
    #           maximum register pressure
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x3
    csrrwi  x0, uepc,     0x5
    csrrwi  x0, ucause,   0x6
    csrrwi  x0, utvec,    0x7
    csrrwi  x0, ustatus,  0x1
    csrrw   x5,  uscratch, x0       # x5=3
    csrrw   x6,  uepc,     x0       # x6=5
    csrrw   x7,  ucause,   x0       # x7=6
    csrrw   x28, utvec,    x0       # x28=7
    csrrw   x29, ustatus,  x0       # x29=1
    xor     x30, x5,  x6            # x30=6
    xor     x30, x30, x7            # x30=0
    xor     x30, x30, x28           # x30=7
    xor     x30, x30, x29           # x30=6
    csrrw   x0,  uscratch, x30      # uscratch=6
    csrrw   x0,  uepc,     x30      # uepc=6
    csrrw   x5,  uscratch, x0       # x5=6
    csrrw   x6,  uepc,     x0       # x6=6
    # expect: x30==6, x5==6, x6==6

    # ═══════════════════════════════════════════════════════
    # BLOCK 12: ustatus UIE only — exhaustive mask check
    #           try to set bits 1-4, only bit 0 and 4 survive
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, ustatus, 0x0
    csrrsi  x0, ustatus, 0x1        # set bit 0
    csrrw   x5, ustatus, x0         # x5 = 1
    csrrsi  x0, ustatus, 0x1        # set bit 0 again (no change)
    csrrw   x6, ustatus, x0         # x6 = 1
    csrrci  x0, ustatus, 0x1        # clear bit 0
    csrrw   x7, ustatus, x0         # x7 = 0
    csrrsi  x0, ustatus, 0x1        # set again
    csrrci  x28, ustatus, 0x1       # x28=1, ustatus=0
    csrrw   x29, ustatus, x0        # x29=0
    # expect: x5==1, x6==1, x7==0, x28==1, x29==0

    # ═══════════════════════════════════════════════════════
    # BLOCK 13: forward distance stress — 1, 2, 3 cycles gap
    #           for every CSR register
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrw   x5, uscratch, x0        # x5=1, dist=1 forward below
    csrrs   x0, uepc,     x5        # uepc|=1,  dist=1

    csrrwi  x0, uscratch, 0x2
    csrrw   x6, uscratch, x0        # x6=2
    nop
    csrrs   x0, ucause,   x6        # ucause|=2, dist=2

    csrrwi  x0, uscratch, 0x4
    csrrw   x7, uscratch, x0        # x7=4
    nop
    nop
    csrrs   x0, utvec,    x7        # utvec|=4,  dist=3

    csrrw   x28, uepc,    x0        # x28=1
    csrrw   x29, ucause,  x0        # x29=2
    csrrw   x30, utvec,   x0        # x30=4
    # expect: x28==1, x29==2, x30==4

    # ═══════════════════════════════════════════════════════
    # BLOCK 14: the ultimate — all hazards simultaneously
    #           RAW WAR WAW, all CSRs, all instrs, ALU mixed
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrw   x5, uscratch, x0        # x5=1
    csrrsi  x0, uepc,     0x2       # uepc=2
    csrrw   x6, uepc,     x5        # x6=2, uepc=1      (x5 fwd)
    csrrsi  x0, ucause,   0x4       # ucause=4
    csrrw   x7, ucause,   x6        # x7=4, ucause=2    (x6 fwd)
    csrrwi  x0, utvec,    0x1
    csrrs   x28, utvec,   x7        # x28=1, utvec|=4=5 (x7 fwd)
    csrrci  x29, utvec,   0x1       # x29=5, utvec=4    (fwd)
    csrrw   x30, utvec,   x0        # x30=4             (fwd)
    add     x5,  x28, x29           # x5=6
    add     x5,  x5,  x30           # x5=10
    csrrwi  x0,  uscratch, 0x0
    csrrs   x0,  uscratch, x5       # uscratch|=10, rs1=x5 fwd
    csrrsi  x6,  uscratch, 0x5      # x6=10, uscratch|=5=15
    csrrci  x7,  uscratch, 0x7      # x7=15, uscratch&=~7=8
    csrrw   x28, uscratch, x0       # x28=8
    csrrwi  x0,  ustatus,  0x1
    csrrw   x29, ustatus,  x0       # x29=1
    xor     x30, x28, x29           # x30=9
    # expect: x5==10, x6==10, x7==15, x28==8, x29==1, x30==9

done:
    j trap_handler_end

trap_handler:
    csrrw x28, uepc,   x0
    csrrw x29, ucause, x0

trap_handler_end:
    wfi
