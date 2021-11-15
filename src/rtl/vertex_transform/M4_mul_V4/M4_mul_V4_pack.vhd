library ieee;
use ieee.std_logic_1164.all;

package M4_mul_V4_pack is
	constant DATA_WIDTH : integer := 32;
	type V4 is array (0 to 3) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	type M44 is array (0 to 3) of V4;
	type V2 is array (0 to 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	type M42 is array (0 to 3) of V2;
end package M4_mul_V4_pack;

package body M4_mul_V4_pack is
end package body M4_mul_V4_pack;