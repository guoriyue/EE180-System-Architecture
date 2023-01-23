beq     $s0, $0, malloc_children_len # if equal to 0 if (children_len[sort_index] == 0), jump to malloc


malloc_children_len:
    li      $v0, 9              # sbrk
    sll     $s8, $a1, 2         # get byte n
    move    $a0, $s8            # set up the argument for sbrk
    syscall
    move    $s3, $v0            # the addr of allocated memory for children[sort_index], $s3 is still the address of children[sort_index]
