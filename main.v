/* 
The eight binary switches are used to take value into the eight bits 
of the registers in the meory module. The toggle switches are used to 
reset, execute, insert, respectively.
*/

module main	(	input clk,
			input s1, s2, s3, s4,
			input b1, b2, b3, b4, b5, b6, b7, b8,
 			output wire [6:0] led,
			output wire d1, d2, d3, d4,
			output wire [7:0] s_led);

//General initialisations
reg [127:0] chk2, chk3, chk4;			//For taking the input of the toggle switches
reg [7:0] state;				//To denote state of FSM
reg [7:0] ret_state;				//Return state
reg [7:0] disp;					//Whatever the register contains, the display module displays it
reg [7:0] count;				//Very imp.
wire [7:0] binary_input;
wire [3:0] opcode;
wire [1:0] val;
wire [1:0] ra, rb;
reg busy, pc_disp;				//For the display module

//CPU registers
reg [5:0] pc;
reg [7:0] r0,r1,r2,r3;
reg [5:0] fp, sp;

//Memory module initialisations
reg [5:0] data_adrs;
reg [5:0] prgm_adrs;
reg data_mode;
reg prgm_mode;
reg data_erase;
reg prgm_erase;
reg [7:0] data_data;
reg [7:0] prgm_data;
wire [7:0] data_out;
wire [7:0] prgm_out;

//Add substract module initialisations
reg addsub;
reg [7:0] op1;
reg [7:0] op2;
wire [7:0] out_addsub;


//wire assigns
assign binary_input[0] = b8;
assign binary_input[1] = b7;
assign binary_input[2] = b6;
assign binary_input[3] = b5;
assign binary_input[4] = b4;
assign binary_input[5] = b3;
assign binary_input[6] = b2;
assign binary_input[7] = b1;
assign opcode = prgm_out[7:4];
assign val = prgm_out[1:0];
assign ra = prgm_out[3:2];
assign rb = prgm_out[1:0];


initial begin
/*Some initialisations*/
state = 0;
disp = 0;
data_mode = 0;
prgm_mode = 0;
data_erase = 0;
prgm_erase = 0;
pc = 0;
addsub = 0;
end


data_mem m1(.adrs(data_adrs), .erase(data_erase), .mode(data_mode), .data(data_data), .out(data_out), .clk(clk));
prgm_mem m2(.adrs(prgm_adrs), .erase(prgm_erase), .mode(prgm_mode), .data(prgm_data), .out(prgm_out), .clk(clk));
add_sub as1(.clk(clk), .oper(addsub), .a(op1), .b(op2), .out(out_addsub));
display disp1(.inp(disp), .clk(clk), .busy(busy), .pc_disp(pc_disp), .led(led), .d1(d1), .d2(d2), .d3(d3), .d4(d4), .s_led(s_led));


always @(posedge clk)					
begin
	//To help get the inputs of the toggle switches
	chk4 <= chk4<<1;				//Corressponds to the input switch 3
	chk4[0] <= s4;
	chk3 <= chk3<<1;				//Corressponds to the input switch 3
	chk3[0] <= s3;
	chk2 <= chk2<<1;				//Corressponds to the input switch 3
	chk2[0] <= s2;
end

always @(posedge clk)
begin
	if (s1==1)	begin
		prgm_erase = 1;
		state = 0;
		disp = 0;
		prgm_mode = 0;
		data_mode = 0;
		pc = 0;
	end

	case(state)
	0: begin
		if (chk3==1)	begin			//Insert
			prgm_erase = 0;
			disp = pc;
			busy = 1;
			pc_disp = 1;
			count = 0;
			state = 5;
		end
		if (chk2==1)	begin			//Execute
			prgm_erase = 0;
			busy = 1;
			pc_disp = 0;
			disp = 0;
			count = 0;
			pc = 0;
			state = 1;
		end
		if (chk4==1)	begin			//Forward
			prgm_erase = 0;
			disp = pc;
			busy = 1;
			pc_disp = 1;
			pc = pc+1;
		end
	end

	1: begin				//Execute state
		prgm_adrs = pc;
		ret_state = 6;
		pc = pc+1;
		count = 0;
		state = 2;
	end
	2: begin				//Read state
		if (count==2)	begin
			count = 0;
			state = ret_state;
		end
	end
	3: begin				//Program Write state
		prgm_mode = 1;
		if (count==3)	begin
			prgm_mode = 0;
			count = 0;
			state = ret_state;
		end
	end
	4: begin				//Data Write state
		data_mode = 1;
		if (count==3)	begin
			data_mode = 0;
			count = 0;
			state = ret_state;
		end
	end

	5: begin				//Program input state
		prgm_data = binary_input;
		prgm_adrs = pc;
		pc = pc+1;
		ret_state = 0;
		count = 0;
		state = 3;
	end
	
	6: begin				//Checking the opcode state
		if (opcode==0)	begin
			if (prgm_out==0)	begin	//No operation
				count = 0;
				state = 1;
			end
			if (prgm_out==1)	begin	//Input
				r0 = binary_input;
				count = 0;
				state = 1;
			end
			if (prgm_out==2)	begin	//Output
				disp = r0;
				count = 0;
				state = 1;	
			end
			if (prgm_out==3)	begin	//Sleep
				count = 0;
				state = 1;
			end
			if (prgm_out==15)	begin	//Halt
				count = 0;
				pc = 0;
				state = 0;
			end
									
		end
		if (opcode==1)	begin		//add ra + rb	
			addsub = 0;
			count = 0;
			ret_state = 8;
			state = 7;
		end
	end
	7: begin					//Reads ra and rb to store in op1 and op2
		case(ra)
		0:begin op1 = r0; end
		1:begin op1 = r1; end
		2:begin op1 = r2; end
		3:begin op1 = r3; end
		endcase

		case(rb)
		0:begin op2 = r0; end
		1:begin op2 = r1; end
		2:begin op2 = r2; end
		3:begin op2 = r3; end
		endcase

		count = 0;
		state = ret_state;
	end
	8: begin
		r0 = out_addsub;
		count = 0;
		state = 1;
	end

	endcase
	
	count = count+1;
end

endmodule
