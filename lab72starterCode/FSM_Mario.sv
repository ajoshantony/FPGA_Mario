

/*
module FSM_Mario (   input logic         Clk, 
									Reset,
									Run,
									Continue,
									is_ground,
									
				input logic[7:0]    keycode,
				  
				  
				output logic[2:0]   right_accel,
										  left_accel,
										  up_accel,
										  down_accel,
				output logic 		  stand_still;
				);

	enum logic [4:0] {  
						Jumping,
						Jumping2,
						Jumping3,
						Falling,
						Falling_right,
						Falling_left,
						Standing,
						Walking_left,
						Walking_right
						}   State, Next_state;   // Internal state logic
		
	always_ff @ (posedge Clk)
	begin
		if (Reset) 
			State <= Halted;
		else 
			State <= Next_state;
	end
   
	always_comb
	begin 
		// Default next state is staying at current state
		Next_state = State;
		
		// Default controls signal values
		down_accel = 3'b000;
		up_accel = 3'b000;
		right_accel = 3'b000;
		left_accel = 3'b000;
	
		// Assign next state
		unique case (State)                
			
			
			Jumping :
			Next_state = Jumping2;
			
			Jumping2 :
			Next_state = Jumping3;
			
			Jumping3 :
			Next_state = Falling;
			
			Falling :
			if((keycode == 8'h07))
			Next_state = Falling_right;
			else if((keycode == 8'h04))
			Next_state = Falling_left;
			else if(is_ground)
			Next_state = Standing;
			else
			Next_state = Falling;
			
			Falling_right :
			if(is_ground)
			Next_state = Standing;ddddddddd
			else if(!(keycode == 8'h07))
			Next_state = Falling;
			else
			Next_state = Falling_right;
			
			Falling_left :
			if(is_ground)
			Next_state = Standing;
			else if(!(keycode == 8'h04))
			Next_state = Falling;
			else
			Next_state = Falling_left;
			
			Standing :
			if(keycode == 8'h26)
			Next_state = Jumping;
			if(keycode == 8'h07)
			Next_state = Walking_right;
			if(keycode == 8'h04)
			Next_state = Walking_left;
			else
			Next_state = Standing;
			
			Walking_left :
			if(keycode == 8'h26)
			Next_state = Jumping;
			if(!(keycode == 8'h04))
			Next_state = Standing;
			else
			Next_state = Walking_left;
			
			Walking_right :
			if(keycode == 8'h26)
			Next_state = Jumping;
			if(!(keycode == 8'h07))
			Next_state = Standing;
			else
			Next_state = Walking_right;
			
			
			
			// You need to finish the rest of states.....
			
			// PauseIR1 and PauseIR2 are only for Week 1 such that TAs can see 
			// the values in IR.
			
				endcase
			
			// You need to finish the rest of states.....

			default : ;

		endcase
		
		// Assign control signals based on current state
		case (State)
			Halted: ;
			
			S_18 : 
				begin 
					GatePC = 1'b1;
					LD_MAR = 1'b1;
					PCMUX = 2'b00;
					LD_PC = 1'b1;
				end
			S_33_1 : 
				Mem_OE = 1'b1;
			S_33_2 : 
				begin 
					Mem_OE = 1'b1;
					//LD_MDR = 1'b1;
				end
			S_33_3 :
				begin
					Mem_OE = 1'b1;
					LD_MDR = 1'b1;
				end
			S_35 : 
				begin 
					GateMDR = 1'b1;
					LD_IR = 1'b1;
				end
			PauseIR1: ;
			PauseIR2: ;
			S_32 : 
				LD_BEN = 1'b1;
			S_01 : 
			begin
			//ADD
				LD_CC = 1'b1;
				GateALU = 1'b1;
				LD_REG = 1'b1;
				SR2MUX = IR_5;
				ALUK = 2'b00;
				SR1MUX = 1'b1;
				DRMUX = 1'b0;
			end

			S_05 :
			//AND
			begin
				LD_CC = 1'b1;
				GateALU = 1'b1;
				LD_REG = 1'b1;
				SR2MUX = IR_5;
				ALUK = 2'b01;
				SR1MUX = 1'b1;
				DRMUX = 1'b0;
				end
			S_09 :
			//NOT
			begin
				LD_CC = 1'b1;
				GateALU = 1'b1;
				LD_REG = 1'b1;
				SR2MUX = IR_5;
				ALUK = 2'b10;
				SR1MUX = 1'b1;
				DRMUX = 1'b0;
				end
			S_00 : 
			//BEN
			begin
				end
			S_22 :
			//PC <- PC + off9
			begin
				LD_PC = 1;
				PCMUX = 2'b10;
				ADDR1MUX = 1'b0;
				ADDR2MUX = 2'b10;
				
				end
			S_12 :
			//JMP
			begin
				/*
				LD_PC = 1'b1;
				PCMUX = 2'b10;
				SR1MUX = 1'b1;
				ADDR1MUX = 1'b1;
				ADDR2MUX = 2'b01;
				
				SR1MUX = 1'b1;
				ALUK = 2'b11;//pass A
				GateALU = 1'b1;//open gatealu
				PCMUX = 2'b01;//pc mux from bus
				LD_PC = 1'b1;//LD_PC 
				
				end
			S_04 :
			//JSR R7 <- PC
			begin
				GatePC = 1'b1;
				DRMUX = 1'b1;
				LD_REG = 1'b1;
				end
			S_21 :
			//PC <- PC + off11
			begin
				LD_PC = 1'b1;
				PCMUX = 2'b10;
				ADDR1MUX = 1'b0;
				ADDR2MUX = 2'b11;
				end
			S_06 :
			//LDR
			begin
				ADDR2MUX = 2'b01;
				ADDR1MUX = 1'b1;
				GateMARMUX = 1'b1;
				LD_MAR = 1'b1;
				SR1MUX = 1'b1;
				end

			S_25 :
			//MDR <- M[MAR]
			begin
				//LD_MDR = 1'b1;
				Mem_OE = 1'b1;
				end
				
			S_25_2 :
			begin	
				Mem_OE = 1'b1;
			end
			
			S_25_3 :
			begin	
				Mem_OE = 1'b1;
				LD_MDR = 1'b1;
			end
				
			S_27 :
			//DR <- MDR, Set CC
			begin
				GateMDR = 1'b1;
				LD_REG = 1'b1;
				LD_CC = 1'b1;
				end
			S_07 :
			//STRF
			begin
				GateMARMUX = 1'b1;
				SR1MUX = 1'b1;
				ADDR1MUX = 1'b1;
				ADDR2MUX = 2'b01;
				LD_MAR = 1'b1;
				end
			S_23 :
			//MDR <- SR
			begin
				ALUK = 2'b11;
				GateALU = 1'b1;
				SR1MUX = 1'b0;
				LD_MDR = 1'b1;
			end
			S_16 :
			begin
				Mem_WE = 1'b1;
				//GateMDR = 1'b1;
				//LD_MAR = 1'b1;
				end
				
			S_16_2 :
			begin
				Mem_WE = 1'b1;
				//GateMDR = 1'b1;
				//LD_MAR = 1'b1;
				end
				
			S_16_3 :
			begin
				Mem_WE = 1'b1;
				GateMDR = 1'b1;
				LD_MAR = 1'b1;
				end
				

			// You need to finish the rest of states.....

			default : ;
		endcase
	end 

	
endmodule

*/