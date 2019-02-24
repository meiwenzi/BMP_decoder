`timescale 1ns/1fs

module tb;

//parameter buffer_deep = 1479166;//b 24bit
//parameter buffer_deep = 120054;
parameter buffer_deep = 61926;
parameter h_size = 701;
parameter v_size = 703;

reg [7:0] bmp_buffer [buffer_deep - 1:0];
reg [23:0] buffer     [h_size * v_size - 1: 0];

reg clk;
reg rst_n;

reg       bmp_dataen;
reg [7:0] bmp_data;

reg ready_to_decod;

reg [31:0] cnt;

reg [31:0] cnt1;

wire       decode_val;
wire [23:0] decode_data;

wire [15:0] decode_Xaddress;
wire [15:0] decode_Yaddress;

wire decod_done;

integer i, fp;

initial begin 
    clk = 0;
    rst_n = 0;
    ready_to_decod = 0;
    //$readmemh("../bmp", bmp_buffer);
    $readmemh("../b_1bit", bmp_buffer);
    fp=$fopen("../figureRGB3", "w");
    #100;
    
    ready_to_decod = 1;
    
    #100;
    rst_n = 1;

    #100;
    ready_to_decod = 2;

end 

always #5 clk = ~clk;

bmp_decoder bmp_decoder_ins(
   .clk            (clk),
   .rst_n          (rst_n),
   .bmp_dataen     (bmp_dataen),
   .bmp_data       (bmp_data),
   .ready_to_decod (ready_to_decod),
   .decode_val     (decode_val),
   .decode_Xaddress(decode_Xaddress),
   .decode_Yaddress(decode_Yaddress),
   .decode_data    (decode_data),

   //.dib_bitmap_width (h_size)，
   //.dib_bitmap_height(v_size)，
    
   .decod_done     (decod_done)
);

always @(posedge clk, negedge rst_n) begin 
    if(rst_n == 1'd0) begin 
        cnt1 <= 32'd0;
    end 
    else begin 
        if(decode_val) begin 
            buffer[decode_Yaddress * h_size + decode_Xaddress] <= decode_data;
        end 
        
        if(decod_done) begin 
        
            //$fdisplay(fp,"%06h", buffer[cnt1]);
            $fdisplay(fp,"%02h", buffer[cnt1][23:16]);
            $fdisplay(fp,"%02h", buffer[cnt1][15:8]);
            $fdisplay(fp,"%02h", buffer[cnt1][7:0]);
        
            if(cnt1 == (h_size * v_size - 1)) begin 
                $fclose(fp);
                $stop;
            end 
            else begin 
                cnt1 <= cnt1 + 1'd1;
            end
        end 
    end 
end 

always @(posedge clk, negedge rst_n) begin 
    if(rst_n == 1'd0) begin 
        bmp_dataen <= 1'd0;
        bmp_data   <= 8'd0;
        cnt        <= 32'd0;
    end 
    else begin 
        if(cnt == buffer_deep) begin 
            cnt <= cnt;
            bmp_dataen <= 1'd0;
        end 
        else begin 
            bmp_dataen <= 1'd1;
            bmp_data   <= bmp_buffer[cnt];
            cnt        <= cnt + 32'd1;
        end 
    end 
end 

endmodule 















