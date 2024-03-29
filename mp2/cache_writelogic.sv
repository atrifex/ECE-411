import lc3b_types::*;

module cache_writelogic
(
    input pmem_read,
    input lc3b_mem_wmask mem_byte_enable,
    input [2:0] offset,
    input lc3b_word mem_wdata,
    input lc3b_cacheline pmem_rdata, cur_cacheline,
    output lc3b_cacheline output_cacheline
);


logic [7:0] wordselector;

decoder3 decoder3_inst(.encodedvalue(offset),.decodedvalue(wordselector));

generate
	 genvar i;
    for (i=0; i<8; i++)
    begin: module_instant_loop
        mux4 #(8) writelogic_highbyte
        (
            .sel({pmem_read,((~pmem_read)&mem_byte_enable[1]&wordselector[i])}),
            .a(cur_cacheline[(i*16+15):(i*16+8)]),
            .b(mem_wdata[15:8]),
            .c(pmem_rdata[(i*16+15):(i*16+8)]),
            .d(8'h0000),
            .f(output_cacheline[(i*16+15):(i*16+8)])
        );
        mux4 #(8) writelogic_lowbyte
        (
            .sel({pmem_read,((~pmem_read)&mem_byte_enable[0]&wordselector[i])}),
            .a(cur_cacheline[(i*16+7):(i*16)]),
            .b(mem_wdata[7:0]),
            .c(pmem_rdata[(i*16+7):(i*16)]),
            .d(8'h0000),
            .f(output_cacheline[(i*16+7):(i*16)])
        );
    end
endgenerate

endmodule : cache_writelogic
