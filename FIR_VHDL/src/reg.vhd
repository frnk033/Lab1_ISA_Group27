library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is 
	generic(
		data_size 	: integer := 8
		);
	port(
		Rst  		: in std_logic; 
		clk  		: in std_logic; 
		enable	: in std_logic;
		Din  		: in signed(data_size-1 downto 0);
		Dout 		: out signed(data_size-1 downto 0) 
		);
end reg;

architecture beh of reg is 
begin

reg_P: process (Clk, Rst)
begin  -- process IR_P
	if Rst = '0' then                   -- asynchronous reset (active low)
		Dout <= (others => '0');
	elsif Clk'event and Clk = '1' then  -- rising clock edge
		if (enable = '1') then
			Dout <= Din  ;--after 0.01 ns;
		end if;
	end if;
end process reg_P;

end architecture; 
