#
# mergesort.s — Recursive Mergesort on a 64-element array (RV32I subset)
#   - Recursion 6 levels deep (log2(64)), large frame stack
#   - Non-local memory writes during merge (writes to a separate scratch buffer)
#   - 64-word working set, strided and non-sequential memory access
#   - Dense branch patterns in merge inner loop
#   - Software division-by-2 via srli in every split
#   - No mul, no ebreak — only base RV32I subset
#
# Expected result:
#   arr[0..63] sorted ascending: 1, 2, 3, ..., 64
#   (array is initialized in reverse: arr[i] = 64 - i)
#
# Instruction set: li la j jr add addi sub sw lw mv beq bne
#                  slli srli srai slt slti and andi or ori xor xori neg wfi
#

.data

# ── 64-element array, initialized reversed (64 down to 1) ───────────────
arr:
        .word 64 63 62 61 60 59 58 57
        .word 56 55 54 53 52 51 50 49
        .word 48 47 46 45 44 43 42 41
        .word 40 39 38 37 36 35 34 33
        .word 32 31 30 29 28 27 26 25
        .word 24 23 22 21 20 19 18 17
        .word 16 15 14 13 12 11 10  9
        .word  8  7  6  5  4  3  2  1

# ── scratch buffer for merge (same size as arr) ──────────────────────────
scratch:
        .word 0 0 0 0 0 0 0 0
        .word 0 0 0 0 0 0 0 0
        .word 0 0 0 0 0 0 0 0
        .word 0 0 0 0 0 0 0 0
        .word 0 0 0 0 0 0 0 0
        .word 0 0 0 0 0 0 0 0
        .word 0 0 0 0 0 0 0 0
        .word 0 0 0 0 0 0 0 0

# ── verification result: 1 = sorted correctly, 0 = error ─────────────────
verify_result:
        .word 0

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
        sw   ra, 12(sp)
        sw   fp,  8(sp)
        mv   fp, sp

        # mergesort(arr, 0, 63)
        la   t4, arr             # t4 = base address of array
        li   t5, 0               # t5 = left  = 0
        li   t6, 63              # t6 = right = 63
        la   ra, _after_sort
        j    mergesort
_after_sort:

        # verify the result is sorted
        la   ra, _after_verify
        j    verify
_after_verify:
        # t2 = 1 if sorted, 0 if not
        la   t3, verify_result
        sw   t2, 0(t3)

        mv   sp, fp
        lw   ra, 12(sp)
        lw   fp,  8(sp)
        addi sp, sp, 16
        jr   ra


# ════════════════════════════════════════════════════════════════════════
#  mergesort(base, left, right)
#  args:  t4 = base (byte address of arr[0])
#         t5 = left  index
#         t6 = right index
#  Sorts arr[left..right] in place using scratch as temp buffer.
#  Destroys: t2, t3, t4, t5, t6
# ════════════════════════════════════════════════════════════════════════
mergesort:
        addi sp, sp, -40
        sw   ra, 36(sp)
        sw   fp, 32(sp)
        mv   fp, sp
        sw   t4, 40(fp)          # save base
        sw   t5, 44(fp)          # save left   (note: args above frame)
        sw   t6, 48(fp)          # save right

        # if left >= right: return (base case)
        slt  t2, t5, t6          # t2 = (left < right)
        beq  t2, x0, _ms_ret

        # mid = left + (right - left) / 2
        #     = left + ((right - left) >> 1)
        lw   t5, 44(fp)
        lw   t6, 48(fp)
        sub  t2, t6, t5          # t2 = right - left
        srli t2, t2, 1           # t2 = (right - left) / 2
        add  t2, t5, t2          # t2 = mid = left + (right-left)/2
        sw   t2, 28(fp)          # save mid

        # mergesort(base, left, mid)
        lw   t4, 40(fp)
        lw   t5, 44(fp)
        lw   t6, 28(fp)
        la   ra, _ms_left_ret
        j    mergesort
_ms_left_ret:

        # mergesort(base, mid+1, right)
        lw   t4, 40(fp)
        lw   t5, 28(fp)
        addi t5, t5, 1           # mid+1
        lw   t6, 48(fp)
        la   ra, _ms_right_ret
        j    mergesort
_ms_right_ret:

        # merge(base, left, mid, right)
        lw   t4, 40(fp)
        lw   t5, 44(fp)
        lw   t6, 28(fp)          # t6 = mid
        lw   t3, 48(fp)          # t3 = right (extra arg passed via t3)
        la   ra, _ms_merge_ret
        j    merge
_ms_merge_ret:

_ms_ret:
        mv   sp, fp
        lw   ra, 36(sp)
        lw   fp, 32(sp)
        addi sp, sp, 40
        jr   ra


# ════════════════════════════════════════════════════════════════════════
#  merge(base, left, mid, right)
#  args:  t4 = base
#         t5 = left
#         t6 = mid
#         t3 = right
#
#  Merges arr[left..mid] and arr[mid+1..right] into scratch,
#  then copies scratch back to arr[left..right].
# ════════════════════════════════════════════════════════════════════════
merge:
        addi sp, sp, -56
        sw   ra, 52(sp)
        sw   fp, 48(sp)
        mv   fp, sp
        sw   t4, 56(fp)          # base
        sw   t5, 60(fp)          # left
        sw   t6, 64(fp)          # mid
        sw   t3, 68(fp)          # right

        # i = left  (index into left half)
        lw   t2, 60(fp)
        sw   t2, 8(fp)           # local: i

        # j = mid+1 (index into right half)
        lw   t2, 64(fp)
        addi t2, t2, 1
        sw   t2, 12(fp)          # local: j

        # k = left  (index into scratch)
        lw   t2, 60(fp)
        sw   t2, 16(fp)          # local: k

# ── main merge loop ──────────────────────────────────────────────────────
_mg_loop:
        # while i <= mid && j <= right
        lw   t2, 8(fp)           # i
        lw   t3, 64(fp)          # mid
        slt  t0, t3, t2          # t0 = (mid < i)  i.e. i > mid
        beq  t0, x0, _mg_check_j
        j    _mg_left_done       # i > mid: left half exhausted

_mg_check_j:
        lw   t2, 12(fp)          # j
        lw   t3, 68(fp)          # right
        slt  t0, t3, t2          # t0 = (right < j)
        beq  t0, x0, _mg_both_valid
        j    _mg_left_done       # j > right: right half exhausted

_mg_both_valid:
        # load arr[i] and arr[j]
        lw   t4, 56(fp)          # base
        lw   t2, 8(fp)           # i
        slli t2, t2, 2
        add  t2, t4, t2
        lw   t0, 0(t2)           # t0 = arr[i]

        lw   t2, 12(fp)          # j
        slli t2, t2, 2
        add  t2, t4, t2
        lw   t1, 0(t2)           # t1 = arr[j]

        # if arr[i] <= arr[j]: scratch[k] = arr[i], i++
        slt  t2, t1, t0          # t2 = (arr[j] < arr[i])
        beq  t2, x0, _mg_take_left

        # take right: scratch[k] = arr[j], j++
        lw   t2, 16(fp)          # k
        slli t2, t2, 2
        la   t3, scratch
        add  t3, t3, t2
        sw   t1, 0(t3)           # scratch[k] = arr[j]
        lw   t2, 12(fp)
        addi t2, t2, 1
        sw   t2, 12(fp)          # j++
        j    _mg_k_inc

_mg_take_left:
        lw   t2, 16(fp)          # k
        slli t2, t2, 2
        la   t3, scratch
        add  t3, t3, t2
        sw   t0, 0(t3)           # scratch[k] = arr[i]
        lw   t2, 8(fp)
        addi t2, t2, 1
        sw   t2, 8(fp)           # i++

_mg_k_inc:
        lw   t2, 16(fp)
        addi t2, t2, 1
        sw   t2, 16(fp)          # k++
        j    _mg_loop

# ── drain remaining left half ────────────────────────────────────────────
_mg_left_done:
        lw   t2, 8(fp)           # i
        lw   t3, 64(fp)          # mid
        slt  t0, t3, t2          # i > mid? (i.e. left half exhausted)
        beq  t0, x0, _mg_drain_left
        j    _mg_drain_right     # left exhausted, drain right instead

_mg_drain_left:
        lw   t2, 8(fp)           # i
        lw   t3, 64(fp)          # mid
        slt  t0, t3, t2          # i > mid?
        beq  t0, x0, _mg_dl_body
        j    _mg_copy_back

_mg_dl_body:
        lw   t4, 56(fp)
        lw   t2, 8(fp)
        slli t2, t2, 2
        add  t2, t4, t2
        lw   t0, 0(t2)           # arr[i]

        lw   t2, 16(fp)
        slli t2, t2, 2
        la   t3, scratch
        add  t3, t3, t2
        sw   t0, 0(t3)           # scratch[k] = arr[i]

        lw   t2, 8(fp)
        addi t2, t2, 1
        sw   t2, 8(fp)           # i++
        lw   t2, 16(fp)
        addi t2, t2, 1
        sw   t2, 16(fp)          # k++
        j    _mg_drain_left

# ── drain remaining right half ───────────────────────────────────────────
_mg_right_done:
_mg_drain_right:
        lw   t2, 12(fp)          # j
        lw   t3, 68(fp)          # right
        slt  t0, t3, t2          # j > right?
        beq  t0, x0, _mg_dr_body
        j    _mg_copy_back

_mg_dr_body:
        lw   t4, 56(fp)
        lw   t2, 12(fp)
        slli t2, t2, 2
        add  t2, t4, t2
        lw   t1, 0(t2)           # arr[j]

        lw   t2, 16(fp)
        slli t2, t2, 2
        la   t3, scratch
        add  t3, t3, t2
        sw   t1, 0(t3)           # scratch[k] = arr[j]

        lw   t2, 12(fp)
        addi t2, t2, 1
        sw   t2, 12(fp)          # j++
        lw   t2, 16(fp)
        addi t2, t2, 1
        sw   t2, 16(fp)          # k++
        j    _mg_drain_right

# ── copy scratch[left..right] back into arr[left..right] ────────────────
_mg_copy_back:
        lw   t2, 60(fp)
        sw   t2, 20(fp)          # idx = left

_mg_copy_loop:
        lw   t2, 20(fp)          # idx
        lw   t3, 68(fp)          # right
        slt  t0, t3, t2          # idx > right?
        beq  t0, x0, _mg_copy_body
        j    _mg_ret

_mg_copy_body:
        lw   t2, 20(fp)
        slli t2, t2, 2
        la   t3, scratch
        add  t3, t3, t2
        lw   t0, 0(t3)           # t0 = scratch[idx]

        lw   t4, 56(fp)
        lw   t2, 20(fp)
        slli t2, t2, 2
        add  t2, t4, t2
        sw   t0, 0(t2)           # arr[idx] = scratch[idx]

        lw   t2, 20(fp)
        addi t2, t2, 1
        sw   t2, 20(fp)          # idx++
        j    _mg_copy_loop

_mg_ret:
        mv   sp, fp
        lw   ra, 52(sp)
        lw   fp, 48(sp)
        addi sp, sp, 56
        jr   ra


# ════════════════════════════════════════════════════════════════════════
#  verify()
#  Checks arr[0..63] is ascending: arr[i] <= arr[i+1] for all i in [0,62]
#  return: t2 = 1 if sorted, 0 if not
# ════════════════════════════════════════════════════════════════════════
verify:
        addi sp, sp, -16
        sw   ra, 12(sp)
        sw   fp,  8(sp)
        mv   fp, sp

        li   t4, 0               # i = 0
        li   t2, 1               # assume sorted

_vfy_loop:
        slti t3, t4, 63          # i < 63?
        beq  t3, x0, _vfy_done

        la   t6, arr
        slli t3, t4, 2
        add  t3, t6, t3
        lw   t0, 0(t3)           # arr[i]
        lw   t1, 4(t3)           # arr[i+1]

        slt  t3, t1, t0          # arr[i+1] < arr[i]?
        beq  t3, x0, _vfy_next
        li   t2, 0               # not sorted
        j    _vfy_done

_vfy_next:
        addi t4, t4, 1
        j    _vfy_loop

_vfy_done:
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
