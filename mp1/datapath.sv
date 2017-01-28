import lc3b_types::*;

module datapath
(
    input clk,

    /* control signals */
    input load_pc,
    input load_ir,
    input load_regfile,
    input load_mar,
    input load_mdr,
    input load_cc,
    input [1:0] pcmux_sel,
    input storemux_sel,
    input [1:0] alumux_sel,
    input [1:0] regfilemux_sel,
    input marmux_sel,
    input mdrmux_sel,
    input lc3b_aluop aluop,
    output lc3b_opcode opcode,
    output ir_5,
    output br_enable,

    /* Memory signals */
    input lc3b_word mem_rdata,
    output lc3b_word mem_address,
    output lc3b_word mem_wdata
);

/***** declare internal signals *****/
// MDR and MAR Signals
lc3b_word marmux_out, mdrmux_out;
lc3b_word mdr_out;
assign mem_wdata = mdr_out;

// Signals related to PC
lc3b_word pcmux_out, pc_out;
lc3b_word br_add_out, pc_plus2_out;
lc3b_word adj9_offset, adj6_offset;
lc3b_offset9 offset9;
lc3b_offset6 offset6;

// Signals related to IR
lc3b_reg sr1, sr2, dest;
lc3b_reg storemux_out;
lc3b_imm5 imm5;

// signals related to regfile
lc3b_word regfilemux_out;
lc3b_word sr1_out, sr2_out, alumux_out;

// signals related to alu
lc3b_word alu_out;

// signals related to branch
lc3b_nzp gencc_out, cc_out;

/***** PC *****/
// register that stores the current PC value
register pc
(
    .clk,
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

// Mux used to select the value that will be placed into the PC register
mux4 pcmux
(
    .sel(pcmux_sel),
    .a(pc_plus2_out),
    .b(br_add_out),
    .c(alu_out),
    .d(16'h0000),
    .f(pcmux_out)
);

// increments PC value to access next instruction
plus2 pcPlus2
(
	.in(pc_out),
	.out(pc_plus2_out)
);

adder br_adder
(
	.a(pc_out),
	.b(adj9_offset),
	.c(br_add_out)
);

adj #(9) offset9_adjuster
(
	.in(offset9),
	.out(adj9_offset)
);

/*****  IR *****/
ir IR
(
	// inputs
    .clk,
    .load(load_ir),
    .in(mdr_out),

	// outputs
    .opcode(opcode),
    .dest(dest),
	.src1(sr1),
	.src2(sr2),
    .offset6(offset6),
    .offset9(offset9),
    .imm5(imm5),
    .ir_5(ir_5)
);

mux2 #(3) storemux
(
	.sel(storemux_sel),
	.a(sr1),
	.b(dest),
	.f(storemux_out)
);


adj #(6) offset6_adjuster
(
	.in(offset6),
	.out(adj6_offset)
);

/***** Regfile *****/
regfile regfile_inst
(
	.clk,
	.load(load_regfile),
	.in(regfilemux_out),
	.src_a(storemux_out),
	.src_b(sr2),
	.dest(dest),
	.reg_a(sr1_out),
	.reg_b(sr2_out)
);

mux4 regfilemux
(
	.sel(regfilemux_sel),
	.a(alu_out),
	.b(mdr_out),
    .c(br_add_out),
    .d(16'h0000),
	.f(regfilemux_out)
);

mux4 alumux
(
	.sel(alumux_sel),
	.a(sr2_out),
	.b(adj6_offset),
    .c($signed(imm5)),
    .d(16'h0000),
	.f(alumux_out)
);

/***** ALU *****/
alu alu_inst
(
    .aluop(aluop),
    .a(sr1_out),
    .b(alumux_out),
    .f(alu_out)
);

/***** Branch Related Modules *****/
gencc gencc_inst
(
	.in(regfilemux_out),
	.out(gencc_out)
);

register #(3) cc
(
    .clk,
    .load(load_cc),
    .in(gencc_out),
    .out(cc_out)
);

cccomp cccomp_inst
(
	.cur_cc(cc_out),
	.br_cc(dest),
	.br_enable(br_enable)
);

/***** MAR *****/
mux2 marmux
(
    .sel(marmux_sel),
    .a(alu_out),
    .b(pc_out),
    .f(marmux_out)
);

register MAR
(
    .clk,
    .load(load_mar),
    .in(marmux_out),
    .out(mem_address)
);

/***** MDR *****/
mux2 mdrmux
(
    .sel(mdrmux_sel),
    .a(alu_out),
    .b(mem_rdata),
    .f(mdrmux_out)
);

register MDR
(
    .clk,
    .load(load_mdr),
    .in(mdrmux_out),
    .out(mdr_out)
);

endmodule : datapath
