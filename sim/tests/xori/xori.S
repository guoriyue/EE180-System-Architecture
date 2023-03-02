###############################################################################
# File         : xor.S
# Project      : EE180 Lab 2: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Test the functionality of the 'xor' instruction.
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
    ori     $t0, $0, 0xbeef     # A = 0xbeef
    nop
    xor     $t3, $t0, 0x5926   # D = xor(A,0x5926) = 0xe7c9
    nop
    xor     $t4, $t3, 0xe7c8     # E = xor(0xe7c8,D) = 0x1
    nop
    sw      $t4, 4($s0)         # Set the test result
    sw      $s1, 0($s0)         # Set 'done'

$done:
    j       $done
    nop

    .end boot
