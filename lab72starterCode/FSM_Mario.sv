

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
			Halted : 
				if (Run) 
					Next_state = S_18;                      
			S_18 :
				Next_state = S_33_1;
			// Any states involving SRAM require more than one clock cycles.
			// The exact number will be discussed in lecture.
			S_33_1 : 
				Next_state = S_33_2;  //repeat 3 times for memory to be ready
			S_33_2 : 
				Next_state = S_33_3;
			S_33_3 :
				Next_state = S_35;
			S_35 : 
				Next_state = S_32;
			S_01 : 
			//ADD
				Next_state = S_18;
			S_05 :
			//AND
				Next_state = S_18;
			S_09 :
			//NOT
				Next_state = S_18;
			S_00 : 
			//BEN
				if(BEN)
				Next_state = S_22;
				else
				Next_state = S_18;
			S_22 :
			//PC <- PC + off9
				Next_state = S_18;
			S_12 :
			//JMP
				Next_state = S_18;
			S_04 :
			//JSR R7 <- PC
				Next_state = S_21;
			S_21 :
			//PC <- PC + off11
				Next_state = S_18;
			S_06 :
			//LDR
				Next_state = S_25;

			S_25 :
			//MDR <- M[MAR]
				Next_state = S_25_2;
				
			S_25_2 :
				Next_state = S_25_3;
				
			S_25_3 :
				Next_state = S_27;
			S_27 :
			//DR <- MDR, Set CC
				Next_state = S_18;
				
			S_07 :
			//STR
			Next_state = S_23;
			
			S_23 :
			//MDR <- SR
			Next_state = S_16;
			
			S_16 :
			//M[MAR] <- MDR
			Next_state = S_16_2;
			
			S_16_2 :
			Next_state = S_16_3;
			
			S_16_3 :
			Next_state = S_18;
			
			// You need to finish the rest of states.....
			
			// PauseIR1 and PauseIR2 are only for Week 1 such that TAs can see 
			// the values in IR.
			PauseIR1 : 
				if (~Continue) 
					Next_state = PauseIR1;
				else 
					Next_state = PauseIR2;
			PauseIR2 : 
				if (Continue) 
					Next_state = PauseIR2;
				else 
					Next_state = S_18;
			S_32 : 
				case (Opcode)
					4'b0001 : 
						Next_state = S_01;
					4'b0101 :
						Next_state = S_05;
					4'b1001 :
						Next_state = S_09;
					4'b0000 :
						Next_state = S_00;
					4'b1100 :
						Next_state = S_12;
					4'b0100 :
						Next_state = S_04;
					4'b0110 :
						Next_state = S_06;
					4'b0111 :
						Next_state = S_07;
					4'b1101 :
						Next_state = PauseIR1;
						
						

					// You need to finish the rest of opcodes.....

					default : 
						Next_state = S_18;
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
				*/
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
