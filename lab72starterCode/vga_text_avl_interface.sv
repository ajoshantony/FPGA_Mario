/************************************************************************
Avalon-MM Interface VGA Text mode display

Register Map:
0x000-0x0257 : VRAM, 80x30 (2400 byte, 600 word) raster order (first column then row)
0x258        : control register

VRAM Format:
X->
[ 31  30-24][ 23  22-16][ 15  14-8 ][ 7    6-0 ]
[IV3][CODE3][IV2][CODE2][IV1][CODE1][IV0][CODE0]

IVn = Draw inverse glyph
CODEn = Glyph code from IBM codepage 437

Control Register Format:
[[31-25][24-21][20-17][16-13][ 12-9][ 8-5 ][ 4-1 ][   0    ] 
[[RSVD ][FGD_R][FGD_G][FGD_B][BKG_R][BKG_G][BKG_B][RESERVED]

VSYNC signal = bit which flips on every Vsync (time for new frame), used to synchronize software
BKG_R/G/B = Background color, flipped with foreground when IVn bit is set
FGD_R/G/B = Foreground color, flipped with background when Inv bit is set

************************************************************************/
`define NUM_REGS 8 //80*30 characters / 4 characters per register
`define CTRL_REG 600 //index of control register
module mux_2 
#(parameter width = 16)
			  (input logic [width-1:0]Din0,
				input [width-1:0] Din1,
				input  sel,
				output logic [width-1:0] Dout);
always_comb
	begin

		case (sel)
			1'b0 : Dout = Din0;
			default : Dout = Din1;
			endcase
	end
endmodule

module vga_text_avl_interface (
	// Avalon Clock Input, note this clock is also used for VGA, so this must be 50Mhz
	// We can put a clock divider here in the future to make this IP more generalizable
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,					// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,			// Avalon-MM Byte Enable
	input  logic [11:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,		// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,		// Avalon-MM Read Data
	
	// Exported Conduit (mapped to VGA port - make sure you export in Platform Designer)
	output logic [7:0]  red, green, blue,	// VGA color channels (mapped to output pins in top-level)
	output logic hs, vs						// VGA HS/VS
);

logic [31:0] LOCAL_REG [`NUM_REGS]; // Registers
//put other local variables here
logic blank,sync,VGA_VS,VGA_HS,VGA_clk;
logic [7:0] sprite_data;
logic [10:0] sprite_addr;
logic [9:0] DrawX,DrawY;


//Declare submodules..e.g. VGA controller, ROMS, etc
vga_controller vga_mod( .Clk(CLK),.Reset(RESET),.hs(hs),.vs(vs),.pixel_clk(VGA_clk), .blank(blank),.sync(sync),  
								.DrawX(DrawX),.DrawY(DrawY) 
);
//to start mult vram addr *16 // just shift left 4 to get 11 bit addr
font_rom font_rom_mod(.addr(sprite_addr),.data(sprite_data)

);

/*
color_mapper color_mod( .BallX(ballxsig),.BallY(ballysig), .DrawX(drawxsig), .DrawY(drawysig),.Ball_size(ballsizesig),
                       .Red(Red),.Green(Green), .Blue(Blue) 

);	


   
// Read and write from AVL interface to register block, note that READ waitstate = 1, so this should be in always_ff
*/
// control reg CTRL_REG
//RESET
/*
always_ff @(posedge CLK) begin

//RESEt set all regs to 0
if(RESET)
	begin
	for(int i = 0; i<601;i++)
	LOCAL_REG[i] <= 0;
	end
else
begin

if(AVL_WRITE && AVL_CS)
	begin
	if(AVL_BYTE_EN == 4'b1111) //full 32
		begin
		LOCAL_REG[AVL_ADDR] <= AVL_WRITEDATA;
		end
		
	else if (AVL_BYTE_EN == 4'b1100)
		begin //upper 2 bytes
		LOCAL_REG[AVL_ADDR][31:16] <= AVL_WRITEDATA[31:16];
		end
		
	else if (AVL_BYTE_EN == 4'b0011)
		begin //2 lower bytes
	  LOCAL_REG[AVL_ADDR][15:0] <= AVL_WRITEDATA[15:0];
		end
		
	else if (AVL_BYTE_EN == 4'b1000)
		begin 
		LOCAL_REG[AVL_ADDR][31:24] <= AVL_WRITEDATA[31:24];
		end
		
	else if (AVL_BYTE_EN == 4'b0100)
		begin 
		LOCAL_REG[AVL_ADDR][23:16]<= AVL_WRITEDATA[23:16];
		end
		
	else if (AVL_BYTE_EN == 4'b0010)
		begin 
		LOCAL_REG[AVL_ADDR][15:8] <= AVL_WRITEDATA[15:8];
		end
		
	else if (AVL_BYTE_EN == 4'b0001)
		begin 
		LOCAL_REG[AVL_ADDR][7:0] <= AVL_WRITEDATA[7:0];
		end
	end
	else
	begin
	
		//read ready wihitin 1 wait state 1 clock cycle 
		if(AVL_READ && AVL_CS)
		begin
		AVL_READDATA <= LOCAL_REG[AVL_ADDR];
		end
	end
	end	
end
*/
//2048 bit
//zero extend avalon addr and other stuff
ram2rw ram0(.address_a(ADDR_A), .address_b(AVL_ADDR), .byteena_a(0), .byteena_b(AVL_BYTE_EN),
				.clock(CLK), .data_a(0), .data_b(AVL_WRITEDATA), .rden_a(1), .rden_b(AVL_READ && AVL_CS),
			   .wren_a(0), .wren_b(~AVL_ADDR[11] && AVL_WRITE && AVL_CS), .q_a(READDATA_VGA), .q_b(ram2_data)
                                                                                                                                                                                        
);


mux_2 #(32) ram_mux (.Din0(ram2_data),.Din1(pallete_read),.sel(AVL_ADDR[11]),.Dout(AVL_READDATA)
); 

//calc curr addr of font rom
// rownum =sprite_addr*16 + drawY%16
//colnum = sprite_data[drawX%8]

logic [12:0] ac; 
logic [11:0] av;
logic [31:0] vdata;
logic [15:0] chard;
logic sprite_on;
logic sprite_inv;
logic [11:0] rgb_back, rgb_fore;

logic [11:0] ADDR_A;
logic [31:0] READDATA_VGA;

logic [31:0] pallete_back;
logic [31:0] pallete_fore;

logic [31:0] pallete_read;

logic [31:0] ram2_data;
//handle drawing (may either be combinational or sequential - or both).

//XOR to get for or back


mux_2 chard_mux(.Din0(vdata[15:0]),.Din1(vdata[31:16]),.sel(ac[0]),.Dout(chard)
); 

mux_2 #(12) back_mux(.Din0(pallete_back[12:1]),.Din1(pallete_back[24:13]),.sel(chard[0]),.Dout(rgb_back)
); 

mux_2 #(12) fore_mux(.Din0(pallete_fore[12:1]),.Din1(pallete_fore[24:13]),.sel(chard[4]),.Dout(rgb_fore)
);

always_comb
begin
ac = DrawX[9:3] + DrawY[9:4]*80;
av = ac[11:1];
ADDR_A = av;  //1 clk for data? //maybe 0 extend 
//vdata = LOCAL_REG[av];

vdata = READDATA_VGA;
	
sprite_addr = chard[14:8]*16 + DrawY[3:0];

sprite_on = sprite_data[7-DrawX[2:0]];
sprite_inv = chard[15];

//rgb_back = LOCAL_REG[600][12:1];
//rgb_fore = LOCAL_REG[600][24:13];
//calc rgb fore and back 

pallete_back = LOCAL_REG[chard[3:1]]; //back
pallete_fore = LOCAL_REG[chard[7:5]];//fore


//rgb_back = LOCAL_REG[ADDR_pal][12:1];
//rgb_fore = LOCAL_REG[ADDR_pal][24:13];

//[3:1] chooses which row, [0] if(==0)chooses[12:1] if(==1)[24:13] 
end
                                                                                                                                           

always_ff @(posedge CLK) begin

//RESEt set all regs to 0
if(RESET)
	begin
	for(int i = 0; i<8; i++)
	LOCAL_REG[i] <= 0;
	end
else
begin
	
		//read ready wihitin 1 wait state 1 clock cycle 
		if(AVL_ADDR[11] && AVL_WRITE && AVL_CS)
		begin
		LOCAL_REG[AVL_ADDR[2:0]] <= AVL_WRITEDATA /*32'hffffffff*/;
		end
		 
		if(AVL_READ && AVL_CS)
		begin
		pallete_read <= LOCAL_REG[AVL_ADDR[2:0]];
		end
		
	end
end



//write to rgb pixel clk
always_ff @(posedge VGA_clk) 
begin
//set rgb
	if(blank)
	begin
	
		if(sprite_on ^ sprite_inv)
		begin
		//fore
		
			red <= rgb_fore[11:8];
			green <= rgb_fore[7:4];
			blue <= rgb_fore[3:0];
		
			/*
			red <= 4'h0;
			green <= 4'hf;
			blue <= 4'h0;
			*/
		end
		
		else
		begin
		//back
			
			red <= rgb_back[11:8];
			green <= rgb_back[7:4];
			blue <= rgb_back[3:0];
		
			/*
			red <= 4'hf;
			green <= 4'h0;
			blue <= 4'h0;
			*/
		end

	end
	
	else
	begin
			red <= 4'h0;
			green <= 4'h0;
			blue <= 4'h0;
	
	end

end



// calc sprite_addr how to ignore input bit, mem logic, draw sprite , main.c use

/*
logic shape_on;
logic[10:0] shape_x =300;
logic[10:0] shape_y = 300;
logic[10:0] shape_size_x = 8;
logic[10:0] shape_size_y = 16;

logic shape2_on;
logic[10:0] shape2_x =100;
logic[10:0] shape2_y = 100;
logic[10:0] shape2_size_x = 8;
logic[10:0] shape2_size_y = 16;

always_comb
begin:Ball_on_proc
	if(DrawX >= shape_x && DrawX < shape_x + shape_size_x &&
	DrawY >= shape_y && DrawY < shape_y + shape_size_y)
	begin
		shape_on = 1'b1;
		shape2_on = 1'b0;
		sprite_addr= (DrawY-shape_y + 16*'h48);
	end
	else if(DrawX >= shape2_x && DrawX < shape2_x + shape2_size_x &&
				DrawY >= shape2_y && DrawY < shape2_y + shape2_size_y)
				
	begin
		shape_on = 1'b0;
		shape2_on = 1'b1;
		sprite_addr = (DrawY-shape2_y + 16*'h49);
	end
	else
	begin
		shape_on = 1'b0;
		shape2_on = 1'b0;
		sprite_addr = 10'b0;
		
	end
end	

always_comb
begin:RBG_Display
	if((shape_on == 1'b1) && sprite_data[DrawX - shape_x] == 1'b1)
	begin
		red = 8'h00;
		green = 8'hff;
		blue = 8'hff;
	end
	
	else if ((shape2_on == 1'b1) && sprite_data[DrawX - shape2_x] == 1'b1)
	begin 
		red = 8'hff;
		green = 8'hff;
		blue = 8'h00;
	end
	
	else
	begin
		red = 8'h4f - DrawX[9:3];
		green = 8'h00;
		blue = 8'h44;
	
	end

end

*/

endmodule
