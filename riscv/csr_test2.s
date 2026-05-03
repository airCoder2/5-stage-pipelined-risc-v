.text
    j main

main:
    # Write 0xDEAD via csrrw, then immediately read back
    li      t0, 0xDEAD
    csrrw   zero, uscratch, t0   # uscratch = 0xDEAD
    csrrw   t1, uscratch, zero   # t1 should = 0xDEAD (bypass)

    # Write 7 via csrrwi, then immediately read back
    csrrwi  zero, uscratch, 7    # uscratch = 7
    csrrw   t1, uscratch, zero   # t1 should = 7 (bypass)

done:
    wfi
