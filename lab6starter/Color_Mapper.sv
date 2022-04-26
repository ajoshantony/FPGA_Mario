//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//                                                                       --
//    Fall 2014 Distribution                                             --
//                                                                       --
//    For use with ECE 385 Lab 7                                         --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module  color_mapper ( input        [9:0] BallX, BallY, DrawX, DrawY, Ball_size,
								input [7:0] keycode,
							  input Clk_50,blank,pixel_clk,
                       output logic [7:0]  Red, Green, Blue );
    
    logic ball_on;
	 
 /* Old Ball: Generated square box by checking if the current pixel is within a square of length
    2*Ball_Size, centered at (BallX, BallY).  Note that this requires unsigned comparisons.
	 
    if ((DrawX >= BallX - Ball_size) &&
       (DrawX <= BallX + Ball_size) &&
       (DrawY >= BallY - Ball_size) &&
       (DrawY <= BallY + Ball_size))

     New Ball: Generates (pixelated) circle by using the standard circle formula.  Note that while 
     this single line is quite powerful descriptively, it causes the synthesis tool to use up three
     of the 12 available multipliers on the chip!  Since the multiplicants are required to be signed,
	  we have to first cast them from logic to int (signed by default) before they are multiplied). */
	  
    int DistX, DistY, Size;
	 assign DistX = DrawX - BallX;
    assign DistY = DrawY - BallY;
    assign Size = Ball_size;
	 
    always_comb
    begin:Ball_on_proc
    if ((DrawX >= BallX) &&
       (DrawX < BallX + Ball_size) &&
       (DrawY >= BallY) &&
       (DrawY < BallY + Ball_size))
            ball_on = 1'b1;
    else 
            ball_on = 1'b0;
		
     end 
  
 mario_standing_rom mario_standing_ROM_0(.read_address(m_stand_addr), .Clk(Clk_50),.data_Out(m_stand_RGB)
);


logic [18:0] back_addr;
logic [23:0] back_RGB;
platform_block_rom platform_block_mod(.read_address(back_addr),.Clk(Clk_50),.data_Out(back_RGB)
);

logic [7:0] brick_addr;
logic [23:0] brick_RGB;
brick_rom brick_rom_mod(.read_address(brick_addr),.Clk(Clk_50),.data_Out(brick_RGB)
);

//RGB to ignore : ee35ff
logic [9:0] sprite_x,sprite_y,spriteB_x,spriteB_y;
logic [7:0] m_stand_addr;
logic [23:0] m_stand_RGB;
always_comb
begin:sprite_addr_calc
sprite_x = DrawX - BallX;
sprite_y = DrawY - BallY;

if(keycode == 8'h07) //right
begin
m_stand_addr = sprite_x + sprite_y*16;
end

else if(keycode == 8'h04)//left
begin
m_stand_addr = (15-sprite_x) + sprite_y*16;
end

else //jump
begin
m_stand_addr = sprite_x + sprite_y*16; //replace with jump mario
end

back_addr = DrawX[3:0]+DrawY[3:0]*16; //(DrawX%16)+(DrawY%16)*16

brick_addr = DrawX[3:0]+DrawY[3:0]*16;
//640 by 480 

end


    always_ff @ (posedge pixel_clk)
    begin:RGB_Display
	if(blank == 1)
	begin
        if ((ball_on == 1'b1) && (m_stand_RGB != 24'hee35ff) ) 
        begin 
            Red = m_stand_RGB[23:16];
            Green = m_stand_RGB[15:8];
            Blue = m_stand_RGB[7:0];
        end
		  
        else if(DrawY>=416)
        begin 
            Red = back_RGB[23:16];
            Green = back_RGB[15:8];
            Blue = back_RGB[7:0];
        end
		  
		  else if(DrawY>= 368 && DrawY<= 384 && DrawX>=96 && DrawX<=160)
		  begin
		      Red = brick_RGB[23:16];
            Green = brick_RGB[15:8];
            Blue = brick_RGB[7:0];
		  end
		  
		  else
		  begin
	         Red = 8'h5c;
            Green = 8'h94;
            Blue = 8'hfc;
		  end
	end
	
	else
	begin
	         Red = 8'h00;
            Green = 8'h00;
            Blue = 8'h00;
	end
		  
		  
		  
    end 
    
endmodule
