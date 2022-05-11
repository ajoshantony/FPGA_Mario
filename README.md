# Final Project: Super Mario NES
## ECE 385 
## Spring 2022

## BY: Ajosh Antony and Michael Garrity


### 1. Introduction 
Our Final Project was the program a game inspired by Super Mario Bros. for the NES onto our FPGA. We accomplished this through primarily SystemVerilog, with the only C code used being the code from Lab 6 used to read keyboard inputs using the NIOS-II processor. Our game functions as a platformer complete with two dimensional physics, collisions, a scrolling world, and game logic. The winning condition of the game is to reach the flag at the end, and the losing condition is either death from falling off the world screen or running out of time on the ten minute timer. The scoring for our game is dependent on the time remaining after completion of the level, meaning the objective of the game is to finish the level in as little time as possible.
	
### 2. Description of Our Final Design
#### 2.1 World Generation

Figure 1: 16x16 palette index table each type is 256 RGB values
16x16 palette
Our world was built by using a palette of all our background assets where each of the assets were 16x16 pixels which we stored in the palette_16_rom using inferred memory. Instead of using an additional palette for the colors we decided to store the full 24 bit RGB values of each pixel. This meant in order to store 1 16x16 block it used 24*256 = 6,144 bits and each address corresponds to a 24 bit RGB value. We used the Rishi helper tool to convert the assets (which were taken from mario sprite sheet) into hex values of the pixels going from left to right then the next line of the image. This gave us a .txt file of individual RGB values which were combined with the other image .txt file in the order shown in figure 1. We then used inferred ram to create the palette_rom module and we used the readmemh function to initialize the rom from the .txt file. We designed the 16x16 palette to work seamlessly with our future collision logic by putting the assets that should collide with mario to be in even indices. This is why there are some blank16 spaces which are 256 pixels of white so that we could maintain this order and also it helped with debugging.   

##### World ROM
After creating the palette of 16x16 blocks we are then able to create our world ROM. Since our screen had the dimension 480x640 the dimensions in terms of 16x16 blocks would be 30x40 which meant we could have a total 1,200 blocks on the screen. We created the world by making multiple frames with the 30x40 dimension where each space corresponds to an index in our 16x16 palette.

Figure 2: Example .csv frame before processing
 We used Excel to create a frame and figure 2 shows an example of one of those frames. We converted the excel workbook into a .csv then used a python script we created (figure 3) which output a .txt with all the indices in hex and separated in one column. 
```python
import csv
#upload new txt file and put "/filename.txt"
ft = open("/titlescreen.txt", "a") 
#upload .csv and put "/name.csv"
f = open('/titlescreen.csv', 'r')
with f:
    reader = csv.reader(f)
    for row in reader:
        for i in row:
            ft.write(str(hex(int(i))[2:])+'\n')
f.close()
ft.close()

```

Figure 3: python script that converts .csv that has the 16x16 palette base 10 indices into to a formatted .txt file with hex values 

We made the world_rom similar to the palette_16_rom but we had to change the address and memory size to fit the 1200 line .txt file that initialized the ROM using the readmem function. After initializing we had to think about how to address each of the ROMs. We first addressed the world_rom through the following formula.
```verilog 
back_ADDR = (DrawXTemp[9:4]+logicalX/6)%40+ DrawY[9:4]*40 + (DrawXTemp[9:4]+logicalX/6)/40*1200;  
```

We had to %16 DrawX and DrawY for the dimensions for each of the blocks %40 for width of the 30x40 frame. The DrawXTemp was DrawX + 1 which was necessary to fix a shifted 
indexing glitch for all of the background assets. In order to properly scroll through different frames we needed to add ``` verilog (DrawXTemp[9:4]+logicalX/6)/40*1200;``` so that we could get the correct slice of the 1,200 entries from one of the frames in world_rom. The logicalx was a register that stored number of blocks shifted*6 so that we could remember the correct frames while scrolling.  After we addressed a certain entry in world_rom we then used that output (sprite_index) to address the palette_16_rom so that we could print the correct pixel to the monitor. The addressing into palette_16_rom was calculated using the following formula.
```verilog
sprite_ADDR = (256*sprite_Index + DrawX[3:0]+DrawY[3:0]*16);
```

We needed to multiply the sprite_Index by 256 since that is how many colors there are for one block. Then to maintain the row major order we need to choose which of the 256 RGB based on ```DrawX[3:0]+DrawY[3:0]*16``` where the *16 was for the width of a block. The output from the palette_16_rom was set to the Red,Green,Blue variables for the VGA as the last else condition in an always_ff block @ posedge pixel_clk (RGB_Display block). An example of one of the frames’ output is shown in figure 4. It is the same frame that is depicted in figure 2.

Figure 4: Example frame after processing
Displaying Score
Our gameTime was a register that stored the current gametime. This register was created in our ball.sv and the output was exported to the Color_Mappper.sv so that we could display the score. 
```verilog time1_Index = gameTime/100;      time2_Index = (gameTime%100)/10;      time3_Index = gameTime%10; 
``

We were able to get the individual numbers of the 3 digit gametime by /100 to get the hundreds place then %100 gets the bottom 2 numbers then /10 gets the 2nd number or the tens place in terms of the gameTime. In order to get the ones place number we just need to do %10. Each digit doubled as the index into the numbers_rom which stores a number sprite in order from 0-9.  An example of this indexing is shown below for the hundreds place digit which is similar to sprite_addr addressing except sprite_index is time1_index. 
``` verilog 
time1ADDR = 256*time1_Index + DrawX[3:0] + DrawY[3:0]*16;
```

Animated Mystery Blocks
In order to animate the mystery blocks we checked if the sprite_Index was indeed 6. We then used a 6 bit counter module to continuously count then overflow. We took advantage of this overflow by setting sprite_Index to 6 for the counter range `[`0,21), 8 for the counter `[`21,42), then 10 for counter `[`42,64`]` which made the animation cycle take around 1 second. We had a time1_on,time2_on, and time3_on values which were set when the DrawX and DrawY were in the region in the top right and within each of the respective digit regions. The Red, Green, and Blue values were set to the time (1,2, or 3) RGB value when the respective time on signal was on. 
Animated Mario

Figure : All the Mario sprites in the animation order
We had a counter_mario_ani module that was a 4 bit counter which we used to cycle through the indices (1-3) in the mario_ani_rom. The animation was done similarly to the mystery block except the range of the count was smaller since mario’s movement looked better when we cycled much faster. The default mario_ani_index was set to 0 which was his default standing sprite. We set the mario_ani_index to 1 for the counter range `[`0,5), 2 for the counter `[`5,11), then 3 for counter `[`11,16`]`. We had a lookDir signal (set by which keycode pressed) sent from ball.sv to signify mario’s current direction so that the sprite drawing would respect that. We also only stored one side of mario’s direction since we could simply read the sprite rgb values right to left instead of left to right saving us double the space. An example of this is shown below for Mario's standing sprite address.
```verilog 
mario_ani_ADDR =(15-sprite_x) + sprite_y*16;
```

We had a ball_on signal which used the BallX and BallY signals from ball.sv to calculate a 16x16 box centered at the top left corner. The ball_on signal was 1 when Mario was in the certain DrawX and DrawY box. The output of the mario_ani_rom was mario_ani_RGB. The Red,Green and Blue signals were set to the mario_ani_RGB when ball_on was 1 and was not our transparent color 0xEE35FF. 
(ball_on == 1'b1) && (mario_ani_RGB != 24'hee35ff) 


2.2 Character Control/Collision
Character Control
	Mario is controlled by user input through the W, A, and D keys on a keyboard. The inputs are read and delivered to the FPGA through the NIOS-II processor. The motion logic is controlled by a set of four different velocity values indicating motion in all different directions. Velocity in this context can be interpreted as a number of pixels that Mario moves in any given direction per frame. Velocity is applied to the character by simply changing their position by some amount between frames, as is shown in this snippet of rightward motion:
``` verilog 
X_Out = Ball_X_Pos + NetRight;
```

 The movement/controls can be separated into two distinct states: standing and jumping. In the standing state, the downward velocity is constant. It’s a simple downward velocity dragging the character down. The left and right velocities are dependent on key inputs. When A is held, the left velocity becomes equal to our speed variable (by default this is 2 pixels per frame). When D is held, then the right velocity becomes equal to our speed. The W key is used for jumping, and triggers a transition into the jumping state. In the jumping state, left and right movement is controlled the same as the standing state, but the vertical velocity is no longer constant. In the jumping state, the goal was to get a parabolic curve in our jump motion to represent realistic looking physics complete with a downward acceleration due to gravity. The desired jump motion should resemble the following:

Figure : Parabolic Jump Motion
To accomplish this, the jumping state implements a timer. This timer is initialized to 63, and counts down every frame. The velocities at the beginning of this state are also initialized to certain values. The upward velocity is initialized to 9 pixels/frame, and the downward velocity is initialized to 4 pixels/frame, generating a net upward velocity of 5 pixels/frame. The logic of the jumping state goes so that every 6 frames, the upward velocity is decreased by one. We accomplish this by using modulus, as shown in this code snippet:
``` verilog
if(jumpCount % 6 == 0)
   begin
   if(fallUpSpeed != 0)
   fallUpSpeed <= fallUpSpeed - 1;
   end
```

This means that after six frames, the net upward velocity will be only 4 pixels/frame. Eventually, the upward velocity and downward velocity will both be equal to 4 pixels/frame, representing the peak of the parabolic curve of Mario’s jump, after which he begins to fall as the net velocity turns downward when the upward velocity becomes 3 pixels/frame. After the upward velocity reaches zero, Mario achieves a terminal velocity of 4 pixels/frame. The jump state ends once Mario’s jump counter has reached zero, at which point his motion returns to the standing state. If Mario lands on a platform before his jump state is finished, we do not need to worry about exiting the state because his left and right motion still works just as before, and our collision logic prevents his net downward velocity from causing any problems. 
Collision logic
	Our collision detection is handled on a pixel-by-pixel basis using four different vectors in each direction of the player. Each of these vectors represents a register intended to store the X and Y position of the nearest collision from the player in every direction. They are initialized to the edges of the screens, as these are the farthest away possible points of collision at all times. Each pixel is determined to be a collision pixel based off of the index corresponding to its addressing in world_ROM. Each world background sprite that is intended to be collided with has intentionally been stored at an even index in our ROM. We can evaluate this by calculating the address of the sprite in our world_rom and then evaluating the least significant bit of the output sprite index, as shown in this code snippet (which uses somewhat different variable names):
``` verilog cell_ADDR <= (tempX[9:4] + logicalX/6)%40 + DrawY[9:4]*40 + (tempX[9:4] + logicalX/6)/40*1200;
if(sprite_ADDR[0] == 0)
//described logic for colliding pixel ensues
```

Using an always_ff block on the pixel clock, we can functionally iterate over every pixel once per frame. For each range of X/Y position values representing Mario’s width/height, we look at each pixel evaluating whether it is a pixel belonging to a collidable world sprite and also evaluating based off Mario’s current position whether it is closer to Mario than the pixel currently stored in that particular direction’s register. These four collision registers are output to our ball.sv module, which then uses them to handle movement during collisions. If the collision is farther from Mario than his current position plus velocity would land him, then the collision is ignored and he moves freely. If the point of collision would be reached or passed through this movement, then his position would snap to be right up against the colliding wall/floor/ceiling. Additionally, we set four different flags to be triggered in this case to be wired to the FPGA LEDs for debugging purposes. 
Here is a visualization of the collision detection logic:

Figure : Collision Logic Initial
The vectors are initialized to stretch toward each edge of the screen, as these are the farthest possible points for collision in each direction.
After looping through all the pixels on screen, we are left with the following:

Figure : Collision Logic Final
The vectors indicating valid movement have shrunk. Most notably, the vector below Mario has disappeared entirely since Mario is actively colliding with the ground. The ground, brick, and pipe tiles are all collidable, which defines the edges of Mario’s maneuverable space at this particular frame. It’s noteworthy that the bush tiles directly to the left, stored at indices 11 and 13 in our world_ROM, are both non-collidable, meaning that Mario can move through them and the collision detection ignores them. With these vectors accurately and precisely identifying the space in which Mario is able to move, our movement logic can now be run without problems.


















3. Block Diagram 

Figure : RTL diagram


Figure: Simplified Top-Level Diagram

4. Module Descriptions
Module: VGA_controller.sv
Inputs: ```verilog Clk,Reset```
Outputs: hs,vs,pixel_clk,blank,sync,[9:0] DrawX,[9:0] DrawY 
Description: This module outputs the DrawX and DrawY variables which are the x and y coordinates of the current pixel being drawn. It also outputs a pixel clock which is half of the input Clk. The hs output is used to determine when a new line is to be drawn and vs is used to determine a new frame. The blank (active low signal) tells whether or not to draw on the monitor. 

Module: lab62.sv
Inputs: MAX10_CLK1_50,[1:0] KEY,[9:0] SW,[9:0] LEDR
Inouts:[15:0] DRAM_DQ,[15:0] ARDUINO_IO,ARDUINO_RESET_N 
Outputs:[7:0] HEX0,[7:0] HEX1,[7:0] HEX2,[7:0] HEX3,[7:0] HEX4,		
[7:0] HEX5,DRAM_CLK, DRAM_CKE,[12:0] DRAM_ADDR, [1:0] DRAM_BA,            DRAM_LDQM,DRAM_UDQM,DRAM_CS_N,DRAM_WE_N,DRAM_CAS_N,DRAM_RAS_N, VGA_HS,VGA_VS,[3:0] VGA_R,[3:0] VGA_G,[3:0] VGA_B

Description: This is the top level of our final project which instantiates the vga_controller, ball, and color_mapper modules. It also assigns the external connections from the .qip file generated by the platform designer. We inherited this top-level design from Lab 6.2. There were some minor modifications made. The major change was made to the SOC. We removed the .leds_export so that we could reassign the LEDs for our own debugging purposes.

Module: HexDriver.sv
Inputs: [3:0] In0
Outputs: [6:0] Out0
Description: The HexDriver.sv file accepts four bits of binary and prints their hexadecimal output to the LEDs on the FPGA. For the purposes of our final project, it just prints the current keycode being pressed on the keyboard by the user.

Module: Color_Mapper.sv
Inputs: [9:0] BallX, [9:0] BallY, [9:0] DrawX,[9:0] DrawY,[9:0] Ball_size, [9:0] score, [20:0] logicalX,[9:0] gameTime, clk_50, blank, pixel_clk, frame_clk,endFlag, lookDir
Outputs: [7:0] Red,[7:0] Green,[7:0] Blue 
Description: The Color_Mapper module decides at each pixel what RGB value should be output to the VGA monitor. The logic for the Color Mapper is driven by an always_ff block on the pixel clock. Inside the module we use a series of on signals to determine what should be drawn at any given point on the screen for each frame. We have a ball_on to indicate when Mario should be drawn, a time_on to indicate when time should be drawn, and a score_on to indicate when the score should be drawn. If none of these three foreground elements have an on signal for any particular pixel, then the background is drawn. These three different foreground elements each have their own ROM module, the details of which are explained below. The background is generated using the world_rom and 16x16 palette ROMs, which are also explained below. The Color_Mapper also contains some counters that handle animations of sprites.

Module: ball.sv
Inputs:  Reset, frame_clk, pixel_clk, clk_50, [7:0] keycode, [9:0] DrawX, [9:0] DrawY
Outputs: [9:0] BallX, [9:0] BallY,[9:0] BallS, [9:0] score, lFlag, rFlag, uFlag, dFlag, endFlag, lookDir, sig1, sig2, sig3, sig4, questionFlag,[20:0] logicalX, [9:0] gameTime,[4:0] collisionIndexRight, [4:0] collisionIndexLeft, [4:0] collisionIndexUp, [4:0] collisionIndexDown
Description: This module controls the movement for Mario. It is driven by an always_ff block on the frame_clk, updating its various outputs with every frame of the VGA monitor. The module keeps track of Mario’s position data, as well as his logicalX offset while scrolling. It is where all of his movements are handled, with the collisions module explained below instantiated inside this module. This module also keeps track of the timer, which counts down once every 64 frames for approximately one second of time (since the VGA monitor operates at a refresh rate of 60Hz). There are also a variety of outputs, such as the directional flags (rFlag, lFlag, etc.) that were wired to LEDs for debugging purposes. We decided to go with a 21 bit logicalX register simply because it was an arbitrarily large number that would allow us to scroll as far as we wanted without worrying about overflow. The gameTime was made 10 bits so that we could accommodate a ten minute timer, which needed to store 600 seconds. The score was also made 10 bits as a consequence of this. 

Module: collisions.sv 
Inputs: [9:0] X_Pos, [9:0] Y_Pos, [9:0] DrawX, [9:0] DrawY, [5:0] Right_V, [5:0] Left_V, [5:0] Up_V, [9:0] Down_V, frame_clk, pixel_clk, clk_50, [20:0] logicalx
Outputs: [9:0] X_Out, [9:0] Y_Out, rightFlag, leftFlag, downFlag, upFlag, [9:0] collision_down, [9:0] collision_up, [9:0] collision_right, [9:0] collision_left, [4:0] collisionIndexRight, [4:0] collisionIndexLeft, [4:0] collisionIndexUp, [4:0] collisionIndexDown
Description: The collisions module functions as a spatial awareness lookahead module. It is driven by an always_ff clock on the pixel_clk. By iterating over every pixel once each frame, it evaluates and stores the nearest colliding pixel in each direction of Mario into one of the four collision registers. These registers are output to the ball.sv module, allowing it to evaluate what Mario’s new position should be on the next frame conscious of what he may collide with when moving. In order to determine which pixels are collidable pixels and which should be ignored in collision, the collision module instantiates a world_rom module. This is explained in detail below, but it basically uses DrawX and DrawY to calculate an address to input to the world_rom and then evaluate the world_rom’s output index. If the index is even, then the pixel at this particular DrawX and DrawY is collidable.

Module: world_rom.sv
Inputs: [13:0] read_address, Clk
Outputs: [4:0] data_out
Description: Our world_rom module is a ROM containing indices to different sprites stored in our palette_16_rom. The numbers range from 0 to 27, with the even indices corresponding to collidable sprites (i.e. a brick platform versus a cloud). This ROM enables us to store a simple 5 bit piece of data for each tile on the background as opposed to storing the full 6144 bits that the color hex data for each tile would store. This avoids storing these repeating sprites more than once. 

Module: mario_ani_rom (in mario_standing_rom.sv)
Inputs: [10:0] read_address, Clk
Outputs: [23:0] data_out
Description: Our mario_ani_rom module is a ROM containing the various sprites for Mario. It contains his standing sprite, as well as his sprites for his running animation. The data_out is 24 bits because each line of data in this ROM contains a full 24 bit color hex with a full 8 bits for each RGB channel.

Module: pallete_16_rom.sv
Inputs: [12:0] read_address, Clk
Outputs: [23:0] data_out
Description: Our palette_16_rom module is a ROM containing the various sprites used to populate the background of our world. These are the sprites that are indexed through by our world_rom module, meaning that the read_address of this module is determined by the data_out of the world_rom module.

Module: numbers_rom.sv
Inputs: [11:0] read_address, Clk
Outputs: [23:0] data_out
Description: Our numbers_rom module is a ROM containing the numeric font sprites for our score and timer displays. It contains all the numbers 0 through 9. The data_out is 24 bits because each line of data in this ROM contains a full 24 bit color hex with a full 8 bits for each RGB channel.

Module: counter (in Color_mapper.sv)
Inputs: Clk, Add_En
Outputs: [5:0] count
Description: This module is a 64-bit counter used for animation in our Color Mapper module. The Add_En signal is not used, and is just left over from an earlier version of the module. Our final version simply increments with each clock cycle from the Clk in an always_ff block. It overflows by design every 64 frames because this is roughly one second, making it convenient for animating sprites.

Module: counter_mario_ani (in Color_mapper.sv)
Inputs: Clk
Outputs: [3:0] count
Description: This counter is nearly identical to the above counter module. The only difference is that this module is 16 bits instead of 64 bits. The reason for this is that we wanted a faster counter for the Mario sprite animations than we did for the background sprite animations.

















5. System Level Block Diagram


Figure : Platform Designer

Components
clk_0: This component provides our 50MHz system clock, and also initializes the hardware for the reset signal. It contains two exported signals, the clk and reset signal.
nios2_gen2_0: This component is our NIOS-II processor. Its features include JTAG Debug and ECC RAM Protection. It is driven by the system clock and communicates with all of our other components through instruction master and data master signals.
sdram: This component is the second memory solution created, as well as the one used. The SDRAM of the FPGA is off-chip synchronous DRAM. It is driven by its own clock labeled sdram_pll_c0. It has a data width of 16 bits, 1 chip select, 4 data banks, and an address width of 13x10. The sdram component also has an exported wire labeled sdram_wire that allows it to interface with the rest of our system.
sdram_pll: This module creates a phase-locked loop (pll) that accepts our 50MHz system clock as input and produces a phase shifted signal c0 as output. This phase shifted clock is intended to align to the logic signals being produced by the SDRAM controller. This is the clock labeled sdram_pll_c0 that is driving the SDRAM component. Additionally, there is an sdram_clk signal exported to be used elsewhere in our system.
sysid_qsys_0: This component is necessary when using a processor such as our NIOS-II processor. It gives a system ID to the processor which we can select in Eclipse. In our case, this system ID is 0x00000000, or in other words, the 32-bit zero.
leds_pio: This PIO module is the PIO for our leds. It creates the exported 14-bit conduit signal leds which was not used but we left it in. 
key: This PIO module is the PIO for our run and reset buttons. It creates the exported 2-bit conduit signal key.
SW: This PIO module is the PIO for our switches. It creates the exported 8-bit conduit signal sq_wire which was also unused but left in.
jutag_uart_0: This component is what allows us to communicate with the NIOS II processor through the terminal in Eclipse. Without this module, it wouldn’t be possible to print to the console in Eclipse. We kept a Write FIFO and Read FIFO buffer depth of 64 bytes and IRQ threshold of 8 as were the default values.
keycode: This PIO module is a part of our I/O for the system. It reads the input of the user from the USB keyboard and stores it as an 8-bit value. This value is stored in the external conduit connection labeled keycode.
usb_irq: This PIO module implements the interrupt request for our USB interface. This signal is necessary to ensure the CPU only needs to block whenever the jutag_art needs more data. It is communicated through the exported conduit connection labeled usb_irq.
usb_gpx: This PIO module implements the ubs_gpx signal. It is the general purpose multiplexor. This signal is necessary for connection to the USB chipset.
usb_rst: This PIO module implements the ubs_rst signal. It is the reset signal. This signal is necessary for connection to the USB chipset.
hex_digits_pio: This PIO module is the PIO for our hexadecimal digits. It creates the exported 16-bit conduit signal hex_digits.
timer_0: This interval timer component is necessary to keep track of the various time-outs that USB requires. It is a 1ms timer.
spi_0: This SPI component creates our SPI core. This core has one slave select bit and an SPI clock of 25MHz. The data register has a width of 8 bits.
Connections
The clk_0 drives almost all of the components, and the slave/master connections from the nios2 controlling the Avalon Memory Mapped Slave signals. All the reset signals are mapped to the clk_reset. There are three interrupt signals that can be sent from the timer_0, spi_0 and jtag_uart0 sent to the Nios II processor. These connections allow the NIOS-II to control the rest of our system

6. Design Resources and Statistics
LUT
6,261
DSP
0
Memory(BRAM)
666,552
Flip-Flop
2,706
Frequency
71.31MHz
Static Power
96.84mW
Dynamic Power
129.33mW
Total Power
246.99mW

Figure : Design Resources
7. Conclusion 
Blanking period, og collisions hardcoded, scrolling background with diff frames, offset background graphics by 1,  
We successfully met the baseline requirements for our project. We succeeded in implementing a unique character responding to USB keyboard inputs that could collide with the world in an environment complete with reasonably convincing physics. We also succeeded in generating a sprite-driven background for Mario’s game world. 
Beyond these baseline requirements, our final design deviated from our proposal’s additional difficulty in many ways, due in large part to how extremely specific we were in our proposal on a lot of game mechanics. For example, we abandoned the idea of using coins for score and instead used just time to determine score. We also did not implement Goombas, Piranha Plants, or Koopa Shells. Powerups like the mushroom, fire flower, and star are also absent in our final implementation.
However, we did add several features that expanded on our baseline requirements. The biggest one would be the large level through which we can scroll while playing Mario. We presented our demo with 6 1200 tile frames loaded in our game, but with each frame taking up approximately 2.9% of on-chip memory, we can theoretically load a world with as many as 26 1200 tile frames before running out of on-chip memory on the FPGA. We consider this efficiency to be a great accomplishment. In addition to this, we also display the score and time on the screen using font text rather than on the hex display. 



