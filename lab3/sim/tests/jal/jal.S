###############################################################################
# File         : jal.S
# Project      : EE180 Lab 3: Digital System Architecture
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Test the functionality of the 'jal' instruction.
#
###############################################################################


    .section .boot, "x"
    .balign 4
    .set    noreorder
    .global boot
    .ent    boot
boot:
    lui     $s0, 0x8002         # Load the base address of the status/test registers
    ori     $s1, $0, 1          # Prepare the 'done' status
    ori     $v0, $0, 0          # Prepare the 'fail' status
    jal     return_function     # Call the function and save the return address in $ra
    or      $v0, $0, $v0        # The test should success if return 1

$finish:
    nop
    nop
    sw      $v0, 4($s0)
    sw      $s1, 0($s0)

$done:
    j       $done
    nop

return_function:
    addi    $v0, $zero, 1       # Return the value 1
    jr      $ra                 # Jump to the return address saved in $ra

    .end boot
