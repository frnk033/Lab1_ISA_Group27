LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

ENTITY myfir_adv is
PORT  (DIN0, DIN1, DIN2    : in signed(nb-1 downto 0); 
	   b0, b1, b2, b3, b4, 
       b5, b6, b7, b8, b9, 
       b10                 : in signed(nb-1 downto 0);	 
	   Vin, CLK, RST_n     : in std_logic;
	   Vout				   : out std_logic;
	   Dout0, Dout1, Dout2 : out signed(nb-1 downto 0)
	  );
END myfir_adv;

ARCHITECTURE beh of myfir_adv is

signal x0, x1, x2 									: signed (nb-2 downto 0); -- shifted right
signal y0_out, y1_out, y2_out 						: signed (nb-1 downto 0);
signal max_value, sum_sat_0, sum_sat_1, sum_sat_2 	: signed(nb-1 downto 0);
signal y0_sh, y1_sh, y2_sh							: signed(nb-1 downto 0);
signal y0, y1, y2 									: signed(add_w-1 downto 0);

type internal_array is array (integer range 0 to N) of signed(nb-2 downto 0);
signal b		: internal_array;
type internal_array_01 is array (integer range 0 to 12) of signed(nb-2 downto 0);
signal x0_regs	: internal_array_01;
signal x1_regs	: internal_array_01;
type internal_array2 is array (integer range 0 to 13) of signed(nb-2 downto 0);
signal x2_regs	: internal_array2;

signal Vin_regs: std_logic_vector(13 downto 0);

type mult_internal_array is array (integer range 0 to N) of signed(mul_w-1 downto 0);
signal mult_part0, mult_part1, mult_part2  		: mult_internal_array;
signal mult_shift0, mult_shift1, mult_shift2 	: mult_internal_array;


type sum_array is array (integer range 0 to N) of signed(add_w-1 downto 0);
signal y0_part_next, y1_part_next, y2_part_next 			: sum_array;
signal y0_part, y1_part, y2_part 							: sum_array;
signal mult_short0, mult_short1, mult_short2 				: sum_array;
signal mult_short0_next, mult_short1_next, mult_short2_next : sum_array;

signal xor_of_0, xor_of_1, xor_of_2 : std_logic_vector(3 downto 0);
signal overflow_p_0, overflow_p_1, overflow_p_2 : std_logic;

component reg is
	generic(
		data_size 	: integer := 8
		);
	port(
		Rst  		: in std_logic; 
		clk  		: in std_logic; 
		enable		: in std_logic;
		Din  		: in signed(data_size-1 downto 0);
		Dout 		: out signed(data_size-1 downto 0) 
		);
end component;

component FF is 
	port(
		Rst  		: in std_logic; 
		clk  		: in std_logic; 
		enable	    : in std_logic;
		Din  		: in std_logic;
		Dout 		: out std_logic
		);
end component;

component mux2to1 is
	Generic(N: integer := 9);
	Port ( 	A: In signed (N-1 downto 0);
			B: In signed(N-1 downto 0);
			S: In std_logic;
			Y: Out signed(N-1 downto 0));
end component;

Begin 

-- DIN0, DIN1 amd DIN2 are truncated and passed through registers
input_reg0: reg port map (Rst => rst_n, clk => clk, enable => Vin, Din => Din0(Nb-1 downto 1), Dout => x0);
input_reg1: reg port map (Rst => rst_n, clk => clk, enable => Vin, Din => Din1(Nb-1 downto 1), Dout => x1);
input_reg2: reg port map (Rst => rst_n, clk => clk, enable => Vin, Din => Din2(Nb-1 downto 1), Dout => x2);

-- input b_i coefficients are truncated and passed through registers
regsb0	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b0(Nb-1 downto 1), Dout => b(0));
regsb1	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b1(Nb-1 downto 1), Dout => b(1));
regsb2	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b2(Nb-1 downto 1), Dout => b(2));
regsb3	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b3(Nb-1 downto 1), Dout => b(3));
regsb4	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b4(Nb-1 downto 1), Dout => b(4));
regsb5	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b5(Nb-1 downto 1), Dout => b(5));
regsb6	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b6(Nb-1 downto 1), Dout => b(6));
regsb7	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b7(Nb-1 downto 1), Dout => b(7));
regsb8	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b8(Nb-1 downto 1), Dout => b(8));
regsb9	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b9(Nb-1 downto 1), Dout => b(9));
regsb10	: reg port map (Rst => rst_n, clk => clk, enable => '1', Din => b10(Nb-1 downto 1), Dout => b(10));

x0_regs(0) <= x0;
x1_regs(0) <= x1;
x2_regs(0) <= x2;

-- chain of register for input DIN0
x0_regs_first: 		reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(1), Din => x0_regs(0), Dout => x0_regs(1));
x0_regs_unfolding0: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(2), Din => x0_regs(1), Dout => x0_regs(2));
x0_regs_pipe0:		for i in 3 to 5 generate
						x0_regs_pipe0i : reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i), Din => x0_regs(i-1), Dout => x0_regs(i));
					end generate;
x0_regs_unfolding1: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(5), Din => x0_regs(5), Dout => x0_regs(6));
x0_regs_pipe1:		for i in 7 to 9 generate
						x0_regs_pipe1i : reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i-1), Din => x0_regs(i-1), Dout => x0_regs(i));
					end generate;
x0_regs_unfolding2: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(8), Din => x0_regs(9), Dout => x0_regs(10));
x0_regs_pipe2:		for i in 11 to 12 generate
						x0_regs_pipe02i: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i-2), Din => x0_regs(i-1), Dout => x0_regs(i));
					end generate;

-- chain of registers for input DIN1
x1_regs_unfolding0: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(1), Din => x1_regs(0), Dout => x1_regs(1));
x1_regs_pipe0:		for i in 2 to 4 generate
						x1_regs_pipe0i : reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i), Din => x1_regs(i-1), Dout => x1_regs(i));
					end generate;
x1_regs_unfolding1: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(4), Din => x1_regs(4), Dout => x1_regs(5));
x1_regs_pipe1:		for i in 6 to 8 generate
						x1_regs_pipe1i : reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i-1), Din => x1_regs(i-1), Dout => x1_regs(i));
					end generate;
x1_regs_unfolding2: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(7), Din => x1_regs(8), Dout => x1_regs(9));
x1_regs_pipe2:		for i in 10 to 12 generate
						x1_regs_pipe2i : reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i-2), Din => x1_regs(i-1), Dout => x1_regs(i));
					end generate;

--chain of registers for input DIN2
x2_regs_unfolding0: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(1), Din => x2_regs(0), Dout => x2_regs(1));
x2_regs_pipe0:		for i in 2 to 4 generate
						x2_regs_pipe0i : reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i), Din => x2_regs(i-1), Dout => x2_regs(i));
					end generate;
x2_regs_unfolding1: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(4), Din => x2_regs(4), Dout => x2_regs(5));
x2_regs_pipe1:		for i in 6 to 8 generate
						x2_regs_pipe1i : reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i-1), Din => x2_regs(i-1), Dout => x2_regs(i));
					end generate;
x2_regs_unfolding2: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(7), Din => x2_regs(8), Dout => x2_regs(9));
x2_regs_pipe2:		for i in 10 to 12 generate
						x2_regs_pipe2i : reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(i-2), Din => x2_regs(i-1), Dout => x2_regs(i));
					end generate;
x2_regs_unfolding3: reg port map (Rst => rst_n, clk => clk, enable => Vin_regs(10), Din => x2_regs(12), Dout => x2_regs(13));


--First branch
mult_part0(0)	<= x0_regs(0)*b(0);
mult_part0(1) 	<= x2_regs(1)*b(1);
mult_part0(2) 	<= x1_regs(2)*b(2);
mult_part0(3) 	<= x0_regs(3)*b(3);
mult_part0(4) 	<= x2_regs(5)*b(4);
mult_part0(5) 	<= x1_regs(6)*b(5);
mult_part0(6) 	<= x0_regs(7)*b(6);
mult_part0(7) 	<= x2_regs(9)*b(7);
mult_part0(8) 	<= x1_regs(10)*b(8);
mult_part0(9) 	<= x0_regs(11)*b(9);
mult_part0(10) 	<= x2_regs(13)*b(10);

mult_shift0(0) <= shift_right(mult_part0(0), Nb-2);
mult_short0(0) <= mult_shift0(0)(11 downto 0);
pipe_r0: reg generic map (data_size => 12  ) port map (Rst => rst_n, clk => clk, enable => Vin_regs(1), Din => mult_short0(0), Dout => mult_short0_next(0));
y0_part(0) <= mult_short0_next(0);
y0_part_next(0) <= y0_part(0);
add_phase0:	for i in 1 to 10 generate
				mult_shift0(i) <= shift_right(mult_part0(i), Nb-2);
				mult_short0(i) <= mult_shift0(i)(11 downto 0);	
				pipe_reg0: reg generic map (data_size => 12  ) port map (Rst => rst_n, clk => clk, enable => Vin_regs(i), Din => mult_short0(i), Dout => mult_short0_next(i));
				y0_part(i) <= y0_part_next(i-1) + mult_short0_next(i);
			    pipe_regs0: reg generic map (data_size => 12  ) port map (Rst => rst_n, clk => clk, enable => Vin_regs(i+1), Din => y0_part(i), Dout => y0_part_next(i));	
			end generate;  

y0 <= y0_part_next(NT-1);

-- overflow saturation 0
couple_check_0: for i in 0 to 3 generate
					xor_of_0(i) <= y0(7+i) xor y0(8+i);
				end generate;
overflow_p_0 <= xor_of_0(0) or xor_of_0(1) or xor_of_0(2) or xor_of_0(3); -- 1 if overflow


-- saturated value: 0111...1 if positive. If negative, complemented => 1000...0
max_value <= "011111111";
saturation_xor_0: 	for i in 0 to Nb-1 generate
						sum_sat_0(i) <= max_value(i) xor y0(11);
					end generate;

-- sum short (direct result) if overflow = 0 ; no overflow
-- saturated value if overflow
y0_sh <= y0(Nb-2 downto 0) & '0';
saturation_mux_0:  mux2to1	port map (A =>  y0_sh, B => sum_sat_0, S => overflow_p_0, Y => y0_out);

output_reg0		: reg	generic map (data_size => 9) 
						port map (Rst => rst_n, clk => clk, enable => '1', Din => y0_out, Dout => Dout0);


--second branch
mult_part1(0) 	<= x1_regs(0)*b(0);
mult_part1(1) 	<= x0_regs(0)*b(1);
mult_part1(2) 	<= x2_regs(2)*b(2);
mult_part1(3) 	<= x1_regs(3)*b(3);
mult_part1(4) 	<= x0_regs(4)*b(4);
mult_part1(5) 	<= x2_regs(6)*b(5);
mult_part1(6) 	<= x1_regs(7)*b(6);
mult_part1(7) 	<= x0_regs(8)*b(7);
mult_part1(8) 	<= x2_regs(10)*b(8);
mult_part1(9) 	<= x1_regs(11)*b(9);
mult_part1(10) 	<= x0_regs(12)*b(10);

mult_shift1(0) <= shift_right(mult_part1(0), Nb-2);
mult_short1(0) <= mult_shift1(0)(11 downto 0);
pipe_r1: reg generic map (data_size => 12) port map (Rst => rst_n, clk => clk, enable => Vin_regs(1), Din => mult_short1(0), Dout => mult_short1_next(0));
y1_part(0) <= mult_short1_next(0);
y1_part_next(0) <= y1_part(0);
add_phase1: for i in 1 to 10 generate
				mult_shift1(i) <= shift_right(mult_part1(i), Nb-2);
				mult_short1(i) <= mult_shift1(i)(11 downto 0);	
				pipe_reg1: reg generic map (data_size => 12) port map (Rst => rst_n, clk => clk, enable => Vin_regs(i), Din => mult_short1(i), Dout => mult_short1_next(i));
				y1_part(i) <= y1_part_next(i-1) + mult_short1_next(i);
	            pipe_regs1: reg generic map (data_size => 12) port map (Rst => rst_n, clk => clk, enable => Vin_regs(i+1), Din => y1_part(i), Dout => y1_part_next(i));	
			end generate;

y1 <= y1_part_next(NT-1);

-- overflow saturation 1
couple_check_1: for i in 0 to 3 generate
					xor_of_1(i) <= y1(7+i) xor y1(8+i);
				end generate;
overflow_p_1 <= xor_of_1(0) or xor_of_1(1) or xor_of_1(2) or xor_of_1(3); -- 1 if overflow


-- saturated value: 0111...1 if positive. If negative, complemented => 1000...0
-- max_value <= "011111111";
saturation_xor_1:	for i in 0 to Nb-1 generate
						sum_sat_1(i) <= max_value(i) xor y1(11);
					end generate;

-- sum short (direct result) if overflow = 0 ; no overflow
-- saturated value if overflow
y1_sh <= y1(Nb-2 downto 0) & '0';
saturation_mux_1:  mux2to1	port map (A =>  y1_sh, B => sum_sat_1, S => overflow_p_1, Y => y1_out);

output_reg1		: reg	generic map (data_size => 9 ) 
						port map (Rst => rst_n, clk => clk, enable => '1', Din => y1_out, Dout => Dout1);



--third branch
mult_part2(0) 	<= x2_regs(0)*b(0);
mult_part2(1) 	<= x1_regs(0)*b(1);
mult_part2(2) 	<= x0_regs(1)*b(2);
mult_part2(3) 	<= x2_regs(3)*b(3);
mult_part2(4) 	<= x1_regs(4)*b(4);
mult_part2(5) 	<= x0_regs(5)*b(5);
mult_part2(6) 	<= x2_regs(7)*b(6);
mult_part2(7) 	<= x1_regs(8)*b(7);
mult_part2(8) 	<= x0_regs(9)*b(8);
mult_part2(9) 	<= x2_regs(11)*b(9);
mult_part2(10) 	<= x1_regs(12)*b(10);

mult_shift2(0) <= shift_right(mult_part2(0), Nb-2);
mult_short2(0) <= mult_shift2(0)(11 downto 0);
pipe_r2: reg generic map (data_size => 12  ) port map (Rst => rst_n, clk => clk, enable => Vin_regs(1), Din => mult_short2(0), Dout => mult_short2_next(0));
y2_part(0) <= mult_short2_next(0);
y2_part_next(0) <= y2_part(0);
add_phase2: for i in 1 to 10 generate
				mult_shift2(i) <= shift_right(mult_part2(i), Nb-2);
				mult_short2(i) <= mult_shift2(i)(11 downto 0);	
				pipe_reg2: reg generic map (data_size => 12) port map (Rst => rst_n, clk => clk, enable => Vin_regs(i), Din => mult_short2(i), Dout => mult_short2_next(i));
				y2_part(i) <= y2_part_next(i-1) + mult_short2_next(i);
	            pipe_regs2: reg generic map (data_size => 12) port map (Rst => rst_n, clk => clk, enable => Vin_regs(i+1), Din => y2_part(i), Dout => y2_part_next(i));	
			end generate;  

y2 <= y2_part_next(NT-1);

-- overflow saturation 0
couple_check_2: for i in 0 to 3 generate
					xor_of_2(i) <= y2(7+i) xor y2(8+i);
				end generate;
overflow_p_2 <= xor_of_2(0) or xor_of_2(1) or xor_of_2(2) or xor_of_2(3); -- 1 if overflow


-- saturated value: 0111...1 if positive. If negative, complemented => 1000...0
--max_value <= "011111111";
saturation_xor_2:	for i in 0 to Nb-1 generate
						sum_sat_2(i) <= max_value(i) xor y2(11);
					end generate;

-- sum short (direct result) if overflow = 0 ; no overflow
-- saturated value if overflow
y2_sh <= y2(Nb-2 downto 0) & '0';
saturation_mux_2:  mux2to1	port map (A =>  y2_sh, B => sum_sat_2, S => overflow_p_2, Y => y2_out);

output_reg2		: reg	generic map (data_size => 9 ) 
						port map (Rst => rst_n, clk => clk, enable => '1', Din => y2_out, Dout => Dout2);




Vin_regs(0) <= Vin;
vin_initial: FF port map (Rst => rst_n, clk => clk, enable => '1', Din => Vin_regs(0), Dout => Vin_regs(1));
vin_pipe:	for i in 2 to 12 generate 
		 		vout_FF: FF port map (Rst => rst_n, clk => clk, enable => '1', Din => Vin_regs(i-1), Dout => Vin_regs(i));
			end generate;
vout_final	: FF port map (Rst => rst_n, clk => clk, enable => '1', Din => Vin_regs(12), Dout => Vin_regs(13));
Vout <= Vin_regs(13);

end ARCHITECTURE;



