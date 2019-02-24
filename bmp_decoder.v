module bmp_decoder(
   input clk,
   input rst_n,
   
   input       bmp_dataen,
   input [7:0] bmp_data,

   input ready_to_decod,

   output reg        decode_val,
   output reg [15:0] decode_Xaddress,
   output reg [15:0] decode_Yaddress,
   output reg [23:0] decode_data,

   output reg [31:0] dib_bitmap_width,
   output reg [31:0] dib_bitmap_height,
   
   output reg decod_done
);

reg [7:0] main_state;
localparam IDLE                      = 8'd0,
           F_TYPE                    = 8'd1,
           F_SIZE                    = 8'd2,
           F_RESERVED1               = 8'd3,
           F_RESERVED2               = 8'd4,
           F_OFFSETBITMAP            = 8'd5,
           DIB_HEADER_SIZE           = 8'd6,
           DIB_BM_WIDTH              = 8'd7,
           DIB_BM_HEIGHT             = 8'd8,
           DIB_NUM_CLOCR_PLANE       = 8'd9,
           DIB_BITS_PER_PIXEL        = 8'd10,
           DIB_COMPRESSION           = 8'd11,
           DIB_IMG_SIZE              = 8'd12,
           DIB_XPIXEL_NUM_PER_METER  = 8'd13,
           DIB_VPIXEL_NUM_PER_METER  = 8'd14,
           DIB_NUM_COLOR_PALETTE     = 8'd15,
           DIB_NUM_IMP_COLOR         = 8'd16,
           COLOR_TABLE               = 8'd17,
           DECODE_DONE               = 8'd18,
           COLOR_PLATE               = 8'd19;




reg [23:0] opt_cnt;
/*00 - 01*/reg [15:0] bmp_file_type; // BM BA CI CP IC PT
/*02 - 05*/reg [31:0] bmp_file_size; //
/*06 - 07*/reg [15:0] bmp_reserved1; // Reserve 
/*08 - 09*/reg [15:0] bmp_reserved2; // Reserve 
/*0A - 0D*/reg [31:0] bmp_bitmap_offset;
/*0E - 11*/reg [31:0] dib_size; //Bitmap Header Size
///*12 - 15*/reg [31:0] dib_bitmap_width; //the bitmap width in pixels (signed integer) 
///*16 - 19*/reg [31:0] dib_bitmap_height; //the bitmap height in pixels (signed integer) 
/*1A - 1B*/reg [15:0] dib_num_clocr_plane; //The number of color planes, must be 1 
/*1C - 1D*/reg [15:0] dib_bits_per_pixel; // the number of bits per pixel, which is the color depth of the image. Typical values are 1, 4, 8, 16, 24 and 32.
/*1E - 21*/reg [31:0] dib_cpmpression; //the compression method being used. See the next table for a list of possible values 
/*22 - 25*/reg [31:0] dib_img_size; // the image size. This is the size of the raw bitmap data; a dummy 0 can be given for BI_RGB bitmaps. 
/*26 - 29*/reg [31:0] dib_hpixel_num_per_meter; // the horizontal resolution of the image. (pixel per metre, signed integer) 
/*2A - 2D*/reg [31:0] dib_vpixel_num_per_meter; // the vertical resolution of the image. (pixel per metre, signed integer) 
/*2E - 31*/reg [31:0] dib_num_color_palette; //  	the number of colors in the color palette, or 0 to default to 2n
/*32 - 35*/reg [31:0] dib_num_imp_color; // the number of important colors used, or 0 when every color is important; generally ignored 


wire [47:0] bitmap_width_size_w;
wire [47:0] bitmap_width_size;

wire [7:0] color_plate_size;

reg [15:0] h_cnt;

assign bitmap_width_size_w = dib_bits_per_pixel * dib_bitmap_width;
assign bitmap_width_size   = |bitmap_width_size_w[4:3]? {bitmap_width_size_w[47:5] + 1'd1, 2'd0}: bitmap_width_size_w[47:3];
assign color_plate_size    = bmp_bitmap_offset - 16'd54;


always @(posedge clk, negedge rst_n) begin 
   if(rst_n == 1'd0) begin 
      opt_cnt       <= 24'd0;
      main_state <= IDLE;
      bmp_file_type <= 16'd0;
      bmp_file_size <= 32'd0;
      bmp_reserved1 <= 16'd0;
      bmp_reserved2 <= 16'd0;
      bmp_bitmap_offset <= 32'd0;
      
      decode_val     <= 1'd0;
      decode_Xaddress <= 16'd0;
      decode_Yaddress <= 16'd0;
      decode_data    <= 24'd0;
      decod_done <= 1'd0;
      
      h_cnt      <= 16'd0;

   end 
   else begin 
      case(main_state)
         IDLE: begin 
            if(ready_to_decod) begin 
               main_state <= F_TYPE;
                decod_done <= 1'd0;
            end 
            
            decode_val      <= 1'd0;
            decode_Xaddress <= 16'd0;
            decode_Yaddress <= 16'd0;
            decode_data     <= 24'd0;
            
            h_cnt           <= 16'd0;
         end 
         F_TYPE: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd1) begin 
                    main_state <= F_SIZE;
                    opt_cnt    <= 24'd0;
                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                bmp_file_type[7:0]  <= bmp_data;
                bmp_file_type[15:8] <= bmp_file_type[7:0];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                bmp_file_type <= bmp_file_type;
            end 
         end 
         F_SIZE: begin 
            
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= F_RESERVED1;
                    opt_cnt    <= 24'd0;
                    
                    $display("ID field:%c%c", bmp_file_type[15:8], bmp_file_type[7:0]);
                    
                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 
    
                bmp_file_size[31:24]  <= bmp_data;
                bmp_file_size[23:0] <= bmp_file_size[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                bmp_file_size <= bmp_file_size;
            end 
         end 
         F_RESERVED1: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd1) begin 
                    main_state <= F_RESERVED2;
                    opt_cnt    <= 24'd0;
                    
                    $display("The size of the BMP file in bytes:%8d", bmp_file_size);
                    
                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 
    
                bmp_reserved1[15:8]  <= bmp_data;
                bmp_reserved1[7:0] <= bmp_reserved1[15:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                bmp_reserved1 <= bmp_reserved1;
            end 
         end 
         F_RESERVED2: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd1) begin 
                    main_state <= F_OFFSETBITMAP;
                    opt_cnt    <= 24'd0;

                    $display("Reserved 1");

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 
    
                bmp_reserved2[15:8]  <= bmp_data;
                bmp_reserved2[7:0] <= bmp_reserved2[15:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                bmp_reserved2 <= bmp_reserved2;
            end 
         end 
         F_OFFSETBITMAP: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_HEADER_SIZE;
                    opt_cnt    <= 24'd0;

                    $display("Reserved 2");

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                bmp_bitmap_offset[31:24]  <= bmp_data;
                bmp_bitmap_offset[23:0] <= bmp_bitmap_offset[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                bmp_bitmap_offset <= bmp_bitmap_offset;
            end 
         end 
         DIB_HEADER_SIZE: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_BM_WIDTH;
                    opt_cnt    <= 24'd0;

                    $display("BMP Starting address:%4d", bmp_bitmap_offset);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_size[31:24]  <= bmp_data;
                dib_size[23:0]   <= dib_size[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_size <= dib_size;
            end 
         end 
         DIB_BM_WIDTH: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_BM_HEIGHT;
                    opt_cnt    <= 24'd0;

                    $display("bitmap information header size:%4d", dib_size);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_bitmap_width[31:24]  <= bmp_data;
                dib_bitmap_width[23:0]   <= dib_bitmap_width[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_bitmap_width <= dib_bitmap_width;
            end 
         end 
         DIB_BM_HEIGHT: begin 
            //decode_Xaddress <= dib_bitmap_width - 1;
            decode_Xaddress <= 16'd0;

            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_NUM_CLOCR_PLANE;
                    opt_cnt    <= 24'd0;
                    
                    $display("bitmap width:%4d", dib_bitmap_width);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_bitmap_height[31:24]  <= bmp_data;
                dib_bitmap_height[23:0]   <= dib_bitmap_height[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_bitmap_height <= dib_bitmap_height;
            end 
         end 
         DIB_NUM_CLOCR_PLANE: begin 
            decode_Yaddress <= dib_bitmap_height - 1;

            if(bmp_dataen) begin 
                if(opt_cnt == 24'd1) begin 
                    main_state <= DIB_BITS_PER_PIXEL;
                    opt_cnt    <= 24'd0;

                    $display("Bitmap hight:%4d", dib_bitmap_height);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_num_clocr_plane[15:8]  <= bmp_data;
                dib_num_clocr_plane[7:0]   <= dib_num_clocr_plane[15:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_num_clocr_plane <= dib_num_clocr_plane;
            end 
         end 
         DIB_BITS_PER_PIXEL: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd1) begin 
                    main_state <= DIB_COMPRESSION;
                    opt_cnt    <= 24'd0;

                    $display("The number of color planes:%4d", dib_num_clocr_plane);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_bits_per_pixel[15:8]  <= bmp_data;
                dib_bits_per_pixel[7:0]   <= dib_bits_per_pixel[15:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_bits_per_pixel <= dib_bits_per_pixel;
            end
         end        
         DIB_COMPRESSION: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_IMG_SIZE;
                    opt_cnt    <= 24'd0;

                    $display("The number of bits per pixel:%4d", dib_bits_per_pixel);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_cpmpression[31:24]  <= bmp_data;
                dib_cpmpression[23:0]   <= dib_cpmpression[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_cpmpression <= dib_cpmpression;
            end 
         end            
         DIB_IMG_SIZE: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_XPIXEL_NUM_PER_METER;
                    opt_cnt    <= 24'd0;

                    $display("The compression method:%4d", dib_cpmpression);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_img_size[31:24]  <= bmp_data;
                dib_img_size[23:0]   <= dib_img_size[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_img_size <= dib_img_size;
            end 
         end               
         DIB_XPIXEL_NUM_PER_METER: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_VPIXEL_NUM_PER_METER;
                    opt_cnt    <= 24'd0;

                    $display("The image size:%4d", dib_img_size);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_hpixel_num_per_meter[31:24]  <= bmp_data;
                dib_hpixel_num_per_meter[23:0]   <= dib_hpixel_num_per_meter[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_hpixel_num_per_meter <= dib_hpixel_num_per_meter;
            end
         end 
         DIB_VPIXEL_NUM_PER_METER: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_NUM_COLOR_PALETTE;
                    opt_cnt    <= 24'd0;

                    $display("The horizontal resolution of the image:%4d", dib_hpixel_num_per_meter);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_vpixel_num_per_meter[31:24]  <= bmp_data;
                dib_vpixel_num_per_meter[23:0]   <= dib_vpixel_num_per_meter[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_vpixel_num_per_meter <= dib_vpixel_num_per_meter;
            end
         end   
         DIB_NUM_COLOR_PALETTE: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    main_state <= DIB_NUM_IMP_COLOR;
                    opt_cnt    <= 24'd0;

                    $display("The vertical resolution of the image:%4d", dib_vpixel_num_per_meter);

                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_num_color_palette[31:24]  <= bmp_data;
                dib_num_color_palette[23:0]   <= dib_num_color_palette[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_num_color_palette <= dib_num_color_palette;
            end
         end      
         DIB_NUM_IMP_COLOR: begin 
            if(bmp_dataen) begin 
                if(opt_cnt == 24'd3) begin 
                    //main_state <= DIB_NUM_IMP_COLOR;
                    opt_cnt    <= 24'd0;
                    $display("The number of colors in the color palette:%4d", dib_num_color_palette);
                    if(bmp_bitmap_offset == 32'd54) begin 
                        main_state <= COLOR_TABLE;
                    end 
                    else begin 
                        main_state <= COLOR_PLATE;
                    end                    
                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 

                dib_num_imp_color[31:24]  <= bmp_data;
                dib_num_imp_color[23:0]   <= dib_num_imp_color[31:8];
            end 
            else begin 
                opt_cnt <= opt_cnt;
                dib_num_imp_color <= dib_num_imp_color;
            end
         end 
         COLOR_PLATE:  begin 
            if(bmp_dataen) begin 
                if(opt_cnt == color_plate_size-1) begin 
                    main_state <= COLOR_TABLE;
                    opt_cnt    <= 24'd0;
                end 
                else begin 
                    opt_cnt <= opt_cnt + 24'd1;
                end 
            end 
            else begin 
                opt_cnt <= opt_cnt;
            end 
         
         end 
         COLOR_TABLE: begin 
            case(dib_bits_per_pixel)
                16'd1: begin 

                end 
                16'd2: begin 

                end 
                16'd8: begin 

                end 
                16'd16: begin 

                end 
                16'd24: begin 
                
                    if(bmp_dataen) begin 
                        if(h_cnt == bitmap_width_size - 1) begin 
                            h_cnt <= 48'd0;
                        end 
                        else begin 
                            h_cnt <= h_cnt + 1'd1;
                        end 
                    end 
                    else begin 
                        h_cnt <= h_cnt;
                    end 
                
                    if((bmp_dataen == 1'd1) && (h_cnt < dib_bitmap_width * 3)) begin 
                        
                        if(opt_cnt == 24'd2) begin 
                            opt_cnt    <= 24'd0;
                            decode_val     <= 1'd1;
                        end 
                        else begin 
                            decode_val     <= 1'd0;
                            opt_cnt <= opt_cnt + 24'd1;
                        end 

                        decode_data[23:16]  <= bmp_data;
                        decode_data[15:0]   <= decode_data[23:8];
                    end 
                    else begin 
                        opt_cnt    <= 24'd0;
                        decode_val <= 1'd0;
                    end


                    if(decode_val == 1'd1) begin    
                        if(decode_Xaddress == dib_bitmap_width - 1) begin 
                            decode_Xaddress <= 16'd0;

                            if(decode_Yaddress == 16'd0) begin 
                                main_state <= DECODE_DONE;
                                
                            end 
                            else begin 
                                decode_Yaddress <= decode_Yaddress - 16'd1;
                            end 
                        end 
                        else begin 
                            decode_Xaddress <= decode_Xaddress + 16'd1;
                        end 
                        
                        $display("AddressX:%3d AddressY:%3d  R:%2h  G:%2h  B:%2h", decode_Xaddress,decode_Yaddress, decode_data[23:16], decode_data[15:8], decode_data[7:0]);
                    end  
                    else begin 
                        decode_Xaddress <= decode_Xaddress;
                        decode_Yaddress <= decode_Yaddress;
                    end 

                end 
                16'd32: begin 
                    
                end 


            endcase  


         end          
         DECODE_DONE: begin 
            //$stop;
            decod_done <= 1'd1;
         end 
      endcase 
   end 
end 

endmodule 