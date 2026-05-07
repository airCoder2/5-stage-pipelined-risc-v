# Proj1_mergesort.s
# Merge Sort on an array of 32 integers
# Array is stored in .data section
# After sorting, array will be in ascending order

.data
array:  .word 95, 3, 47, 82, 16, 63, 29, 71
        .word 58, 14, 90, 37, 5, 78, 42, 61
        .word 88, 23, 55, 11, 74, 33, 67, 8
        .word 49, 86, 20, 44, 99, 2, 70, 38
N:      .word 32

temp:   .word 0, 0, 0, 0, 0, 0, 0, 0
        .word 0, 0, 0, 0, 0, 0, 0, 0
        .word 0, 0, 0, 0, 0, 0, 0, 0
        .word 0, 0, 0, 0, 0, 0, 0, 0

.text
.globl main


# main
#   Sets up arguments and calls merge_sort

main:
    la   a0, array          # a0 = base address of array
    li   a1, 0              # a1 = left index (0)
    li   a2, 31             # a2 = right index (N-1 = 31)
    jal  ra, merge_sort     # call merge_sort(array, 0, 31)

    li   a7, 10             # exit syscall
    ecall


# merge_sort(a0=arr, a1=left, a2=right)

merge_sort:
    # Prologue
    addi sp, sp, -20
    sw   ra,  16(sp)
    sw   s0,  12(sp)
    sw   s1,   8(sp)
    sw   s2,   4(sp)
    sw   s3,   0(sp)

    mv   s0, a0             # s0 = arr
    mv   s1, a1             # s1 = left
    mv   s2, a2             # s2 = right

    # Base case: if left >= right, return
    bge  s1, s2, ms_return

    # Compute mid = left + (right - left) / 2
    sub  t0, s2, s1         # t0 = right - left
    srli t0, t0, 1          # t0 = (right - left) / 2
    add  s3, s1, t0         # s3 = mid

    # Recursive call: merge_sort(arr, left, mid)
    mv   a0, s0
    mv   a1, s1
    mv   a2, s3
    jal  ra, merge_sort

    # Recursive call: merge_sort(arr, mid+1, right)
    mv   a0, s0
    addi a1, s3, 1
    mv   a2, s2
    jal  ra, merge_sort

    # merge(arr, left, mid, right)
    mv   a0, s0
    mv   a1, s1
    mv   a2, s3
    mv   a3, s2
    jal  ra, merge

ms_return:
    # Epilogue
    lw   ra,  16(sp)
    lw   s0,  12(sp)
    lw   s1,   8(sp)
    lw   s2,   4(sp)
    lw   s3,   0(sp)
    addi sp, sp, 20
    jalr zero, ra, 0


# merge(a0=arr, a1=left, a2=mid, a3=right)
#
# Uses temp buffer in .data to hold merged result,
# then copies back into arr[left..right]

merge:
    # Prologue
    addi sp, sp, -28
    sw   ra,  24(sp)
    sw   s0,  20(sp)
    sw   s1,  16(sp)
    sw   s2,  12(sp)
    sw   s3,   8(sp)
    sw   s4,   4(sp)
    sw   s5,   0(sp)

    mv   s0, a0             # s0 = arr base address
    mv   s1, a1             # s1 = left
    mv   s2, a2             # s2 = mid
    mv   s3, a3             # s3 = right

    la   t6, temp           # t6 = base of temp buffer

    mv   t0, s1             # t0 = i (left half pointer)
    addi t1, s2, 1          # t1 = j (right half pointer = mid+1)
    mv   t2, s1             # t2 = k (temp index, starts at left)

merge_loop:
    # if i > mid, go copy remaining right
    blt  s2, t0, copy_right
    # if j > right, go copy remaining left
    blt  s3, t1, copy_left

    # Load arr[i]
    slli t3, t0, 2
    add  t3, s0, t3
    lw   t3, 0(t3)          # t3 = arr[i]

    # Load arr[j]
    slli t4, t1, 2
    add  t4, s0, t4
    lw   t4, 0(t4)          # t4 = arr[j]

    # if arr[i] > arr[j], pick right
    blt  t4, t3, pick_right

pick_left:
    slli t5, t2, 2
    add  t5, t6, t5
    sw   t3, 0(t5)          # temp[k] = arr[i]
    addi t0, t0, 1          # i++
    addi t2, t2, 1          # k++
    j    merge_loop

pick_right:
    slli t5, t2, 2
    add  t5, t6, t5
    sw   t4, 0(t5)          # temp[k] = arr[j]
    addi t1, t1, 1          # j++
    addi t2, t2, 1          # k++
    j    merge_loop

copy_right:
    # while j <= right
    blt  s3, t1, copy_back
    slli t3, t1, 2
    add  t3, s0, t3
    lw   t3, 0(t3)          # arr[j]
    slli t5, t2, 2
    add  t5, t6, t5
    sw   t3, 0(t5)          # temp[k] = arr[j]
    addi t1, t1, 1          # j++
    addi t2, t2, 1          # k++
    j    copy_right

copy_left:
    # while i <= mid
    blt  s2, t0, copy_back
    slli t3, t0, 2
    add  t3, s0, t3
    lw   t3, 0(t3)          # arr[i]
    slli t5, t2, 2
    add  t5, t6, t5
    sw   t3, 0(t5)          # temp[k] = arr[i]
    addi t0, t0, 1          # i++
    addi t2, t2, 1          # k++
    j    copy_left

copy_back:
    mv   t0, s1             # t0 = index = left
copy_back_loop:
    # exit if index > right
    blt  s3, t0, merge_done
    slli t3, t0, 2
    add  t4, t6, t3         # &temp[index]
    lw   t4, 0(t4)          # temp[index]
    add  t5, s0, t3         # &arr[index]
    sw   t4, 0(t5)          # arr[index] = temp[index]
    addi t0, t0, 1          # index++
    j    copy_back_loop

merge_done:
    # Epilogue
    lw   ra,  24(sp)
    lw   s0,  20(sp)
    lw   s1,  16(sp)
    lw   s2,  12(sp)
    lw   s3,   8(sp)
    lw   s4,   4(sp)
    lw   s5,   0(sp)
    addi sp, sp, 28
    jalr zero, ra, 0
