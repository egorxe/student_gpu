library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gpu_pkg.all;

entity frame_buffer_axis_type_wrapper is
	generic (
			SCREEN_WIDTH  : integer := 640;
			SCREEN_HEIGHT : integer := 480
		);
	port (
			clk_i : in std_logic;
			rst_i : in std_logic;

			axis_mosi_i : in global_axis_mosi_type;
			axis_miso_o : out global_axis_miso_type;

			xVGA_i        : in  integer;
			yVGA_i        : in  integer;
			colorVGA_o    : out vec32
		);
end entity frame_buffer_axis_type_wrapper;

architecture arch of frame_buffer_axis_type_wrapper is
	component frame_buffer_axis_wrapper is
		generic (
			SCREEN_WIDTH  : integer := 640;
			SCREEN_HEIGHT : integer := 480
		);
		port (
			clk_i         : in  std_logic;
			rst_i         : in  std_logic;
			s_axis_tdata  : in  std_logic_vector(GLOBAL_AXIS_DATA_WIDTH - 1 downto 0);
			s_axis_tkeep  : in  std_logic_vector(3 downto 0);
			s_axis_tvalid : in  std_logic;
			s_axis_tlast  : in  std_logic;
			s_axis_tid    : in  std_logic_vector(3 downto 0);
			s_axis_tdest  : in  std_logic_vector(3 downto 0);
			s_axis_tuser  : in  std_logic_vector(3 downto 0);
			s_axis_tready : out std_logic;
			xVGA_i        : in  integer;
			yVGA_i        : in  integer;
			colorVGA_o    : out vec32
		);
	end component frame_buffer_axis_wrapper;	

begin

	frame_buffer_axis_wrapper_1 : frame_buffer_axis_wrapper
		generic map (
			SCREEN_WIDTH  => SCREEN_WIDTH,
			SCREEN_HEIGHT => SCREEN_HEIGHT
		)
		port map (
			clk_i         => clk_i,
			rst_i         => rst_i,

			s_axis_tdata  => axis_mosi_i.axis_tdata,
			s_axis_tkeep  => axis_mosi_i.axis_tkeep,
			s_axis_tvalid => axis_mosi_i.axis_tvalid,
			s_axis_tlast  => axis_mosi_i.axis_tlast,
			s_axis_tid    => axis_mosi_i.axis_tid,
			s_axis_tdest  => axis_mosi_i.axis_tdest,
			s_axis_tuser  => axis_mosi_i.axis_tuser,

			s_axis_tready => axis_miso_o.axis_tready,

			xVGA_i        => xVGA_i,
			yVGA_i        => yVGA_i,
			colorVGA_o    => colorVGA_o
		);	
	
end architecture arch;