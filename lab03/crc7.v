module crc7(
        input clk,
        input in_valid,
        input start,
        input rst,
        input[39:0] data,
        output reg crc7,
        output reg out_valid
    );

reg[6:0] crc,crc_wr,poly,cnt;
reg[39:0] data_ff;
reg working_f;
wire done_f = cnt == 0;
reg done_ff;

always @(posedge clk)
begin
    if(rst)
    begin
        working_f <= 0;
        done_ff  <= 0;
    end
    else if(done_f)
    begin
        working_f <= 0;
        done_ff    <= 1;
    end
    else if(start)
    begin
        working_f <= 1;
    end
end

always @(posedge clk)
begin
    if(rst)
    begin
        data_ff <= 0;
        cnt     <= 39;
    end
    else if(done_f)
    begin
        cnt <= 39;
    end
    else if(in_valid)
    begin
        data_ff <= data;
    end
    else if(working_f)
    begin
        data_ff <=  data_ff << 1;
        cnt <= cnt - 1;
    end
end

integer i;
wire data_out = crc[6];
wire data_in  = data_ff[39];
always @(posedge clk)
begin
    if(rst)
    begin
        crc <= 0 ;
    end
    else if(working_f)
    begin
        crc[0] <= data_out ^ data_in;
        crc[1] <= crc[0];
        crc[2] <= crc[1];
        crc[3] <= crc[2] ^ (data_out ^ data_in);
        crc[4] <= crc[3];
        crc[5] <= crc[4];
        crc[6] <= crc[5];
    end
end

endmodule
