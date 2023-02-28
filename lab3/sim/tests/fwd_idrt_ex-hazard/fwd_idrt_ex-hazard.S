###############################################################################
# File         : fwd_idrs_ex.S
# Project      : EE180 Lab 2: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Test the functionality of forwarding from EX to ID.Rs
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
    ori     $t2, $0, 0x000f     # Prepare the test value
    ori     $t0, $0, 0xfff0
    or      $t1, $t0, $t2       # $t1 = 0xffff
    xori    $t2, $t1, 0xfffe
    sw      $t2, 4($s0)         # Set the test result
    sw      $s1, 0($s0)         # Set 'done'

$done:
    j       $done

    .end boot
