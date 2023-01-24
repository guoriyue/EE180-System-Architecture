#==============================================================================
# File:         radixsort.s (PA 1)
#
# Description:  Skeleton for assembly radixsort routine. 
#
#       To complete this assignment, add the following functionality:
#
#       1. Call find_exp. (See radixsort.c)
#          Pass 2 arguments:
#
#          ARG 1: Pointer to the first element of the array
#          (referred to as "array" in the C code)
#
#          ARG 2: Number of elements in the array
#          
#          Remember to use the correct CALLING CONVENTIONS !!!
#          Pass all arguments in the conventional way!
#
#       2. Call radsort. (See radixsort.c)
#          Pass 3 arguments:
#
#          ARG 1: Pointer to the first element of the array
#          (referred to as "array" in the C code)
#
#          ARG 2: Number of elements in the array
#
#          ARG 3: Exponentiated radix
#          (output of find_exp)
#                 
#          Remember to use the correct CALLING CONVENTIONS !!!
#          Pass all arguments in the conventional way!
#
#       2. radsort routine.
#          The routine is recursive by definition, so radsort MUST 
#          call itself. There are also two helper functions to implement:
#          find_exp, and arrcpy.
#          Again, make sure that you use the correct calling conventions!
#
#==============================================================================

.data
HOW_MANY:   .asciiz "How many elements to be sorted? "
ENTER_ELEM: .asciiz "Enter next element: "
ANS:        .asciiz "The sorted list is:\n"
SPACE:      .asciiz " "
EOL:        .asciiz "\n"

.text
.globl main
.globl find_exp
.globl radsort

#==========================================================================
main:
#==========================================================================

    #----------------------------------------------------------
    # Register Definitions
    #----------------------------------------------------------
    # $s0 - pointer to the first element of the array
    # $s1 - number of elements in the array
    # $s2 - number of bytes in the array
    #----------------------------------------------------------
    
    #---- Store the old values into stack ---------------------
    addiu   $sp, $sp, -32
    sw      $ra, 28($sp)

    #---- Prompt user for array size --------------------------
    li      $v0, 4              # print_string
    la      $a0, HOW_MANY       # "How many elements to be sorted? "
    syscall         
    li      $v0, 5              # read_int
    syscall 
    move    $s1, $v0            # save number of elements

    #---- Create dynamic array --------------------------------
    li      $v0, 9              # sbrk
    sll     $s2, $s1, 2         # number of bytes needed
    move    $a0, $s2            # set up the argument for sbrk
    syscall
    move    $s0, $v0            # the addr of allocated memory


    #---- Prompt user for array elements ----------------------
    addu    $t1, $s0, $s2       # address of end of the array
    move    $t0, $s0            # address of the current element
    j       read_loop_cond

read_loop:
    li      $v0, 4              # print_string
    la      $a0, ENTER_ELEM     # text to be displayed
    syscall
    li      $v0, 5              # read_int
    syscall
    sw      $v0, 0($t0)     
    addiu   $t0, $t0, 4

read_loop_cond:
    bne     $t0, $t1, read_loop 

    #---- Call find_exp, then radixsort ------------------------
    # ADD YOUR CODE HERE! 

    # Pass the two arguments in $a0 and $a1 before calling
    # find_exp. Again, make sure to use proper calling 
    # conventions!

    move    $a0, $s0            # a0 is the pointer to the first element of the array
    move    $a1, $s1            # a1 is number of elements in the array
    jal     find_exp
    

    # Pass the three arguments in $a0, $a1, and $a2 before
    # calling radsort (radixsort)

    move    $a2, $v0            # a2 is return value of find_exp
    move    $a0, $s0            # a0 is the pointer to the first element of the array
    move    $a1, $s1            # a1 is number of elements in the array
    jal     radsort

    #---- Print sorted array -----------------------------------
    li      $v0, 4              # print_string
    la      $a0, ANS            # "The sorted list is:\n"
    syscall

    #---- For loop to print array elements ---------------------
    
    #---- Initiazing variables ---------------------------------
    move    $t0, $s0            # address of start of the array
    addu    $t1, $s0, $s2       # address of end of the array
    j       print_loop_cond

print_loop:
    li      $v0, 1              # print_integer
    lw      $a0, 0($t0)         # array[i]
    syscall
    li      $v0, 4              # print_string
    la      $a0, SPACE          # print a space
    syscall            
    addiu   $t0, $t0, 4         # increment array pointer

print_loop_cond:
    bne     $t0, $t1, print_loop

    li      $v0, 4              # print_string
    la      $a0, EOL            # "\n"
    syscall          

    #---- Exit -------------------------------------------------
    lw      $ra, 28($sp)
    addiu   $sp, $sp, 32
    jr      $ra


# ADD YOUR CODE HERE! 

radsort: 
    # a0 is the pointer to the first element of the array `array'
    # a1 is number of elements in the array `n'
    # a2 is exp `exp'
    
    # You will have to use a syscall to allocate
    # temporary storage (mallocs in the C implementation)

    #---- Store the old values into stack ---------------------
    addiu   $sp, $sp, -32
    sw      $s0, 0($sp)
    sw      $s1, 4($sp)
    sw      $s2, 8($sp)
    sw      $s3, 12($sp)
    sw      $s4, 16($sp)
    sw      $s5, 20($sp)
    sw      $s6, 24($sp)
    sw      $s7, 28($sp)

    addiu	$sp, $sp, -32		# allocate memory for new frame
    sw      $ra, 28($sp)        # save $ra
    sw      $a0, 24($sp)        # save $a0
    sw      $a1, 20($sp)        # save $a1
    sw      $a2, 16($sp)        # save $a2

    sltiu   $t2, $a1, 2         # if (n < 2)
    bne     $t2, $0, radsort_return     # return 
    beq     $a2, $0, radsort_return     # return if exp == 0

    move    $s5, $a0            # the start of array
    move    $s6, $a2            # the exp

    #---- Create dynamic array for children --------------------
    li      $v0, 9              # sbrk
    li      $a0, 10          # a0 = RADIX
    sll     $a0, $a0, 2          # 4 * RADIX
    syscall
    move    $s3, $v0            # the addr of allocated memory for children

    #---- Create dynamic array for children_len ----------------
    li      $v0, 9              # sbrk
    li      $a0, 10          # 4 * RADIX
    sll     $a0, $a0, 2         # 4 * RADIX
    syscall
    move    $s4, $v0            # the addr of allocated memory for children_len

    # store children and children_len start in stack
    sw      $s3, 12($sp)        # store children start in stack
    sw		$s4, 8($sp)		    # store children_len start in stack

    move    $t3, $s4            # the start of children_len(for initialization)
    addu    $t2, $s4, $a0       # end of children_len array

    j initialization_loop_cond  # after initialization, t1 is changed

initialization_loop:
    sw      $0, 0($t3)          # save 0 to array
    addiu   $t3, $t3, 4         # increment pointer

initialization_loop_cond:
    bne     $t3, $t2, initialization_loop

    li      $t3, 10          # RADIX = 10 = $t3
    sll     $t4, $a1, 2         # number of bytes in array
    addu    $t4, $s5, $t4       # end of array
    move    $t5, $s5            # the start of array(for iteration)
    
    j assign_buckets_loop_cond 


assign_buckets_loop:
    lw      $t7, 0($t5)         # array[i]
    div     $t7, $a2            # array[i] / exp
    mflo    $t6                 # array[i] / exp, get quotient

    div     $t6, $t3            # / RADIX
    mfhi    $t6                 # remainder, (array[i] / exp) % RADIX, get sort_index in $t6


    sll     $t6, $t6, 2         # get byte address of sort_index
    addu    $t1, $s4, $t6       # add together to get the address of children_len[sort_index]
    

    lw      $t2, 0($t1)         # children_len[sort_index]
    addu    $t8, $s3, $t6       # get the address of children[sort_index]
    # if (children_len[sort_index] == 0)
    beq     $t2, $0, alloc_bucket
    j       end_if
alloc_bucket:                   # children[sort_index] = malloc(4 * n) n is in $a1
    li      $v0, 9              # sbrk
    sll     $a0, $a1, 2         # 4 * n
    syscall
    sw      $v0, 0($t8)         # children[sort_index] = v0

end_if:
    # children[sort_index][children_len[sort_index]] = array[i]
    sll     $t0, $t2, 2         # children_len[sort_index] to byte address
    lw      $t9, 0($t8)         # get children[sort_index]
    addu    $t9, $t9, $t0       # get the address of children[sort_index][children_len[sort_index]]
    sw      $t7, 0($t9)         # assign children[sort_index][children_len[sort_index]] = array[i]
    # children_len[sort_index]++
    addiu   $t2, $t2, 1         # children_len[sort_index]++
    sw      $t2, 0($t1)         # save children_len[sort_index] back to memory

assign_buckets_loop_update:
    addiu   $t5, $t5, 4         # increment array pointer
assign_buckets_loop_cond:
    bne     $t5, $t4, assign_buckets_loop

    # Call radsort on buckets and then concatenate
    move    $t0, $0             # idx = 0
    move    $t1, $s4            # the start of children_len
    move    $t2, $s3            # the start of children
    sll     $t4, $t3, 2         # number of bytes in these arrays 4 * RADIX
    addu    $t4, $s4, $t4       # end of children_len array(for iteration)

    j recursive_sort_loop_cond

recursive_sort_loop:
    lw      $t6, 0($t1)         # children_len[i]

    beq     $t6, $0, recursive_sort_loop_update

    # len not 0, call radsort and copy to array

    # call radsort
    # save t registers in stack
    addiu   $sp, $sp, -40       # increase stack
    sw      $t0, 0($sp)         # save t0
    sw      $t1, 4($sp)         # save t1
    sw      $t2, 8($sp)         # save t2
    sw      $t3, 12($sp)        # save t3
    sw      $t4, 16($sp)        # save t4
    sw      $t5, 20($sp)        # save t5
    sw      $t6, 24($sp)        # save t6
    sw      $t7, 28($sp)        # save t7
    sw      $t8, 32($sp)        # save t8
    sw      $t9, 36($sp)        # save t9

    lw      $a0, 0($t2)         # children[i]
    lw      $a1, 0($t1)         # children_len[i]
    div     $s6, $t3            # exp / RADIX
    mflo    $a2                 # exp / RADIX, get new exp
    jal     radsort

    # restore t registers from stack
    lw      $t9, 36($sp)        # load t9
    lw      $t8, 32($sp)        # load t8
    lw      $t7, 28($sp)        # load t7
    lw      $t6, 24($sp)        # load t6
    lw      $t5, 20($sp)        # load t5
    lw      $t4, 16($sp)        # load t4
    lw      $t3, 12($sp)        # load t3
    lw      $t2, 8($sp)         # load t2
    lw      $t1, 4($sp)         # load t1
    lw      $t0, 0($sp)         # load t0
    # decrease stack
    addiu   $sp, $sp, 40

    # copy to array
    
    # load addr of array
    lw      $t7, 24($sp)        # load in array start in stack

    # call copy_array
    # save t registers in stack
    addiu   $sp, $sp, -40       # increase stack
    sw      $t0, 0($sp)         # save t0
    sw      $t1, 4($sp)         # save t1
    sw      $t2, 8($sp)         # save t2
    sw      $t3, 12($sp)        # save t3
    sw      $t4, 16($sp)        # save t4
    sw      $t5, 20($sp)        # save t5
    sw      $t6, 24($sp)        # save t6
    sw      $t7, 28($sp)        # save t7
    sw      $t8, 32($sp)        # save t8
    sw      $t9, 36($sp)        # save t9

    addu    $a0, $t7, $t0       # array+idx
    lw      $a1, 0($t2)         # children[i]
    lw      $a2, 0($t1)         # children_len[i]
    jal     arrcpy

    # restore registers
    lw      $t9, 36($sp)        # load t9
    lw      $t8, 32($sp)        # load t8
    lw      $t7, 28($sp)        # load t7
    lw      $t6, 24($sp)        # load t6
    lw      $t5, 20($sp)        # load t5
    lw      $t4, 16($sp)        # load t4
    lw      $t3, 12($sp)        # load t3
    lw      $t2, 8($sp)         # load t2
    lw      $t1, 4($sp)         # load t1
    lw      $t0, 0($sp)         # load t0
    # decrease stack
    addiu   $sp, $sp, 40

    # update idx
    lw      $t6, 0($t1)         # children_len[i]
    sll     $s2, $t6, 2         # children_len[i] to byte address
    addu    $t0, $t0, $s2       # idx += children_len[i]

recursive_sort_loop_update:
    addiu   $t1, $t1, 4         # increment children_len pointer
    addiu   $t2, $t2, 4         # increment children pointer
recursive_sort_loop_cond:
    bne     $t1, $t4, recursive_sort_loop

radsort_return:
    lw      $ra, 28($sp)        # load in ra
    addiu   $sp, $sp, 32        # pop stack

    # restore registers
    lw      $s7, 28($sp)        # load in s7
    lw      $s6, 24($sp)        # load in s6
    lw      $s5, 20($sp)        # load in s5
    lw      $s4, 16($sp)        # load in s4
    lw      $s3, 12($sp)        # load in s3
    lw      $s2, 8($sp)         # load in s2
    lw      $s1, 4($sp)         # load in s1
    lw      $s0, 0($sp)         # load in s0
    addiu   $sp, $sp, 32        # pop stack
    jr      $ra                 # return

arrcpy:                         # void copy_array(unsigned *dst, unsigned *src, unsigned n)
    #----------------------------------------------------------
    # $a0 - pointer to the dst array
    # $a1 - pointer to the src array
    # $a2 - number of elements in the array
    #----------------------------------------------------------
    move    $t0, $a0            # start of dst array
    sll     $t1, $a2, 2         # number of bytes in array
    addu    $t1, $a0, $t1       # end of array
    move    $t2, $a1            # start of src array
    j       copy_loop_cond

copy_loop:
    lw      $t3, 0($t2)         # load src word
    sw      $t3, 0($t0)         # save loaded src word to dst array
    addiu   $t0, $t0, 4         # increment dst pointer
    addiu   $t2, $t2, 4         # increment src pointer

copy_loop_cond:
    bne     $t0, $t1, copy_loop

    jr      $ra                 # return

find_exp:                       # unsigned find_exp(unsigned *array, unsigned n)
    #----------------------------------------------------------
    # $a0 - pointer to the dst array
    # $a1 - number of elements in the array
    #----------------------------------------------------------

    move    $t0, $a0            # start of array
    sll     $t2, $a1, 2         # number of bytes in array
    addu    $t1, $t0, $t2       # end of array

    lw      $t3, 0($t0)         # unsigned largest = array[0];
    j       find_max_loop_cond

find_max_loop:
    lw      $t4, 0($t0)         # array[i]
    sltu    $t5, $t3, $t4       # largest < array[i]
    beq     $t5, $0, find_max_loop_update # jump if not largest < array[i]
    move    $t3, $t4            # largest = array[i];
find_max_loop_update:
    addiu   $t0, $t0, 4         # increment array pointer
find_max_loop_cond:
    bne     $t1, $t0, find_max_loop

    li      $t7, 1                      # exp = 1
    li      $t5, 10                  # $t5 = RADIX
    j       find_exp_loop_cond          # while (largest >= RADIX)

find_exp_loop:
    div     $t3, $t5
    mflo    $t3                  # largest = largest / RADIX
    mult    $t7, $t5
    mflo    $t7                  # 32 least significant bits of multiplication to $t7

find_exp_loop_cond:
    bge     $t3, $t5, find_exp_loop     # jump if largest >= RADIX, continue while loop

find_exp_return:
    move    $v0, $t7            # return exp
    jr      $ra                 # return









