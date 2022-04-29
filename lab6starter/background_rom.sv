/*
 * ECE385-HelperTools/PNG-To-Txt
 * Author: Rishi Thakkar
 *
 */
/*
module  background_rom
(

		input [18:0]  read_address,
		input  Clk,

		output logic [23:0] data_Out
);

// mem has width of 3 bits and a total of 400 addresses
logic [23:0] mem [0:307200];

initial
begin
	 $readmemh("background1.txt", mem);
end


always_ff @ (posedge Clk) begin

	data_Out<= mem[read_address];
end

endmodule
*/





module  brick_rom
(

		input [7:0]  read_address,
		input  Clk,

		output logic [23:0] data_Out
);

// mem has width of 3 bits and a total of 400 addresses
logic [23:0] mem [0:255];

initial
begin
	 $readmemh("brick.txt", mem);
end


always_ff @ (posedge Clk) begin

	data_Out<= mem[read_address];
end

endmodule


module  question_rom
(

		input [7:0]  read_address,
		input  Clk,

		output logic [23:0] data_Out
);

// mem has width of 3 bits and a total of 400 addresses
logic [23:0] mem [0:255];

initial
begin
	 $readmemh("question.txt", mem);
end


always_ff @ (posedge Clk) begin

	data_Out<= mem[read_address];
end

endmodule



module  bcloud_rom
(

		input [10:0]  read_address,
		input  Clk,

		output logic [23:0] data_Out
);

// mem has width of 3 bits and a total of 400 addresses
logic [23:0] mem [0:1535];

initial
begin
	 $readmemh("bcloud.txt", mem);
end


always_ff @ (posedge Clk) begin

	data_Out<= mem[read_address];
end

endmodule



module  bhill_rom
(

		input [11:0]  read_address,
		input  Clk,

		output logic [23:0] data_Out
);

// mem has width of 3 bits and a total of 400 addresses
logic [23:0] mem [0:2799];

initial
begin
	 $readmemh("bhill.txt", mem); //2800
end


always_ff @ (posedge Clk) begin

	data_Out<= mem[read_address];
end

endmodule

