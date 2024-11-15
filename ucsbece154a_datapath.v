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

// Use name "rf" for a register file module so testbench file work properly (or modify testbench file) 

wire [31:0] RD1; //Same as SrcA
wire [31:0] RD2;
reg [31:0] SrcA; 
reg [31:0] SrcB;
reg [31:0] ImmExt;
reg [31:0] result;
reg [31:0] PCNext; 
reg [31:0] PCPlus4; 
reg [31:0] PCTarget;




ucsbece154a_alu alu (
    .a_i(SrcA), .b_i(SrcB),
    .alucontrol_i(ALUControl_i),
    .result_o(aluresult_o),
    .zero_o(zero_o)
);

ucsbece154a_rf rf(
    .clk(clk),
    .a1_i(instr_i[19:15]), .a2_i(instr_i[24:20]), .a3_i(instr_i[11:7]),
    .rd1_o(RD1), .rd2_o(RD2),
    .we3_i(RegWrite_i),
    .wd3_i(result)
);

assign writedata_o = RD2; 

initial begin
	pc_o = 0; 
	PCNext = 0;
end

always @ * begin
	//ImmExt
	if(ImmSrc_i == 3'b000)begin
    	ImmExt[31:12] = instr_i[31];
    	ImmExt[11:0] = instr_i[31:20]; //Check this in testing to make sure extension is being done properly
	end 
	else if(ImmSrc_i == 3'b001) begin
    	ImmExt[31:12] = instr_i[31]; 
    	ImmExt[11:5] = instr_i[31:25];
    	ImmExt[4:0] = instr_i[11:7];
	end 
	else if(ImmSrc_i == 3'b010) begin
    	ImmExt[31:12] = instr_i[31]; 
    	ImmExt[11] = instr_i[7];
    	ImmExt[10:5] = instr_i[30:25];
    	ImmExt[4:1] = instr_i[11:8];
    	ImmExt[0] = 0; 
	end
	else if(ImmSrc_i == 3'b011) begin
	ImmExt[31:20] = instr_i[31]; 
	ImmExt[19:12] = instr_i[19:12]; 
	ImmExt[11] = instr_i[20];
	ImmExt[10:1] = instr_i[30:21];
	ImmExt[0] = 0; 
	end 
	else if(ImmSrc_i == 3'b100) begin
	ImmExt[31:12] = instr_i[31:12];
	ImmExt[11:0] = 0; 
	end

	//SrcA Mux
	SrcA = RD1;
	if (ImmSrc_i == 3'b100) begin
		SrcA = 0; 
	end
	

	//SrcB Mux
    	SrcB = RD2;
    	if (ALUSrc_i) begin
        	SrcB = ImmExt;
	end

	//PC Math
	PCPlus4 <= pc_o + 4; 
	PCTarget <= pc_o + ImmExt; 
	PCNext = PCPlus4; 
	if (PCSrc_i) begin
		PCNext <= PCTarget; 
    	end

	//Result Mux
	if (ImmSrc_i == 3'b100)begin
		result = aluresult_o;
	end else begin
		result = {20'b00000000000000000000,aluresult_o[11:0]};
	end
    	if (ResultSrc_i == 2'b01) begin
		result = readdata_i; 
    	end else if (ResultSrc_i == 2'b10) begin
		result = PCPlus4;
	end
end

always @ (posedge clk) begin
	pc_o <= PCNext;
end
endmodule
