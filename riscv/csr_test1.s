.text
    j main

main:
    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 1: x0 as rd — CSR must still write even when
    #              result is discarded. Then verify CSR held.
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0xF       # uscratch = 0xF, rd=x0 discards
    csrrwi  x0, uscratch, 0x0       # uscratch = 0,   rd=x0 discards
    csrrsi  x0, uscratch, 0x5       # uscratch |= 5,  rd=x0 discards
    csrrci  x0, uscratch, 0x1       # uscratch &= ~1, rd=x0 discards
    csrrw   x6, uscratch, x0        # x6 = 4
    # expect: x6 == 4

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 2: csrrs/csrrc with rs1=x0 must NOT write CSR
    #              spec says: if rs1=x0, CSR is not modified
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0xA       # uscratch = 0xA
    csrrs   x6, uscratch, x0        # x6 = 0xA, uscratch UNCHANGED (rs1=x0)
    csrrc   x7, uscratch, x0        # x7 = 0xA, uscratch UNCHANGED (rs1=x0)
    csrrw   x28, uscratch, x0       # x28 = 0xA, uscratch = 0
    # expect: x6==0xA, x7==0xA, x28==0xA

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 3: csrrsi/csrrci with imm=0 must NOT write CSR
    #              spec says: if uimm=0, CSR is not modified
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x7       # uscratch = 7
    csrrsi  x6, uscratch, 0x0       # x6 = 7, uscratch UNCHANGED (imm=0)
    csrrci  x7, uscratch, 0x0       # x7 = 7, uscratch UNCHANGED (imm=0)
    csrrw   x28, uscratch, x0       # x28 = 7, uscratch = 0
    # expect: x6==7, x7==7, x28==7

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 4: utvec in a full forwarding chain
    #              hasn't been stressed yet
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x3       # uscratch = 3
    csrrw   x5, uscratch, x0        # x5 = 3  (fwd)
    csrrw   x0, utvec,    x5        # utvec = 3  (x5 fwd)
    csrrw   x6, utvec,    x0        # x6 = 3  (fwd)
    addi    x6, x6, 0x1             # x6 = 4
    csrrw   x0, utvec,    x6        # utvec = 4  (x6 fwd through ALU)
    csrrw   x7, utvec,    x0        # x7 = 4
    csrrs   x0, utvec,    x7        # utvec |= 4 = 4  (x7 fwd, rs1=x7)
    csrrw   x28, utvec,   x0        # x28 = 4
    # expect: x6==4, x7==4, x28==4

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 5: write same value to two CSRs, then swap them
    #              forwarding must select correct CSR not just
    #              "most recent write"
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1       # uscratch = 1
    csrrwi  x0, uepc,     0x2       # uepc = 2
    csrrw   x5, uscratch, x0        # x5 = 1  (fwd uscratch)
    csrrw   x6, uepc,     x0        # x6 = 2  (fwd uepc)
    csrrw   x0, uscratch, x6        # uscratch = 2  (swap)
    csrrw   x0, uepc,     x5        # uepc = 1  (swap)
    csrrw   x7,  uscratch, x0       # x7  = 2
    csrrw   x28, uepc,     x0       # x28 = 1
    # expect: x5==1, x6==2, x7==2, x28==1

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 6: write same CONSTANT to all five CSRs back
    #              to back, read all back — forwarding must
    #              not conflate them
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1
    csrrwi  x0, uepc,     0x2
    csrrwi  x0, ucause,   0x3
    csrrwi  x0, ustatus,  0x1       # only bit 0 sticks
    csrrwi  x0, utvec,    0x5
    csrrw   x5,  uscratch, x0       # x5  = 1
    csrrw   x6,  uepc,     x0       # x6  = 2
    csrrw   x7,  ucause,   x0       # x7  = 3
    csrrw   x28, ustatus,  x0       # x28 = 1
    csrrw   x29, utvec,    x0       # x29 = 5
    # expect: x5==1, x6==2, x7==3, x28==1, x29==5

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 7: rd and rs1 are the SAME register
    #              x6 = old CSR, then x6 written into next CSR
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0xB       # uscratch = 0xB
    csrrw   x6, uscratch, x0        # x6 = 0xB, uscratch = 0
    csrrw   x6, uepc,     x6        # x6 = old uepc (0 or whatever), uepc = 0xB
    csrrw   x7, uepc,     x0        # x7 = 0xB
    # expect: x7 == 0xB

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 8: back to back csrrw where rd of instr N
    #              is rs1 of instr N+1 AND rd of instr N+1
    #              is rs1 of instr N+2 — full pipeline WAR
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1       # uscratch = 1
    csrrwi  x0, uepc,     0x2       # uepc = 2
    csrrwi  x0, ucause,   0x3       # ucause = 3
    csrrw   x5, uscratch, x0        # x5 = 1,  uscratch = 0
    csrrw   x6, uepc,     x5        # x6 = 2,  uepc = 1   (x5 fwd)
    csrrw   x7, ucause,   x6        # x7 = 3,  ucause = 2 (x6 fwd)
    csrrw   x28, uscratch, x7       # x28 = 0, uscratch=3 (x7 fwd)
    csrrw   x29, uepc,    x0        # x29 = 1
    csrrw   x30, ucause,  x0        # x30 = 2
    csrrw   x5,  uscratch, x0       # x5  = 3
    # expect: x6==2, x7==3, x28==0, x29==1, x30==2, x5==3

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 9: csrrw rd=x5 followed immediately by
    #              csrrw rd=x5 — second must overwrite first
    #              in regfile, forwarding must give LATEST
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x7       # uscratch = 7
    csrrwi  x0, uepc,     0x3       # uepc = 3
    csrrw   x5, uscratch, x0        # x5 = 7  (first write to x5)
    csrrw   x5, uepc,     x0        # x5 = 3  (second write to x5, must win)
    addi    x6, x5, 0x0             # x6 = x5 = 3  (which x5 forwarded?)
    # expect: x6 == 3

    # ═══════════════════════════════════════════════════════
    # NIGHTMARE 10: ALL registers, ALL instructions, maximum
    #               WAW WAR RAW simultaneously, 10 deep chain
    # ═══════════════════════════════════════════════════════
    csrrwi  x0, uscratch, 0x1       # uscratch=1
    csrrw   x5, uscratch, x0        # x5=1, uscratch=0
    csrrsi  x0, uepc,     0x2       # uepc=2
    csrrw   x6, uepc,     x5        # x6=2, uepc=1      (x5 fwd as rs1)
    csrrsi  x0, ucause,   0x4       # ucause=4
    csrrw   x7, ucause,   x6        # x7=4, ucause=2    (x6 fwd as rs1)
    csrrwi  x0, utvec,    0x1
    csrrs   x28, utvec,   x7        # x28=1, utvec|=4=5 (x7 fwd as rs1)
    csrrci  x29, utvec,   0x1       # x29=5, utvec=4    (fwd from csrrs)
    csrrw   x30, utvec,   x0        # x30=4             (fwd from csrrci)
    add     x5, x28, x29            # x5 = 1+5 = 6
    add     x5, x5,  x30            # x5 = 6+4 = 10
    # expect: x28==1, x29==5, x30==4, x5==10

done:
    j trap_handler_end

trap_handler:
    csrrw x28, uepc,   x0
    csrrw x29, ucause, x0

trap_handler_end:
    wfi
