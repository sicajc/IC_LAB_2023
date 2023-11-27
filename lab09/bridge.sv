module bridge(input clk, INF.bridge_inf inf);
//================================================================
//  integer / genvar / parameter
//================================================================
typedef enum logic [3:0]{
    ST_IDLE,
    ST_AXI_RD_ADDR,
    ST_AXI_RD_DATA,
    ST_AXI_WR_ADDR,
    ST_AXI_WR_DATA,
    ST_AXI_WR_RESP,
    ST_DONE
} state_t;
//  MODE
//  FSM
//================================================================
// logic
//================================================================
state_t cur_st;
logic[63:0] in_data_ff;
logic[7:0] in_addr_ff;

wire read_dram_f  = inf.C_r_wb == 1'b1;
wire write_dram_f = inf.C_r_wb == 1'b0;
wire axi_rd_addr_tx_f = inf.AR_VALID && inf.AR_READY;
wire axi_rd_data_tx_f = inf.R_VALID && inf.R_READY;
wire axi_wr_addr_tx_f = inf.AW_VALID && inf.AW_READY;
wire axi_wr_data_tx_f = inf.W_VALID && inf.W_READY;
wire axi_wr_data_resp_f = inf.B_VALID && inf.B_READY;

//================================================================
// main fsm
//================================================================
always_ff @( posedge clk or negedge inf.rst_n)
begin
    if(~inf.rst_n)
    begin
        cur_st <= ST_IDLE;
    end
    else
    begin
        case(cur_st)
        ST_IDLE:            cur_st <= inf.C_in_valid ? (read_dram_f ? ST_AXI_RD_ADDR:ST_AXI_WR_ADDR):ST_IDLE;
        ST_AXI_RD_ADDR:     cur_st <= axi_rd_addr_tx_f ? ST_AXI_RD_DATA : ST_AXI_RD_ADDR;
        ST_AXI_RD_DATA:     cur_st <= axi_rd_data_tx_f ? ST_IDLE : ST_AXI_RD_DATA;
        ST_AXI_WR_ADDR:     cur_st <= axi_wr_addr_tx_f ? ST_AXI_WR_DATA : ST_AXI_WR_ADDR;
        ST_AXI_WR_DATA:     cur_st <= axi_wr_data_tx_f ? ST_AXI_WR_RESP : ST_AXI_WR_DATA;
        ST_AXI_WR_RESP:     cur_st <= axi_wr_data_resp_f ? ST_IDLE : ST_AXI_WR_RESP;
        default:            cur_st <= ST_IDLE;
        endcase
    end
end

//================================================================
// Datapath
//================================================================
always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
    begin
        in_data_ff <= 0;
        inf.C_out_valid <= 0;
        // inf.C_data_r <= 0;
        inf.AR_VALID <= 0;
        inf.AR_ADDR <= 0;
        inf.R_READY <= 0;
        inf.AW_VALID <= 0;
        inf.AW_ADDR <= 0;
        inf.W_VALID <= 0;
        // inf.W_DATA <= 0;
        inf.B_READY <= 0;
    end
    else
    begin
        case(cur_st)
        ST_IDLE:
        begin
            inf.C_out_valid <= 0;
            // inf.C_data_r <= 0;

            if(inf.C_in_valid)
            begin
                in_data_ff <= inf.C_data_w;
                if(read_dram_f)
                begin
                    inf.AR_VALID <= 1;
                    inf.AR_ADDR  <= {{6'b10_0000},inf.C_addr,3'b000};
                end
                else
                begin
                    inf.AW_VALID <= 1;
                    inf.AW_ADDR  <= {{6'b10_0000},inf.C_addr,3'b000};
                end
            end
            else
            begin
                in_data_ff <= 0;
            end

            inf.R_READY <= 0;
            inf.W_VALID <= 0;
            // inf.W_DATA  <= 0;
            inf.B_READY <= 0;
        end
        ST_AXI_RD_ADDR:
        begin
            if(axi_rd_addr_tx_f)
            begin
                inf.AR_VALID <= 0;
                inf.AR_ADDR  <= 0;

                inf.R_READY  <= 1;
            end
        end
        ST_AXI_RD_DATA:
        begin
            if(axi_rd_data_tx_f)
            begin
                inf.R_READY     <= 0;
                in_data_ff      <= inf.R_DATA;
                inf.C_out_valid <= 1;
            end
        end
        ST_AXI_WR_ADDR:
        begin
            if(axi_wr_addr_tx_f)
            begin
                // inf.W_DATA   <= in_data_ff;
                inf.W_VALID  <= 1;
                inf.AW_ADDR  <= 0;
                inf.AW_VALID <= 0;
            end
        end
        ST_AXI_WR_DATA:
        begin
            if(axi_wr_data_tx_f)
            begin
                // inf.W_DATA  <= 0;
                inf.W_VALID <= 0;
                inf.B_READY <= 1;
            end
        end
        ST_AXI_WR_RESP:
        begin
            if(axi_wr_data_resp_f)
            begin
                inf.B_READY <= 0;
                inf.C_out_valid <= 1;
            end
        end
        endcase
    end
end
// Add one state to prevent C_data_r getting incorrect value
assign inf.W_DATA   = cur_st == ST_AXI_WR_DATA ? in_data_ff : 0;
assign inf.C_data_r = cur_st == ST_IDLE        ? in_data_ff : 0;

endmodule