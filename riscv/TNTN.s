li x1, 0        
li x2, 3000     
li x3, 0        

loop1:
    andi x4, x1, 1      
    bne  x4, x0, odd    
    add  x3, x3, x1     
    jal  x0, next1
odd:
    sub  x3, x3, x1     
next1:
    addi x1, x1, 1
    blt  x1, x2, loop1  

wfi
