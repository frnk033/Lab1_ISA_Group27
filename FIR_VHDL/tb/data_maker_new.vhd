library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity data_maker is  
  port (
    CLK     : in  std_logic;
    RST_n   : in  std_logic;
    VOUT    : out std_logic;
    DOUT    : out signed(8 downto 0);
    b0      : out signed(8 downto 0);
    b1      : out signed(8 downto 0);
    b2      : out signed(8 downto 0);
    b3      : out signed(8 downto 0);
    b4      : out signed(8 downto 0);
    b5      : out signed(8 downto 0);
    b6      : out signed(8 downto 0);
    b7      : out signed(8 downto 0);
    b8      : out signed(8 downto 0);
    b9      : out signed(8 downto 0);
    b10      : out signed(8 downto 0);
    END_SIM : out std_logic);
end data_maker;

architecture beh of data_maker is

  constant tco : time := 1 ns;
  constant Ts : time := 10 ns;

  signal sEndSim : std_logic;
  signal END_SIM_i : std_logic_vector(0 to 10);  
  signal cnt: integer;

begin  -- beh
  
   
  b0 <= to_signed(-1,b0'length);
  b1 <= to_signed(-4,b1'length);
  b2 <= to_signed(-7,b2'length);
  b3 <= to_signed(16,b3'length);  
  b4 <= to_signed(70,b4'length);  
  b5 <= to_signed(101,b5'length);  
  b6 <= to_signed(70,b6'length);  
  b7 <= to_signed(16,b7'length);  
  b8 <= to_signed(-7,b8'length);  
  b9 <= to_signed(-4,b9'length);  
  b10 <= to_signed(-1,b10'length);  


  process (CLK, RST_n, cnt)
    file fp_in : text open READ_MODE is "samples.txt";
    variable line_in : line;
    variable x : integer;
  begin  -- process
    if RST_n = '0' then                 -- asynchronous reset (active low)
      DOUT <= (others => '0') after tco;      
      VOUT <= '0' after tco;
      sEndSim <= '0' after tco;
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      if (cnt /= 4 ) then               -- this counter variable is used as factor to decide if DIN should be sampled or not
		if  (not endfile(fp_in))  then
        	readline(fp_in, line_in);
        	read(line_in, x);
        	DOUT <= to_signed(x, DOUT'length) after tco;
        	VOUT <= '1' after tco;
        	sEndSim <= '0' after tco;
      	else
        	VOUT <= '0' after tco;        
        	sEndSim <= '1' after tco;
	  	end if;
	  else
		Vout <= '0' after tco; 
		DOUT <= "UUUUUUUUU";
      end if;
    end if;
  end process;

-- counter
 process (CLK, RST_n)
 begin 
 	if Rst_n = '0' then
		cnt <= 0; 
	else 
		cnt <= cnt +1; 
		if cnt = 4 then 
			cnt <= 0;  
		end if;
	end if;
 end process;


  process (CLK, RST_n)
  begin  -- process
    if RST_n = '0' then                 -- asynchronous reset (active low)
      END_SIM_i <= (others => '0') after tco;
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      END_SIM_i(0) <= sEndSim after tco;
      END_SIM_i(1 to 10) <= END_SIM_i(0 to 9) after tco;
    end if;
  end process;

  END_SIM <= END_SIM_i(10);  
 
end beh;
