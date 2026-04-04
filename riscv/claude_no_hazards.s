.text
.globl main

main:

########################
# INIT
########################
addi x1, x0, 8
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

addi x2, x0, 3
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# U-TYPE
########################
lui x3, 0x12345
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

auipc x4, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# ALU
########################
add x5, x1, x2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

sub x6, x5, x2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

and x7, x5, x6
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

or x8, x6, x7
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

xor x9, x7, x8
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# IMMEDIATE
########################
andi x10, x9, 7
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

ori x11, x10, 4
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

xori x12, x11, 2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# COMPARE
########################
slt x13, x2, x1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

sltu x14, x1, x2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

slti x15, x1, 10
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

sltiu x16, x2, 5
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# SHIFTS
########################
sll x17, x1, x2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

srl x18, x17, x2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

sra x19, x18, x2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

slli x20, x1, 1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

srli x21, x20, 1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

srai x22, x21, 1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# MEMORY BASE
########################
lui x23, 0x10010
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

addi x23, x23, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# STORE
########################
sw x5, 0(x23)
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# LOADS
########################
lw x24, 0(x23)
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

lb x25, 0(x23)
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

lh x26, 0(x23)
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

lbu x27, 0(x23)
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

lhu x28, 0(x23)
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# BRANCHES
########################
beq x24, x5, L1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

bne x24, x5, L2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

blt x2, x1, L3
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

bge x1, x2, L4
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

bltu x2, x1, L5
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

bgeu x1, x2, L6
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# JUMPS
########################
jal x29, J1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

J1:
jalr x30, x29, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# LABEL TARGETS
########################
L1:
addi x0, x0, 1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

L2:
addi x0, x0, 2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

L3:
addi x0, x0, 3
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

L4:
addi x0, x0, 4
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

L5:
addi x0, x0, 5
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

L6:
addi x0, x0, 6
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0

########################
# END
########################
wfi
