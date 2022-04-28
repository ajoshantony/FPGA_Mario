module  world_ROM_mod
(

		input [10:0]  read_address,
		input  Clk,

		output logic [4:0] data_Out
);

endmodule

module collisions (
	input [9:0] X_Pos, Y_Pos, DrawX, DrawY, //input positions
	//input [3:0] cell_REG [10:0], //This is the array of cells. Should be like 1200 4 bit cells
	input [5:0] Right_V, Left_V, Up_V, Down_V, //input velocities
	input frame_clk, pixel_clk, clk_50,
	output [9:0] X_Out, Y_Out //output positions
	


);

world_ROM_mod world_ROM (.read_address(cell_ADDR), .Clk(clk_50), .data_Out(sprite_ADDR));

//The location of the nearest colliding pixel in each direction
logic [9:0] collision_down, collision_up, collision_right, collision_left;

//Net velocities for each direction because we don't handle negatives
logic [5:0] Net_Right_V, Net_Left_V, Net_Up_V, Net_Down_V;

//The offsets from the top left pixel
logic [5:0] Right_Offset, Left_Offset, Up_Offset, Down_Offset;

logic [10:0] ac;

logic [10:0] cell_ADDR;
logic [4:0] sprite_ADDR;

assign Right_Offset = 15;
assign Left_Offset = 0;
assign Up_Offset = 0;
assign Down_Offset = 15;

always_ff @ (posedge frame_clk or posedge pixel_clk)
begin
if(frame_clk) //initial conditions/update outputs. TA says this is kinda sus, if
					//it doesn't work then switch to just the pixel_clk and use DrawX
					//and DrawY in the if statement (since frame_clk is dependent on them)
begin


/*--------------------------------------
Set Net velocities because no 2's comp
----------------------------------------*/
if(Right_V > Left_V) 
begin
Net_Right_V <= Right_V - Left_V;
Net_Left_V <= 0;
end

else
begin
Net_Left_V <= Left_V - Right_V;
Net_Right_V <= 0;
end

if(Up_V > Down_V)
begin
Net_Up_V <= Up_V - Down_V;
Net_Down_V <= 0;
end

else
begin
Net_Down_V <= Down_V - Up_V;
Net_Up_V <= 0;
end


/*--------------------------------------
Update positions based off collisions
----------------------------------------*/
if(Net_Right_V > 0)
begin
if(X_Pos + Net_Right_V + Right_Offset > collision_right)
X_Out <= collision_right - 1 -Right_Offset; //maybe remove offset
else
X_Out <= X_Out + Net_Right_V;
end

else
begin
if(X_Pos - Net_Left_V + Left_Offset < collision_left)
X_Out <= collision_left + 1 + Left_Offset; //maybe remove offset
else
X_Out <= X_Out - Net_Left_V;
end

if(Net_Up_V > 0)
begin
if(Y_Pos - Net_Up_V + Up_Offset < collision_up) //possible bug here is getting stuck on ceilings in a jump until timer runs out. Solve by adding a zero output for up Veclocity if this is the case.
Y_Out <= collision_up + 1 + Up_Offset; //maybe remove offset
else
Y_Out <= Y_Out - Net_Up_V;
end

else
begin
if(Y_Pos + Net_Down_V + Down_Offset > collision_down)
Y_Out <= collision_down - 1 - Down_Offset; //maybe remove offset
else
Y_Out <= Y_Out + Net_Down_V;
end



/*--------------------------------------
Reset all the pixel_clk logic signals
----------------------------------------*/
Net_Right_V <= 0;
Net_Left_V <= 0;
Net_Up_V <= 0;
Net_Down_V <= 0;
collision_right <= 639;
collision_left <= 0;
collision_up <= 0;
collision_down<= 479;

end



/*--------------------------------------
Determine closest collisions at each pixel
----------------------------------------*/
if(pixel_clk)
begin
cell_ADDR = DrawX[9:3] + DrawY[9:3]*40; //when we do scrolling this will have an logic x offset


if(sprite_ADDR % 2 == 0) //even index has collision
begin


if((DrawX >= X_Pos)&&(DrawX <= X_Pos + 15))
begin
if((DrawX > X_Pos)&&(DrawX < collision_right))
collision_right <= DrawX;
else if((DrawX < X_Pos)&&(DrawX > collision_left))
collision_left <= DrawX;
end

if((DrawY >= Y_Pos)&&(DrawY <= Y_Pos + 15))
begin
if((DrawY > Y_Pos)&&(DrawY < collision_down))
collision_down <= DrawY;
else if((DrawY < Y_Pos)&&(DrawY > collision_up))
collision_up <= DrawY;
end

end

end



//have an always_ff @ (posedge frame_clk or posedge VGA_Clk)
//go through all the pixels at the pixel_clk, and then at the very
//end (using an if statement for the VGA_Clk) evaluate collisions based
//off of the logic signals generated in pixel_clk. Set the X and Y Out.
//then reset all logic signals for the next frame.

end



endmodule
