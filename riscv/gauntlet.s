#
# gauntlet.s — The Gauntlet: a single comprehensive RV32I stress test.
#
# Tests in one program:
#   - Deep recursive call stack (Fibonacci, recursive)
#   - Nested loops with complex branch patterns
#   - Memory access patterns (store/load matrix, row-major traversal)
#   - Arithmetic intensity (bitwise ops, shifts, comparisons, sign tricks)
#   - Subroutine linkage discipline (ra/fp/sp save+restore every frame)
#   - Topological-style DFS with a visited bitmask
#
# Expected results written to data segment starting at `results`:
#   results[0]  = fib(8)            = 21       (0x00000015)
#   results[1]  = checksum of 4x4 matrix after fill = sum of mat[i][j]=i*4+j
#                 = 0+1+2+...+15    = 120      (0x00000078)
#   results[2]  = popcount(0xDEADBEEF)         = 24       (0x00000018)
#   results[3]  = dfs_order bitmask (all 4 nodes visited) = 0x0F
#
# Assemble & run in RARS. Inspect Memory starting at label `results`.
#
# Instruction set used: identical to grendel.s —
#   li la j jr add addi sub sw lw mv beq slli srli srai
#   slt slti and andi or ori xor xori neg ebreak wfi
#

.data

# ── output ──────────────────────────────────────────────────────────────
results:
        .word   0 0 0 0          # [0]=fib [1]=matrix_sum [2]=popcount [3]=dfs

# ── matrix (4x4 words) ──────────────────────────────────────────────────
matrix:
        .word   0 0 0 0
        .word   0 0 0 0
        .word   0 0 0 0
        .word   0 0 0 0

# ── DFS state ───────────────────────────────────────────────────────────
# adjacency encoded as one word per source node (bit i = edge to node i)
# graph:  0->1, 0->2,  1->3,  2->3   (DAG, all 4 reachable from 0)
adj:
        .word   6                # node 0 → nodes 1,2  (0b0110)
        .word   8                # node 1 → node 3     (0b1000)
        .word   8                # node 2 → node 3     (0b1000)
        .word   0                # node 3 → (none)     (0b0000)

visited_mask:
        .word   0

# ── scratch / stack ─────────────────────────────────────────────────────
dfs_stack:
        .word   0 0 0 0 0 0 0 0  # 8-deep software stack for DFS

.text

# ════════════════════════════════════════════════════════════════════════
#  BOOT
# ════════════════════════════════════════════════════════════════════════
        li   sp, 0x10011000
        li   fp, 0
        la   ra, _halt
        j    main
_halt:
        j    _done

# ════════════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════════════
main:
        addi sp, sp, -16
        sw   ra,  12(sp)
        sw   fp,   8(sp)
        mv   fp,  sp

        # ── 1. Fibonacci(8) ─────────────────────────────────────────────
        li   t4, 8               # arg: n=8
        la   ra, _after_fib
        j    fib
_after_fib:
        # t2 = fib(8) = 21
        la   t3, results
        sw   t2, 0(t3)

        # ── 2. Fill matrix[i][j] = i*4+j, then sum all entries ─────────
        la   ra, _after_matrix
        j    matrix_fill_and_sum
_after_matrix:
        # t2 = sum = 120
        la   t3, results
        sw   t2, 4(t3)

        # ── 3. Popcount(0xDEADBEEF) ─────────────────────────────────────
        # load constant in two halves (li sign-extends 12-bit imm)
        # 0xDEAD = 57005,  0xBEEF = 48879
        # Build 0xDEADBEEF:  upper = 0xDEADB000 via lui-equivalent trick
        # We only have li/la, so we compose with shifts and or:
        #   0xDEAD0000 | 0x0000BEEF
        li   t4, 0xDEAD          # t4 = 0x0000DEAD
        slli t4, t4, 16          # t4 = 0xDEAD0000
        li   t5, 0xBEEF
        li   a1, 0x0000FFFF
        and  t5, t5, a1          # mask to 16 bits (0x0000BEEF)
        or   t4, t4, t5          # t4 = 0xDEADBEEF
        la   ra, _after_popcount
        j    popcount
_after_popcount:
        # t2 = 24
        la   t3, results
        sw   t2, 8(t3)

        # ── 4. DFS from node 0, record visited bitmask ──────────────────
        li   t4, 0               # start node = 0
        la   ra, _after_dfs
        j    dfs
_after_dfs:
        la   t3, visited_mask
        lw   t2, 0(t3)
        la   t3, results
        sw   t2, 12(t3)

        # ── epilogue ─────────────────────────────────────────────────────
        mv   sp, fp
        lw   ra, 12(sp)
        lw   fp,  8(sp)
        addi sp, sp, 16
        jr   ra


# ════════════════════════════════════════════════════════════════════════
#  fib(n)  —  recursive Fibonacci
#  arg:    t4 = n
#  return: t2 = fib(n)
#  Destroys: t2, t3, t4, t5
# ════════════════════════════════════════════════════════════════════════
fib:
        addi sp, sp, -24
        sw   ra, 20(sp)
        sw   fp, 16(sp)
        mv   fp, sp
        sw   t4, 24(fp)          # save n

        # if n <= 1 return n
        lw   t2, 24(fp)
        slti t3, t2, 2           # t3 = (n < 2)
        beq  t3, x0, _fib_recurse
        mv   t2, t2              # return value already in t2
        j    _fib_ret

_fib_recurse:
        lw   t4, 24(fp)
        addi t4, t4, -1          # n-1
        la   ra, _fib_back1
        j    fib
_fib_back1:
        sw   t2, 8(fp)           # save fib(n-1)

        lw   t4, 24(fp)
        addi t4, t4, -2          # n-2
        la   ra, _fib_back2
        j    fib
_fib_back2:
        lw   t3, 8(fp)           # restore fib(n-1)
        add  t2, t3, t2          # fib(n-1) + fib(n-2)

_fib_ret:
        mv   sp, fp
        lw   ra, 20(sp)
        lw   fp, 16(sp)
        addi sp, sp, 24
        jr   ra


# ════════════════════════════════════════════════════════════════════════
#  matrix_fill_and_sum()
#  Fills matrix[i][j] = i*4+j for i,j in [0,3], then sums all 16 words.
#  return: t2 = sum (expected 120)
#  Registers: t2=sum/tmp, t3=tmp, t4=i, t5=j, t6=addr
# ════════════════════════════════════════════════════════════════════════
matrix_fill_and_sum:
        addi sp, sp, -16
        sw   ra, 12(sp)
        sw   fp,  8(sp)
        mv   fp, sp

        # fill pass
        li   t4, 0               # i = 0
_mfs_outer:
        slti t3, t4, 4
        beq  t3, x0, _mfs_fill_done

        li   t5, 0               # j = 0
_mfs_inner:
        slti t3, t5, 4
        beq  t3, x0, _mfs_next_row

        # value = i*4 + j
        slli t2, t4, 2           # i*4
        add  t2, t2, t5          # i*4 + j

        # addr = &matrix + (i*4+j)*4
        la   t6, matrix
        slli t3, t4, 4           # i*16  (row offset in bytes)
        add  t6, t6, t3
        slli t3, t5, 2           # j*4   (col offset in bytes)
        add  t6, t6, t3
        sw   t2, 0(t6)

        addi t5, t5, 1
        j    _mfs_inner

_mfs_next_row:
        addi t4, t4, 1
        j    _mfs_outer

_mfs_fill_done:
        # sum pass
        li   t2, 0               # sum = 0
        li   t4, 0               # idx = 0
        la   t6, matrix
_mfs_sum_loop:
        slti t3, t4, 16
        beq  t3, x0, _mfs_sum_done
        slli t3, t4, 2
        add  t3, t6, t3
        lw   t3, 0(t3)
        add  t2, t2, t3
        addi t4, t4, 1
        j    _mfs_sum_loop

_mfs_sum_done:
        mv   sp, fp
        lw   ra, 12(sp)
        lw   fp,  8(sp)
        addi sp, sp, 16
        jr   ra


# ════════════════════════════════════════════════════════════════════════
#  popcount(x)
#  arg:    t4 = x
#  return: t2 = number of set bits in x
#  Uses the classic shift-and-mask Hamming-weight algorithm (32 iterations).
# ════════════════════════════════════════════════════════════════════════
popcount:
        addi sp, sp, -16
        sw   ra, 12(sp)
        sw   fp,  8(sp)
        mv   fp, sp
        sw   t4, 16(fp)          # save x

        li   t2, 0               # count = 0
        li   t3, 32              # loop 32 times
        li   t5, 0               # bit index

_pc_loop:
        slt  t6, t5, t3          # t6 = (i < 32)
        beq  t6, x0, _pc_done

        lw   t4, 16(fp)          # reload x
        slli t6, t5, 0           # t6 = i (no-op shift, just copy via slli 0)
        # shift x right by i: we want bit i of x
        # We only have slli/srli/srai — use srli with the loop counter
        # Emulate: tmp = x >> i  using repeated srli-by-1 inside inner pass
        # Instead: extract bit i cleanly using the shift-loop trick below.
        # Approach: build mask = 1 << i, and t4 & mask, then slt x0 < result
        li   t6, 1
        # shift mask left by t5 positions using a small shift loop
        li   t0, 0               # shift counter
        mv   a0, t6              # a0 = mask (start = 1)
_pc_shift_mask:
        slt  a1, t0, t5          # a1 = (shift_counter < i)
        beq  a1, x0, _pc_shift_done
        slli a0, a0, 1
        addi t0, t0, 1
        j    _pc_shift_mask
_pc_shift_done:
        and  a0, t4, a0          # a0 = x & mask
        beq  a0, x0, _pc_bit_zero  # if zero, bit not set
        addi t2, t2, 1           # bit is set, count++
_pc_bit_zero:

        addi t5, t5, 1
        j    _pc_loop

_pc_done:
        mv   sp, fp
        lw   ra, 12(sp)
        lw   fp,  8(sp)
        addi sp, sp, 16
        jr   ra


# ════════════════════════════════════════════════════════════════════════
#  dfs(start_node)
#  Iterative DFS using a software stack (dfs_stack array).
#  Marks each visited node in visited_mask (bit i = node i visited).
#  arg:    t4 = start node index
# ════════════════════════════════════════════════════════════════════════
dfs:
        addi sp, sp, -16
        sw   ra, 12(sp)
        sw   fp,  8(sp)
        mv   fp, sp

        # software stack pointer: s_top stored in 8(fp) already used by fp
        # use 0(fp) as our soft-stack top index
        sw   x0, 0(fp)           # soft_top = 0

        # push start node
        la   t6, dfs_stack
        sw   t4, 0(t6)           # dfs_stack[0] = start
        li   t3, 1
        sw   t3, 0(fp)           # soft_top = 1

_dfs_loop:
        lw   t3, 0(fp)           # t3 = soft_top
        beq  t3, x0, _dfs_done  # if top==0, stack empty

        # pop
        addi t3, t3, -1
        sw   t3, 0(fp)           # soft_top--
        la   t6, dfs_stack
        slli t5, t3, 2
        add  t5, t6, t5
        lw   t4, 0(t5)           # t4 = popped node

        # check visited
        li   t2, 1
        # build mask = 1 << t4
        li   t0, 0
        mv   a0, t2
_dfs_shift:
        slt  a1, t0, t4
        beq  a1, x0, _dfs_shift_done
        slli a0, a0, 1
        addi t0, t0, 1
        j    _dfs_shift
_dfs_shift_done:
        la   t2, visited_mask
        lw   t3, 0(t2)
        and  a1, t3, a0
        beq  a1, x0, _dfs_visit  # if zero → not visited → visit
        j    _dfs_loop            # nonzero → already visited → skip

_dfs_visit:
        # mark visited
        la   t2, visited_mask
        lw   t3, 0(t2)
        or   t3, t3, a0
        sw   t3, 0(t2)

        # push unvisited neighbors (iterate bits of adj[node])
        la   t6, adj
        slli t5, t4, 2
        add  t5, t6, t5
        lw   t5, 0(t5)           # t5 = adj[node] bitmask

        li   t0, 0               # neighbor index = 0
_dfs_neighbors:
        slti a1, t0, 4           # only 4 nodes
        beq  a1, x0, _dfs_loop

        # check if neighbor bit t0 is set in t5
        li   t2, 1
        li   t1, 0
        mv   a0, t2
_dfs_nbr_shift:
        slt  a1, t1, t0
        beq  a1, x0, _dfs_nbr_shift_done
        slli a0, a0, 1
        addi t1, t1, 1
        j    _dfs_nbr_shift
_dfs_nbr_shift_done:
        and  a0, t5, a0
        beq  a0, x0, _dfs_nbr_next  # if zero → neighbor not set → skip

        # push neighbor t0 onto soft stack
        lw   t3, 0(fp)           # soft_top
        la   t6, dfs_stack
        slli t2, t3, 2
        add  t2, t6, t2
        sw   t0, 0(t2)           # dfs_stack[soft_top] = neighbor
        addi t3, t3, 1
        sw   t3, 0(fp)           # soft_top++

_dfs_nbr_next:
        addi t0, t0, 1
        j    _dfs_neighbors

_dfs_done:
        mv   sp, fp
        lw   ra, 12(sp)
        lw   fp,  8(sp)
        addi sp, sp, 16
        jr   ra


# ════════════════════════════════════════════════════════════════════════
#  DONE
# ════════════════════════════════════════════════════════════════════════
_done:
        wfi
