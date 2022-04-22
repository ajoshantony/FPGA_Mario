//-------------------------------------------------------------------------
//    Ball.sv                                                            --
//    Viral Mehta                                                        --
//    Spring 2005                                                        --
//                                                                       --
//    Modified by Stephen Kempf 03-01-2006                               --
//                              03-12-2007                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Fall 2014 Distribution                                             --
//                                                                       --
//    For use with ECE 298 Lab 7                                         --
//    UIUC ECE Department                                                --
//-------------------------------------------------------------------------
module counter (input  logic Clk, Reset, Add_En,
              output logic [3:0]  count);

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice, this is a sycnrhonous reset, which is recommended on the FPGA
			  count <= 4'h0;
		 else if (Add_En)
		 begin
			count <= count + 1;
		 end
    end
	

endmodule

module  ball ( input Reset, frame_clk,
					input [7:0] keycode,
               output [9:0]  BallX, BallY, BallS );
    
    logic [9:0] Ball_X_Pos, Ball_Right_Motion, Ball_Left_Motion, Ball_Y_Pos, Ball_Up_Motion, Ball_Down_Motion, Ball_Size;
	 logic downFlag, upFlag, leftFlag, rightFlag, addTrue, jumpReset;
	 logic [5:0] jumpCount;
	 logic [1:0] speed;
	 
    parameter [9:0] Ball_X_Center=0;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center=220;  // Center position on the Y axis
    parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Ball_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Ball_X_Step=1;      // Step size on the X axis
    parameter [9:0] Ball_Y_Step=1;      // Step size on the Y axis

    assign Ball_Size = 16;  // assigns the value 4 as a 10-digit binary number, ie "0000000100"
   
	
    always_ff @ (posedge Reset or posedge frame_clk )
    begin: Move_Ball
        if (Reset)  // Asynchronous Reset
        begin 
            Ball_Up_Motion <= 10'd0; //Ball_Y_Step;
				Ball_Down_Motion <= 10'd0; //Ball_Y_Step;
				Ball_Right_Motion <= 10'd0; //Ball_X_Step;
				Ball_Left_Motion <= 10'd0; //Ball_X_Step;
				Ball_Y_Pos <= Ball_Y_Center;
				Ball_X_Pos <= Ball_X_Center;
				jumpCount <= 0;
				speed <= 2;
	 
        end
           
        else 
        begin 
		  //This logic for the ball here can be reworked to take the coordinates of the
		  //sprites of other world objects, like pipes and brick platforms.
		  //To differentiate between pixels that can be collided with and pixels
		  //that can be passed through, I have two different ideas.
		  //One idea is to have an extra bit of logic in our VRAM that indicates
		  //whether the pixel is one that can be passed through or should be collided
		  //with.
		  //The other idea is to instead of keeping track of pixels, keep track of
		  //the position of the sprites and use this info (alongside the height/width
		  //of the sprite) to calculate collisions. 
		  //I'm thinking that the second idea is more practical, but it does require
		  //more logic. The downside is that the amount of logic needed only increases
		  //the more we add sprites, while the pixel logic would be universal across
		  //all sprites.
		  //If we do go with using the coordinates of sprites, I believe that the logic
		  //can be simplified if we introduce a sprite RAM. This way the logic for
		  //each sprite is the same, just with the index of the ram changing for each
		  //sprite. This would just simplify our logic. Each sprite RAM could contain
		  //data that store's the sprite's location, width, height, and of course its
		  //address in our ROM. This information is everything needed to draw the
		  //sprite and perform our collision logic.
		  //For now I'll offset the max by 16 pixels. This will be a good test to see if
		  //that is enough to prevent Mario from going off screen at all. If it works, then
		  //we know this is the offset we need for all collisions right/left/up/down since
		  //Mario's sprite is a 16x16 square. I will not offset it for the top and left of
		  //the screen since the position describes Mario's top-left pixel.
		  //One other consideration. If we were to zero out the velocity instead of 2's
		  //complement it, that would mean that we're zeroing it out in both directions.
		  //We may want to create a separate right/left and up/down velocity to prevent
		  //zeroing one direction from also zeroing the opposite direction. We can test
		  //whether this is an issue though by just zeroing it at first. Pressing the
		  //opposite key may work to not have it get stuck, and if that doesn't work, then
		  //maybe pushing Mario away one pixel to the opposite direction would also work.
		  //I'll include commented out code that I think works. The only note is that
		  //all variables labeled as Ball will instead be Mario after making all the rest
		  //of the changes to the code.
		  
		  
		  //read comments on each line, changed all the conditional logic
		  upFlag <= 0;
		  downFlag <= 0;
		  leftFlag <= 0;
		  rightFlag <= 0;
		  
		  if ( (Ball_Y_Pos ) >= Ball_Y_Max - 5'b10001 )  // Mario is at bottom of screen, on the floor
					  begin
					  Ball_Down_Motion <= 0;  // Zero out the motion (maybe need to push back Mario as well if he clips through)
					  downFlag <= 1;
					  end
					  
				 if ( (Ball_Y_Pos) <= Ball_Y_Min+1 )  // Mario has hit the top of the screen. Stop motion.
					  begin
					  Ball_Up_Motion <= 0;
					  upFlag <= 1;
					  end
					  
				 if ( (Ball_X_Pos) >= Ball_X_Max - 5'b10001)  //Mario is on right side of screen, stop motion
					  begin
					  Ball_Right_Motion <= 0;  
					  rightFlag <= 1;
					  end  
				 if ( (Ball_X_Pos) <= Ball_X_Min+1)  // Mario is on left side of screen. Stop
					  begin
					  Ball_Left_Motion <= 0;
					  leftFlag <= 1;
					  end
					  
		  if(jumpCount == 0)
		  begin
		  
		  
					  
				  
				 begin
				 
					  Ball_Up_Motion <= 0;
					  Ball_Down_Motion <= speed;
					  Ball_Right_Motion <= 0; // No key is pressed, fall down.
					  Ball_Left_Motion <= 0;
					if(downFlag)
					Ball_Down_Motion <= 0;
				 
					if((keycode == 8'h04)&&!leftFlag)
							begin

								Ball_Left_Motion <= speed;//A
								Ball_Right_Motion <= 0;
								Ball_Up_Motion <= 0;
								if(downFlag)
								Ball_Down_Motion <= 0;
								else
								Ball_Down_Motion <= speed;
							  end
					        
					if((keycode == 8'h07)&&!rightFlag)
							begin
								
							  Ball_Left_Motion <= 0;
								Ball_Right_Motion <= speed;//D
								Ball_Up_Motion <= 0;
								if(downFlag)
								Ball_Down_Motion <= 0;
								else
								Ball_Down_Motion <= speed;
							  end

							  
					if((keycode == 8'h16)&&!downFlag)
							begin

							  Ball_Left_Motion <= 0;
								Ball_Right_Motion <= 0;
								Ball_Up_Motion <= 0;
								Ball_Down_Motion <= speed;//S
							 end
							  
					if((keycode == 8'h1A)&&!upFlag&&downFlag)
							begin
								jumpCount <= 6'b111111;
							 end	  

				end
				end
				else
				begin
				Ball_Up_Motion <= speed;
				Ball_Down_Motion <= 0;
				jumpCount <= jumpCount - 1;
				if((keycode == 8'h04)&&!leftFlag)
							begin

								Ball_Left_Motion <= speed;//A
								Ball_Right_Motion <= 0;
								Ball_Up_Motion <= speed;
								Ball_Down_Motion <= 0;
							  end
					        
				else if((keycode == 8'h07)&&!rightFlag)
							begin
								
							  Ball_Left_Motion <= 0;
								Ball_Right_Motion <= speed;//D
								Ball_Up_Motion <= speed;
								Ball_Down_Motion <= 0;
							  end
				else
				begin
				Ball_Right_Motion <= 0;
				Ball_Left_Motion <= 0;
				end
				if ( (Ball_Y_Pos - Ball_Size) <= Ball_Y_Min +5'b10001 )  // Mario has hit the top of the screen. Stop motion.
					  begin
					  Ball_Up_Motion <= 0;
					  upFlag <= 1;
					  end
				end
				 
				 Ball_Y_Pos <= (Ball_Y_Pos + Ball_Down_Motion - Ball_Up_Motion);  // Update ball position
				 Ball_X_Pos <= (Ball_X_Pos + Ball_Right_Motion - Ball_Left_Motion);
		  
		  
		  
		  /*
				 if ( (Ball_Y_Pos + Ball_Size) >= Ball_Y_Max)  // Ball is at the bottom edge, BOUNCE!
					  Ball_Y_Motion <= (~ (Ball_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (Ball_Y_Pos - Ball_Size) <= Ball_Y_Min)  // Ball is at the top edge, BOUNCE!
					  Ball_Y_Motion <= Ball_Y_Step;
					  
				 else if ( (Ball_X_Pos + Ball_Size) >= Ball_X_Max )  // Ball is at the Right edge, BOUNCE!
					  Ball_X_Motion <= (~ (Ball_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (Ball_X_Pos - Ball_Size) <= Ball_X_Min )  // Ball is at the Left edge, BOUNCE!
					  Ball_X_Motion <= Ball_X_Step;
					  
				 else 
				 begin
					  Ball_Y_Motion <= Ball_Y_Motion;  // Ball is somewhere in the middle, don't bounce, just keep moving
				 
				 
				 case (keycode)
					8'h04 : begin

								Ball_X_Motion <= -1;//A
								Ball_Y_Motion<= 0;
								
							  end
					        
					8'h07 : begin
								
					        Ball_X_Motion <= 1;//D
							  Ball_Y_Motion <= 0;
							  end

							  
					8'h16 : begin

					        Ball_Y_Motion <= 1;//S
							  Ball_X_Motion <= 0;
							 end
							  
					8'h1A : begin
								
					        Ball_Y_Motion <= -1;//W
							  Ball_X_Motion <= 0;
							 end	  
					default: ;
			   endcase
				end
				 
				 Ball_Y_Pos <= (Ball_Y_Pos + Ball_Y_Motion);  // Update ball position
				 Ball_X_Pos <= (Ball_X_Pos + Ball_X_Motion);
			
			*/
			
	  /**************************************************************************************
	    ATTENTION! Please answer the following quesiton in your lab report! Points will be allocated for the answers!
		 Hidden Question #2/2:
          Note that Ball_Y_Motion in the above statement may have been changed at the same clock edge
          that is causing the assignment of Ball_Y_pos.  Will the new value of Ball_Y_Motion be used,
          or the old?  How will this impact behavior of the ball during a bounce, and how might that 
          interact with a response to a keypress?  Can you fix it?  Give an answer in your Post-Lab.
      **************************************************************************************/
      
			
		end  
    end
       
    assign BallX = Ball_X_Pos;
   
    assign BallY = Ball_Y_Pos;
   
    assign BallS = Ball_Size;
    

endmodule
