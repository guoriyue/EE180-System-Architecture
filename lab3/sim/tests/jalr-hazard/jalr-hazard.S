###############################################################################
# File         : jalr.S
# Project      : EE180 Lab 3: Digital System Architecture
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Test the functionality of the 'jalr' instruction.
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
    
    # Set up the address to jump to and save the return address in $ra
    la      $t0, return_address
    jalr    $t1, $t0
    
    # The test should pass if the return value is 1
    or      $v0, $0, $v0
    beq     $v0, $s1, test_passed
    
test_failed:
    ori     $v0, $0, 0          # Set the 'fail' status
    j       $finish
    
test_passed:
    ori     $v0, $0, 1          # Set the 'success' status

$finish:
    sw      $v0, 4($s0)
    sw      $s1, 0($s0)

$done:
    j       $done

return_address:
    addi    $v0, $zero, 1       # Return the value 1
    jr      $ra                 # Jump to the return address saved in $ra

    .end boot
