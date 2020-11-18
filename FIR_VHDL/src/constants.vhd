LIBRARY ieee; 
USE ieee.std_logic_1164.all;

package constants is 

constant N     : integer := 10;   -- filter order 
constant nb    : integer := 9;    -- number of bits of the samples
constant mul_w : integer := 18;   -- number of bits after multiplication
constant add_w : integer := 13;   -- number of bits needed for additions

end constants; 
