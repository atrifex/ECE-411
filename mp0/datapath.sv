import lc3b_types::*;

module datapath
(
    input clk,

    /* control signals */
    input pcmux_sel,
    input load_pc,

	 input storemux_sel
	 
    /* declare more ports here */
);

/* declare internal signals */
lc3b_word pcmux_out;
lc3b_word pc_out;
lc3b_word br_add_out;
lc3b_word pc_plus2_out;

// internal signals for store mux
lc3b_reg sr1;
lc3b_reg dest;
lc3b_reg storemux_out;


/*
 * PC
 */
mux2 pcmux
(
    .sel(pcmux_sel),
    .a(pc_plus2_out),
    .b(br_add_out),
    .f(pcmux_out)
);

// name-to-name instantiation of module
//mux2 #(.width(3)) storemux
//(
//	.sel(storemux_sel),
//	.a(sr1),
//	.b(dest),
//	.f(storemux_out)
//);

// alternate instantiation of storemux using positional mapping
mux2 #(3) storemux
(
	storemux_sel,
	sr1,
	dest,
	storemux_out
);


register pc
(
    .clk,
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

endmodule : datapath
