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

	



module  ball ( input Reset, frame_clk, pixel_clk, clk_50,
					input [7:0] keycode,
					input [9:0] DrawX, DrawY, score,
               output [9:0]  BallX, BallY, BallS,
					output lFlag, rFlag, uFlag, dFlag,
					output sig1, sig2, sig3, sig4,
					output [20:0] logicalX
					);
    
    logic [9:0] Ball_X_Pos, Ball_Right_Motion, Ball_Left_Motion, Ball_Y_Pos, Ball_Up_Motion, Ball_Down_Motion, Ball_Size;
	 logic [9:0] New_X_Pos, New_Y_Pos;
	 logic downFlag, upFlag, leftFlag, rightFlag, addTrue, jumpReset, beginFlag, backFlag, horizFlag;
	 logic [5:0] jumpCount;
	 logic [2:0] speed, terminal;
	 logic [5:0] fallDownSpeed, fallUpSpeed, NetRight, NetLeft, NetUp, NetDown;
	 logic [5:0] finUp, finDown, finRight, finLeft;
	 logic [9:0] collision_down, collision_up, collision_right, collision_left;
	 logic [5:0] Right_Offset, Left_Offset, Up_Offset, Down_Offset;
	 logic [9:0] X_Out, Y_Out;
	 
	 
    parameter [9:0] Ball_X_Center=50;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center=300;  // Center position on the Y axis
    parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Ball_Y_Max=416;  //was 479 hardcoded floor   // Bottommost point on the Y axis
    parameter [9:0] Ball_X_Step=1;      // Step size on the X axis
    parameter [9:0] Ball_Y_Step=1;      // Step size on the Y axis

    assign Ball_Size = 16;  // assigns the value 4 as a 10-digit binary number, ie "0000000100"
   
	collisions mario_collisions (.X_Pos(Ball_X_Pos), .Y_Pos(Ball_Y_Pos), 
	.DrawX(DrawX), .DrawY(DrawY), .Right_V(NetRight), .Left_V(NetLeft), .Up_V(NetUp), 
	.Down_V(NetDown), .frame_clk(frame_clk), .pixel_clk(pixel_clk), 
	.clk_50(clk_50), .X_Out(New_X_Pos),.Y_Out(New_Y_Pos), .upFlag(upFlag), 
	.downFlag(downFlag), .rightFlag(rightFlag), .leftFlag(leftFlag),
	.collision_down(collision_down), .collision_up(collision_up), 
	.collision_left(collision_left), .collision_right(collision_right),
	.logicalX(logicalX));
	
	
	
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
				terminal <= 3;
				sig1 <= 0;
				sig2 <= 0;
				sig3 <= 0;
				sig4 <= 0;
				beginFlag <= 0;
				logicalX <= 0;
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
		  
		  /*
		  upFlag <= 0;
		  downFlag <= 0;
		  leftFlag <= 0;
		  rightFlag <= 0;
		  
		  if ( ((Ball_Y_Pos ) >= Ball_Y_Max - 20)||((Ball_Y_Pos>= 368-20) &&(Ball_Y_Pos<=368)&& (Ball_X_Pos>=96-10) && (Ball_X_Pos<=160)) )  // Mario is at bottom of screen, on the floor
					  begin
					  Ball_Down_Motion <= 0;// Zero out the motion (maybe need to push back Mario as well if he clips through)
					  downFlag <= 1;
					  end
					  
				 if ( ((Ball_Y_Pos) <= Ball_Y_Min+1 )||((Ball_Y_Pos<= 384+8) && (Ball_Y_Pos >= 384)&&(Ball_X_Pos>=96-10) && (Ball_X_Pos<=160)))  // Mario has hit the top of the screen. Stop motion.
					  begin
					  Ball_Up_Motion <= 0;
					  upFlag <= 1;
					  end
					  
				 if ( (Ball_X_Pos) >= Ball_X_Max - 17)  //Mario is on right side of screen, stop motion
					  begin
					  Ball_Right_Motion <= 0;  
					  rightFlag <= 1;
					  end  
					  
				 if ( (Ball_X_Pos) <= Ball_X_Min + 4)  // Mario is on left side of screen. Stop
					  begin
					  Ball_Left_Motion <= 0;
					  leftFlag <= 1;
					  end
			*/		  
		  if(jumpCount == 0)
		  begin
		  
		  
					  
				  
				 begin
					  Ball_Up_Motion <= 0;
					  Ball_Down_Motion <= terminal;
					  Ball_Right_Motion <= 0; // No key is pressed, fall down.
					 Ball_Left_Motion <= 0;
					//if(downFlag)
					//Ball_Down_Motion <= 0;
				 
					if((keycode == 8'h04)/*&&!leftFlag*/)
							begin

								Ball_Left_Motion <= speed;//A
								//Ball_Right_Motion <= 0;
								//Ball_Up_Motion <= 0;
								//if(downFlag)
								//Ball_Down_Motion <= 0;
								//else
								//Ball_Down_Motion <= speed;
							  end
					        
					if((keycode == 8'h07)/*&&!rightFlag*/)
							begin
								
							  //Ball_Left_Motion <= 0;
								Ball_Right_Motion <= speed;//D
								beginFlag<=1;
								//Ball_Up_Motion <= 0;
								//if(downFlag)
								//Ball_Down_Motion <= 0;
								//else
								//Ball_Down_Motion <= speed;
							  end

							  
					if((keycode == 8'h16)/*&&!downFlag*/)
							begin

							  //Ball_Left_Motion <= 0;
								//Ball_Right_Motion <= 0;
								//Ball_Up_Motion <= 0;
								Ball_Down_Motion <= terminal;//S
							 end
							  
					if((keycode == 8'h1A)/*&&!upFlag&&downFlag*/)
							begin
								jumpCount <= 6'b111111;
							 end	  

				end
				end
				else
				begin
				if(jumpCount == 6'b111111)
				begin
				fallUpSpeed <= 9;
				fallDownSpeed <= 4;
				end
				if(jumpCount % 6 == 0)
				begin
				if(fallUpSpeed != 0)
				fallUpSpeed <= fallUpSpeed - 1;
				end
				Ball_Up_Motion <= fallUpSpeed;
				Ball_Down_Motion <= fallDownSpeed;
				jumpCount <= jumpCount - 1;
				if((keycode == 8'h04)/*&&!leftFlag*/)
							begin

								Ball_Left_Motion <= speed;//A
								Ball_Right_Motion <= 0;
								Ball_Up_Motion <= fallUpSpeed;
								Ball_Down_Motion <= fallDownSpeed;
							  end
					        
				else if((keycode == 8'h07)/*&&!rightFlag*/)
							begin
								beginFlag<=1;
							  Ball_Left_Motion <= 0;
								Ball_Right_Motion <= speed;//D
								Ball_Up_Motion <= fallUpSpeed;
								Ball_Down_Motion <= fallDownSpeed;
							  end

				
				else
				begin
				Ball_Right_Motion <= 0;
				Ball_Left_Motion <= 0;
				end
				/*
				if ( ((Ball_Y_Pos ) >= Ball_Y_Max - 20)||((Ball_Y_Pos>= 368-20) &&(Ball_Y_Pos<=368)&& (Ball_X_Pos>=96-10) && (Ball_X_Pos<=160)) )  // Mario is at bottom of screen, on the floor
					  begin
					  Ball_Down_Motion <= 0;// Zero out the motion (maybe need to push back Mario as well if he clips through)
					  downFlag <= 1;
					  end
					  
				 if ( ((Ball_Y_Pos) <= Ball_Y_Min+1 )||((Ball_Y_Pos<= 384+8) && (Ball_Y_Pos >= 384)&&(Ball_X_Pos>=96-10) && (Ball_X_Pos<=160)))  // Mario has hit the top of the screen. Stop motion.
					  begin
					  Ball_Up_Motion <= 0;
					  upFlag <= 1;
					  end
					  
				 if ( (Ball_X_Pos) >= Ball_X_Max - 17)  //Mario is on right side of screen, stop motion
					  begin
					  Ball_Right_Motion <= 0;  
					  rightFlag <= 1;
					  end  
					  
				 if ( (Ball_X_Pos) <= Ball_X_Min + 4)  // Mario is on left side of screen. Stop
					  begin
					  Ball_Left_Motion <= 0;
					  leftFlag <= 1;
					  end
				
				if(downFlag)
				begin
				Ball_Down_Motion <= 0;
				//jumpCount <= 0;
				end
				if(upFlag)
				begin
				Ball_Up_Motion <= 0;
				fallUpSpeed <= 0;
				jumpCount <= 0;
				end
				*/
				end
				 
				 
				 //Ball_Y_Pos <= (Ball_Y_Pos + Ball_Down_Motion - Ball_Up_Motion);  // Update ball position
				 //Ball_X_Pos <= (Ball_X_Pos + Ball_Right_Motion - Ball_Left_Motion);
				 
				 NetRight <= Ball_Right_Motion;
				 NetLeft <= Ball_Left_Motion;
				 NetUp <= Ball_Up_Motion; //+ fallUpSpeed;
				 NetDown <= Ball_Down_Motion; //+ fallDownSpeed;
			 
		if(Ball_Right_Motion > Ball_Left_Motion) 
		begin
		NetRight <= Ball_Right_Motion - Ball_Left_Motion;
		NetLeft <= 0;
		end

	else
		begin
		NetLeft <= Ball_Left_Motion - Ball_Right_Motion;
		NetRight <= 0;
		end

	if(Ball_Up_Motion > Ball_Down_Motion)
		begin
		NetUp <= Ball_Up_Motion - Ball_Down_Motion;
		NetDown <= 0;
		end
	
	else
		begin
		NetDown <= Ball_Down_Motion - Ball_Up_Motion;
		NetUp <= 0;
		end
				 
				 //Ball_X_Pos <= New_X_Pos;
				 //Ball_Y_Pos <= New_Y_Pos;
				 
				lFlag <= leftFlag;
				rFlag <= rightFlag;
				uFlag <= upFlag;
				dFlag <= downFlag;
				
		
		if(rightFlag)
		NetRight <= 0;
		if(leftFlag)
		NetLeft <= 0;
		if(downFlag)
		NetDown <= 0;
		if(upFlag)
		NetUp <= 0;
		
		
		backFlag <= 1;
		
		
		/*
		if(Ball_X_Pos >= 320)
		begin
		backFlag <= 0;
		Ball_X_Pos <= 320;
		if(NetRight > NetLeft)
		begin
		finRight <= NetRight - NetLeft;
		if(!(Ball_X_Pos + finRight + 30 > collision_right))
		begin
				logicalX <= logicalX + 1;
				sig1 <= 1;
				end
		end
		else if(NetLeft > NetRight)
		backFlag <= 1;
		if(NetUp > NetDown)
		begin
		finUp <= NetUp - NetDown;
		finDown <= 0;
		if(!upFlag)
		begin
				Ball_Y_Pos <= Ball_Y_Pos - finUp;
				sig3 <= 1;
				end
		end
	
	if(NetDown > NetUp)
		begin
		finDown <= NetDown - NetUp;
		finUp <= 0;
		if(!downFlag)
		begin
				Ball_Y_Pos <= Ball_Y_Pos + finDown;
				sig4 <= 1;
				end
		end
		end
		
		
		
		
		
		if(backFlag || Ball_X_Pos < 320)
		begin
		if(NetRight > NetLeft) 
		begin
		finRight <= NetRight - NetLeft;
		finLeft <= 0;
		if(!rightFlag)
		begin
				Ball_X_Pos <= Ball_X_Pos + finRight;
				sig1 <= 1;
				end
		end

	if(NetLeft > NetRight)
		begin
		finLeft <= NetLeft - NetRight;
		finRight <= 0;
		if(!leftFlag)
		begin
				Ball_X_Pos <= Ball_X_Pos - finLeft;
				sig2 <= 1;
				end
		end

	if(NetUp > NetDown)
		begin
		finUp <= NetUp - NetDown;
		finDown <= 0;
		if(!upFlag)
		begin
				Ball_Y_Pos <= Ball_Y_Pos - finUp;
				sig3 <= 1;
				end
		end
	
	if(NetDown > NetUp)
		begin
		finDown <= NetDown - NetUp;
		finUp <= 0;
		if(!downFlag)
		begin
				Ball_Y_Pos <= Ball_Y_Pos + finDown;
				sig4 <= 1;
				end
		end
	
	if(collision_up > Ball_Y_Pos)
	Ball_Y_Pos <= collision_up + 1;
	else if((collision_left > Ball_X_Pos)&&(!upFlag))
	Ball_X_Pos <= collision_left + 10;
	else if(collision_right < Ball_X_Pos + 15)
	Ball_X_Pos <= collision_right - 1 -15;
	if(collision_down < Ball_Y_Pos)
	Ball_Y_Pos <= collision_down -1 +15;
	end	
	*/
	
	//Older collision logic transplanted to ball
	
Right_Offset <= 15;
Left_Offset <= 0;
Up_Offset <= 0;
Down_Offset <= 15;
if(beginFlag)
begin

if(Ball_X_Pos >= 320)
begin
backFlag <= 0;
Ball_X_Pos <= 320;
		if(NetRight > NetLeft)
		begin
		finRight <= NetRight - NetLeft;
		if(!(Ball_X_Pos + finRight + 30 > collision_right))
		begin
				logicalX <= logicalX + 1;
				sig1 <= 1;
				end
		end
else if(NetLeft > NetRight)
		backFlag <= 1;
		
		if(NetUp > 0)
		begin
		if(Ball_Y_Pos - NetUp + Up_Offset < collision_up) //possible bug here is getting stuck on ceilings in a jump until timer runs out. Solve by adding a zero output for up Veclocity if this is the case.
			Ball_Y_Pos <= collision_up + 1 + Up_Offset; //maybe remove offset
		else
			Ball_Y_Pos <= Ball_Y_Pos - NetUp;
		end

	else
		begin
		if(Ball_Y_Pos + NetDown + Down_Offset > collision_down)
			Ball_Y_Pos <= collision_down - 1 - Down_Offset; //maybe remove offset
		else
			Ball_Y_Pos <= Ball_Y_Pos + NetDown;
		end	
		

end


if(backFlag || Ball_X_Pos < 320)
begin
horizFlag <= 0;
if(NetRight > 0)
		begin
		if(Ball_X_Pos + NetRight + Right_Offset > collision_right)
		begin
			X_Out = collision_right - 1 -Right_Offset; //maybe remove offset
			horizFlag <= 1;
			end
		else
			X_Out = Ball_X_Pos + NetRight;
		end

	else
		begin
		if(Ball_X_Pos - NetLeft + Left_Offset < collision_left)
		begin
			X_Out = collision_left + 1 + Left_Offset; //maybe remove offset
			horizFlag <= 1;
			end
		else
			X_Out = Ball_X_Pos - NetLeft;
		end
if((NetUp > 0))
		begin
		if((Ball_Y_Pos - NetUp + Up_Offset < collision_up)&&(!horizFlag)) //possible bug here is getting stuck on ceilings in a jump until timer runs out. Solve by adding a zero output for up Veclocity if this is the case.
			Y_Out = collision_up + 1 + Up_Offset; //maybe remove offset
		else
			Y_Out = Ball_Y_Pos - NetUp;
		end

	else
		begin
		if((Ball_Y_Pos + NetDown + Down_Offset > collision_down))
			Y_Out = collision_down - 1 - Down_Offset; //maybe remove offset
		else
			Y_Out = Ball_Y_Pos + NetDown;
		end	
				
	
	
	
	if(beginFlag)
	begin
		Ball_X_Pos <= X_Out;
		Ball_Y_Pos <= Y_Out;
		end
		else
		begin
		Ball_X_Pos <= Ball_X_Pos;
		Ball_Y_Pos <= Ball_Y_Pos;
		end
	
		
		/*
				if(Ball_Y_Pos > 480)
				begin
				Ball_Y_Pos <= 464;
				Ball_X_Pos <= 50;
				end
		  */
			
		end 
	end	
		end
    end
       
    assign BallX = Ball_X_Pos;
   
    assign BallY = Ball_Y_Pos;
   
    assign BallS = Ball_Size;
    
	 

endmodule
