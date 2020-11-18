library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myfir is 
	generic(
		Nb 	: integer := 9;
		NT	: integer := 11
		);
	port(
		RST_n  	: in std_logic; 
		CLK  	: in std_logic; 
		DIN  	: in signed(Nb-1 downto 0);
		Vin		: in std_logic;
		Dout 	: out signed(Nb-1 downto 0); 
		Vout	: out std_logic;
		b0		: in signed(Nb-1 downto 0);
		b1		: in signed(Nb-1 downto 0);
		b2		: in signed(Nb-1 downto 0);
		b3		: in signed(Nb-1 downto 0);
		b4		: in signed(Nb-1 downto 0);
		b5		: in signed(Nb-1 downto 0);
		b6		: in signed(Nb-1 downto 0);
		b7		: in signed(Nb-1 downto 0);
		b8		: in signed(Nb-1 downto 0);
		b9		: in signed(Nb-1 downto 0);
		b10		: in signed(Nb-1 downto 0)
		);
end myfir;

architecture beh of myfir is 

signal sum_final, max_value, sum_saturated : signed(Nb-1 downto 0);
type internal_array is array (integer range 0 to NT - 1) of signed(Nb-2 downto 0);
signal regs_data : internal_array;
signal b : internal_array;
type mult_internal_array is array (integer range 0 to NT - 1) of signed(2*Nb-3 downto 0);
signal mult: mult_internal_array;
type sum_internal_array is array (integer range 0 to NT-1) of signed (11 downto 0); -- min length necessary
signal sum : sum_internal_array;
signal mult_short : sum_internal_array;
signal xor_of : std_logic_vector(3 downto 0);
signal overflow_p, Vout1 : std_logic;
signal sum_sh: signed (nb-1 downto 0);


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

component  mux2to1 is 
	Generic(N: integer:= 9);
	Port(	A:	In	signed(N-1 downto 0) ;
			B:	In	signed(N-1 downto 0);
			S:	In	std_logic;
			Y:	Out	signed(N-1 downto 0));
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

begin

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

-- inout samples are truncated and passed through registers
input_reg: reg port map (Rst => rst_n, clk => clk, enable => Vin, Din => Din(Nb-1 downto 1), Dout => regs_data(0));

-- index 0 computations 
mult(0) <= regs_data(0)*b(0);
mult_short(0)(Nb-1 downto 0) <= mult(0)(2*Nb-3 downto Nb-2);
mult_short(0)(9) <= mult(0)(2*Nb-3);
mult_short(0)(10) <= mult(0)(2*Nb-3);
mult_short(0)(11) <= mult(0)(2*Nb-3);

sum(0) <= mult_short(0);

out_computation: for i in 1 to NT-1 generate
	-- regs
	x_registers: reg port map(Rst => rst_n, clk => clk, enable => Vout1, Din => regs_data(i-1), Dout => regs_data(i)); -- enable vin

	-- mults
	mult(i) <= regs_data(i)*b(i);

	-- shifts						
	mult_short(i)(Nb-1 downto 0) <= mult(i)(2*Nb-3 downto Nb-2);
	mult_short(i)(9) <= mult(i)(15);
	mult_short(i)(10) <= mult(i)(15);
	mult_short(i)(11) <= mult(i)(15);
	sum(i) <= sum(i-1) + mult_short(i);  
end generate;

-- overflow: saturation

couple_check: for i in 0 to 3 generate
	xor_of(i) <= sum(Nt-1)(7+i) xor sum(Nt-1)(8+i);
	end generate;
overflow_p <= xor_of(0) or xor_of(1) or xor_of(2) or xor_of(3); -- 1 if overflow


-- saturated value: 0111...1 if positive. If negative, complemented => 1000...0
max_value <= "011111111";
saturation_xor	:	for i in 0 to Nb-1 generate
						sum_saturated(i) <= max_value(i) xor sum(Nt-1)(11);
					end generate;

-- sum short (direct result) if overflow = 0 ; no overflow
-- saturated value if overflow
sum_sh <= sum(Nt-1)(Nb-2 downto 0) & '0';
saturation_mux:  mux2to1	port map (A => sum_sh, B => sum_saturated, S => overflow_p, Y => sum_final);

output_reg: reg 	generic map (data_size => Nb)
					port map (Rst => rst_n, clk => clk, enable => '1', Din => sum_final, Dout => Dout);
						
vin_vout_first : FF port map (Rst => rst_n, clk => clk, enable => '1', Din => Vin, Dout => Vout1);
vin_vout_second: FF port map (Rst => rst_n, clk => clk, enable => '1', Din => Vout1, Dout => Vout);
						
end architecture; 


