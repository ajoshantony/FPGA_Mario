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
module counter (input  logic Clk, Add_En,
              output logic [5:0]  count);

    always_ff @ (posedge Clk)
    begin
	 	 
		
			count <= count + 1;

    end
	

endmodule

module  color_mapper ( input        [9:0] BallX, BallY, DrawX, DrawY, Ball_size, score,
								input [7:0] keycode,
							  input Clk_50,blank,pixel_clk, frame_clk,
                       output logic [7:0]  Red, Green, Blue );
    
    logic ball_on;
	 logic [5:0] questioncount;
	 
	 
	 
	 
	 
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

counter questioncounter (.Clk(frame_clk), .count(questioncount));


//RGB to ignore : ee35ff
logic [9:0] sprite_x,sprite_y;
logic [7:0] m_stand_addr;
logic [23:0] m_stand_RGB;
logic [12:0] back_ADDR;
logic [4:0] sprite_Index;
logic [23:0] back_RGB;
logic [12:0] sprite_ADDR;
logic [12:0] scroll_shift; //make register

world_rom world_ROM_Color_Mapper (.read_address(back_ADDR), .Clk(Clk_50), .data_Out(sprite_Index));
	 
palette_16_rom palette_16_rom_mod (.read_address(sprite_ADDR), .Clk(Clk_50), .data_Out(back_RGB));

always_comb
begin:sprite_addr_calc
sprite_x = DrawX - BallX;
sprite_y = DrawY - BallY;

//if(BallX > 240)

//scroll_shift = BallX + scroll_shift;
//back_ADDR = (DrawX[9:4]+BallX/10)%40+ DrawY[9:4]*40;
back_ADDR = (DrawX[9:4] + BallX/10)%40+ DrawY[9:4]*40;


	if((questioncount >= 0)&&(questioncount < 21)&&(sprite_Index == 6))
	begin
	sprite_ADDR = (256*6 + DrawX[3:0]+DrawY[3:0]*16);
	end
	else if((questioncount >=21)&&(questioncount < 42)&&(sprite_Index == 6))
	begin
	sprite_ADDR = (256*8 + DrawX[3:0]+DrawY[3:0]*16);
	end
	else if((questioncount >=42)&&(sprite_Index == 6))
	begin 
	sprite_ADDR = (256*10 + DrawX[3:0]+DrawY[3:0]*16);
	end
else
begin 
sprite_ADDR = (256*sprite_Index + DrawX[3:0]+DrawY[3:0]*16);
end


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


//640 by 480 

end





    always_ff @ (posedge pixel_clk)
    begin:RGB_Display
	if(blank == 1)
	begin
        if ((ball_on == 1'b1) && (m_stand_RGB != 24'hee35ff) ) 
        begin 
            Red <= m_stand_RGB[23:16];
            Green <= m_stand_RGB[15:8];
            Blue <= m_stand_RGB[7:0];
        end
		  else
		  begin
				Red <= back_RGB[23:16];
            Green <= back_RGB[15:8];
            Blue <= back_RGB[7:0];
		  end
        
	end
	
	else
	begin
	         Red <= 8'h00;
            Green <= 8'h00;
            Blue <= 8'h00;
	end
		  
		  
		  
    end 
    
	
endmodule
