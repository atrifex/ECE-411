
module cache_control
(
    input clk,

    /* Datapath controls */
    input lru_in, d_in0, d_in1, hit0, hit1,
    output logic load_lru, lru_set, pmemwdata_sel,
    output logic load_d0, load_v0, load_TD0, d_set0, v_set0,
    output logic load_d1, load_v1, load_TD1, d_set1, v_set1,
    output logic [1:0] pmemaddr_sel,

    /* CPU signals */
    input mem_read, mem_write,
    output logic mem_resp,

    /* Memory signals */
    input pmem_resp,
    output logic pmem_read, pmem_write
);

/* List of states */
enum int unsigned {
    process_request, fetch_cline, write_back
} state, next_state;

always_comb
begin : state_actions
    /* Default output assignments */
    load_lru = 0; lru_set = 0;
    pmemwdata_sel = 0;
    load_d0 = 0; load_v0 = 0; load_TD0 = 0;
    d_set0 = 0; v_set0 = 0;
    load_d1 = 0; load_v1 = 0; load_TD1 = 0;
    d_set1 = 0; v_set1 = 0;
    pmemaddr_sel = 2'b00;
    mem_resp = 0; pmem_read = 0; pmem_write = 0;


    case (state)
        process_request: begin
            if(hit0 & (mem_read ^ mem_write)) begin
                if(mem_write) begin
                    d_set0 = 1;
                    load_d0 = 1;
	                 load_TD0 = 1;
                end
                lru_set = 1;
                load_lru = 1;
                mem_resp = 1;
	             pmemwdata_sel = 0;
            end
            if(hit1 & (mem_read ^ mem_write)) begin
                if(mem_write) begin
                    d_set1 = 1;
                    load_d1 = 1;
	                 load_TD1 = 1;
                end
                lru_set = 0;
                load_lru = 1;
                mem_resp = 1;
 	             pmemwdata_sel = 1;
            end
        end
        fetch_cline: begin
            pmem_read = 1;
            if(lru_in == 0) begin
                v_set0 = 1;
                d_set0 = 0;
                load_v0 = 1;
                load_d0 = 1;
                load_TD0 = 1;
            end else begin
                v_set1 = 1;
                d_set1 = 0;
                load_v1 = 1;
                load_d1 = 1;
                load_TD1 = 1;
            end
        end
        write_back: begin
            pmem_write = 1;
            pmemwdata_sel = lru_in;
            if(lru_in == 0)
                pmemaddr_sel = 2'b01;
            else
                pmemaddr_sel = 2'b10;
        end
        default:;
    endcase


end

always_comb
begin : next_state_logic
    next_state = state;

    case (state)
        process_request: begin
            if(~(hit1 | hit0) & (mem_read ^ mem_write)) begin
                if((d_in0 == 1 && lru_in == 0) || (d_in1 == 1 && lru_in == 1))
                    next_state = write_back;
                else
                    next_state = fetch_cline;
            end
        end
        fetch_cline: begin
            if(pmem_resp == 1)
                next_state = process_request;
        end
        write_back: begin
            if(pmem_resp == 1)
                next_state = fetch_cline;
        end
        default: next_state = process_request;
    endcase


end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end


endmodule : cache_control
