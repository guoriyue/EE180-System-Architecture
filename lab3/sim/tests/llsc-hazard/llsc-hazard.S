###############################################################################
# File         : ll.S
# Project      : EE180 Lab 2: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Test the functionality of the 'll' instruction.
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
    lui     $t0, 0              # Load some valid address 0x00003210 to register $t0
    ori     $t0, $t0, 0x3210
    ll      $t1, 0($t0)         # Load-link the value at address $t0 into $t1
    ori     $t2, $0, 2
    sw      $t2, 0($t0)         # Store a new value at address $t0
    sc      $t1, ($t0)     # Store-conditional the value in $t1 to address $t0
    beq     $t1, $0, retry      # If the store-conditional failed, retry the test
    ori     $t1, $0, 0          # If the store-conditional succeeded, set $t1 to 0
    sw      $t1, 4($s0)         # Set the test result
    sw      $s1, 0($s0)         # Set 'done'
    j       $done

retry:
    ll      $t1, 0($t0)         # Load-link the value at address $t0 again
    sc      $t1, ($t0)     # Store-conditional the value in $t1 to address $t0
    sw      $t1, 4($s0)         # Set the test result
    sw      $s1, 0($s0)         # Set 'done'

$done:
    j       $done

    .end boot
