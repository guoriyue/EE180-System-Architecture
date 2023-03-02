//=============================================================================
// EE180 Lab 3
//
// Instruction fetch module. Maintains PC and updates it. Reads from the
// instruction ROM.
//=============================================================================

module instruction_fetch (
    input clk,
    input rst,
    input en,
    input jump_target,
    input jump_branch,
    input jump_reg,
    input [31:0] jump_target_pc,
    input [31:0] jr_pc_id,
    input [31:0] pc_id,
    input [25:0] instr_id,  // Lower 26 bits of the instruction

    output [31:0] pc
);


    wire [31:0] pc_id_p4 = pc_id + 3'h4;
    wire [31:0] pc_p4 = pc + 3'h4;
    wire [31:0] j_addr = (jump_reg)
                            ? jr_pc_id
                            : {pc_id_p4[31:28], instr_id[25:0], 2'b0};

    wire [31:0] pc_next = (jump_target | jump_reg) ? j_addr : (jump_branch ? jump_target_pc : pc_p4);

    dffare #(32) pc_reg (.clk(clk), .r(rst), .en(en), .d(pc_next), .q(pc));

endmodule