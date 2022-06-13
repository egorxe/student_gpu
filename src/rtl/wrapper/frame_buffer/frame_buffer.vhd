library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gpu_pkg.all;

entity frame_buffer is
	generic (
			SCREEN_WIDTH  : integer := 640;
			SCREEN_HEIGHT : integer := 480
		);
	port (
			clk_i : in std_logic;
			rst_i : in std_logic;

			data_i : in vec32;
			valid_i : in std_logic;
			ready_o : out std_logic;

			xVGA_i : in integer;
			yVGA_i : in integer;
			colorVGA_o : out vec32; --will be ready for the 2nd rising edge after alternation of xVGA_i or yVGA_i

			coordsError_o : out std_logic --debug signal
		);
end entity frame_buffer;

architecture arch of frame_buffer is
	type string_buffer_type is array (SCREEN_WIDTH - 1 downto 0) of vec32;
	type frame_buffer_type is array (SCREEN_HEIGHT - 1 downto 0) of string_buffer_type;
	signal frame_buffer0, frame_buffer1 : frame_buffer_type;-- := (others => (others => (others => '0'))); 

	type module_state_type is (coords, colors);
	signal module_state : module_state_type := coords;

	signal bufferSelector : std_logic := '0';
	signal xInput, yInput, verticeCnt, xVGA_iBoxed, yVGA_iBoxed : integer := 0; 
begin

	sync : process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (rst_i = '1') then
				module_state <= coords;
				verticeCnt <= 0;
				bufferSelector <= '0';
				ready_o <= '0';

			else
				coordsError_o <= '0';
				ready_o <= '1';

				colorVGA_o <= frame_buffer0(yVGA_iBoxed)(xVGA_iBoxed) when bufferSelector /= '0' else
						 frame_buffer1(yVGA_iBoxed)(xVGA_iBoxed);

				if (valid_i = '1') then
					case (module_state) is
					when coords =>
						xInput <= to_integer(unsigned(data_i(15 downto 0)));
						yInput <= to_integer(unsigned(data_i(31 downto 16)));
						module_state <= colors;

					when colors =>
						if (yInput >= 0 and yInput <= SCREEN_HEIGHT and xInput >= 0 and xInput <= SCREEN_WIDTH) then
							case bufferSelector is
							when '0' =>
								frame_buffer0(yInput)(xInput) <= data_i;

							when others =>
								frame_buffer1(yInput)(xInput) <= data_i;
							end case;

							verticeCnt <= verticeCnt + 1;
							coordsError_o <= '0';
						
						else 
							coordsError_o <= '1';
						end if;

						if (verticeCnt = SCREEN_WIDTH*SCREEN_HEIGHT - 1) then
							bufferSelector <= not bufferSelector;
							verticeCnt <= 0;
						end if;
						module_state <= coords;
					end case;
				end if;
			end if;
		end if;
	end process;

	xVGA_iBoxed <= xVGA_i when xVGA_i >= 0 and xVGA_i < SCREEN_WIDTH else 0;
    yVGA_iBoxed <= yVGA_i when yVGA_i >= 0 and yVGA_i < SCREEN_HEIGHT else 0;
	
end architecture arch;
