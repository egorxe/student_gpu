library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gpu_pkg.all;

entity frame_buffer_axis_wrapper is
	generic (
		SCREEN_WIDTH  : integer := 640;
		SCREEN_HEIGHT : integer := 480
		);
	port(
		clk_i : in std_logic;
		rst_i : in std_logic;

		s_axis_tdata         : in  std_logic_vector(GLOBAL_AXIS_DATA_WIDTH - 1 downto 0);
        s_axis_tkeep         : in  std_logic_vector(3 downto 0); 	--not used
        s_axis_tvalid        : in  std_logic;
        s_axis_tlast         : in  std_logic;						--not used
        s_axis_tid           : in  std_logic_vector(3 downto 0);	--not used
        s_axis_tdest         : in  std_logic_vector(3 downto 0);	--not used
        s_axis_tuser         : in  std_logic_vector(3 downto 0);	
        s_axis_tready        : out std_logic;

        xVGA_i : in integer;
        yVGA_i : in integer;
		colorVGA_o : out vec32 --will be ready for the 2nd rising edge after alternation of xVGA_i or yVGA_i
        );
end entity frame_buffer_axis_wrapper;

architecture arch of frame_buffer_axis_wrapper is
	component frame_buffer is
		generic (
			SCREEN_WIDTH  : integer := 640;
			SCREEN_HEIGHT : integer := 480
		);
		port (
			clk_i         : in  std_logic;
			rst_i         : in  std_logic;
			data_i        : in  vec32;
			valid_i       : in  std_logic;
			ready_o       : out std_logic;
			xVGA_i        : in  integer;
			yVGA_i        : in  integer;
			colorVGA_o    : out vec32;
			coordsError_o : out std_logic
		);
	end component frame_buffer;	

begin

	frame_buffer_1 : frame_buffer
		generic map (
			SCREEN_WIDTH  => SCREEN_WIDTH,
			SCREEN_HEIGHT => SCREEN_HEIGHT
		)
		port map (
			clk_i         => clk_i,
			rst_i         => rst_i,
			data_i        => s_axis_tdata,
			valid_i       => s_axis_tvalid,
			ready_o       => s_axis_tready,
			xVGA_i        => xVGA_i,
			yVGA_i        => yVGA_i,
			colorVGA_o    => colorVGA_o,
			coordsError_o => open
		);	
	
end architecture arch;