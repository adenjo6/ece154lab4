// ucsbece154a_datapath.v
// All Rights Reserved
// Copyright (c) 2023 UCSB ECE
// Distribution Prohibited


module ucsbece154a_datapath (
    input               clk, reset,
    input               RegWrite_i,
    input         [2:0] ImmSrc_i,
    input               ALUSrc_i,
    input               PCSrc_i,
    input         [1:0] ResultSrc_i,
    input         [2:0] ALUControl_i,
    output              zero_o,
    output reg   [31:0] pc_o,
    input        [31:0] instr_i,
    output wire  [31:0] aluresult_o, writedata_o,
    input        [31:0] readdata_i
);

`include "ucsbece154a_defines.vh"



/// Your code here
wire [6:0] opcode   = instr_i[6:0];
wire [4:0] rd       = instr_i[11:7];
wire [2:0] funct3   = instr_i[14:12];
wire [4:0] rs1      = instr_i[19:15];
wire [4:0] rs2      = instr_i[24:20];
wire [6:0] funct7   = instr_i[31:25];

reg [31:0] immext;
always @(*) begin
    case (ImmSrc_i)
        imm_Itype: // I-type immediate
            immext = {{20{instr_i[31]}}, instr_i[31:20]};
        imm_Stype: // S-type immediate
            immext = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
        imm_Btype: // B-type immediate
            immext = {{19{instr_i[31]}}, instr_i[31], instr_i[7],
                       instr_i[30:25], instr_i[11:8], 1'b0};
        imm_Jtype: // J-type immediate
            immext = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12],
                       instr_i[20], instr_i[30:21], 1'b0};
        imm_Utype: // U-type immediate
            immext = {instr_i[31:12], 12'b0};
        default:
            immext = 32'b0;
    endcase
end

wire [31:0] rd1, rd2;
rf register_file (
    .clk(clk),
    .we(RegWrite_i),
    .ra1(rs1),
    .ra2(rs2),
    .wa(rd),
    .wd(result),
    .rd1(rd1),
    .rd2(rd2)
);

wire [31:0] srcA = rd1;
wire [31:0] srcB = ALUSrc_i ? immext : rd2;

wire [31:0] alu_result;
wire        zero;

assign zero_o       = zero;
assign aluresult_o  = alu_result;

alu alu_inst (
    .a(srcA),
    .b(srcB),
    .alu_control(ALUControl_i),
    .result(alu_result),
    .zero(zero)
);

wire [31:0] pcplus4  = pc_o + 4;
wire [31:0] pcbranch = pc_o + immext;
wire [31:0] pcnext   = PCSrc_i ? pcbranch : pcplus4;

always @(posedge clk or posedge reset) begin
    if (reset)
        pc_o <= 0;
    else
        pc_o <= pcnext;
end

reg [31:0] result;

always @(*) begin
    case (ResultSrc_i)
        ResultSrc_ALU:  result = alu_result;   // ALU result
        ResultSrc_load: result = readdata_i;   // Data loaded from memory
        ResultSrc_jal:  result = pcplus4;      // PC + 4 (for jal instruction)
        ResultSrc_lui:  result = immext;       // Immediate value (for lui)
        default:        result = 32'b0;
    endcase
end

assign writedata_o = rd2;
// Use name "rf" for a register file module so testbench file work properly (or modify testbench file) 


endmodule
