library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gpu_pkg.all;

entity wrapper is
	generic (
		SCREEN_WIDTH  : integer := 640;
		SCREEN_HEIGHT : integer := 480
		);
	port (
		clk_i : std_logic;
		rst_i : std_logic;

		axis_mosi_i : in  global_axis_mosi_type;
		axis_miso_o : out global_axis_miso_type;

		axis_mosi_o : out global_axis_mosi_type;
		axis_miso_i : in  global_axis_miso_type
		);
end entity wrapper;

architecture behavioral of wrapper is

	--COMPONENTS--------------------------------------------------------------------------

	component vertex_transform_axis_type_wrapper is
		generic (
			SCREEN_WIDTH  : integer;
			SCREEN_HEIGHT : integer
		);
		port (
			clk_i       : in  std_logic;
			rst_i       : in  std_logic;
			axis_mosi_i : in  global_axis_mosi_type;
			axis_miso_o : out global_axis_miso_type;
			axis_mosi_o : out global_axis_mosi_type;
			axis_miso_i : in  global_axis_miso_type
		);
	end component vertex_transform_axis_type_wrapper;		

	component axis_in is
		port (
			clk     : in  std_logic;
			rst     : in  std_logic;
			s_i     : in  global_axis_mosi_type;
			s_o     : out RV;
			ready_o : out std_logic
		);
	end component axis_in;

	component fragment_ops_axis is
		generic (
			SCREEN_WIDTH  : integer;
			SCREEN_HEIGHT : integer
		);
		port (
			clk_i          : in  std_logic;
			rst_i          : in  std_logic;
			axistready_out : in  global_axis_miso_type;
			axistire_out   : out global_axis_mosi_type;
			axistready_in  : out global_axis_miso_type;
			axistire_in    : in  global_axis_mosi_type
		);
	end component fragment_ops_axis;

	--SIGNALS--------------------------------------------------------------------------

	signal vt2rasterizer : global_axis_mosi_type;
	signal rasterizer2vt : global_axis_miso_type;

	signal rasterizer2fo : global_axis_mosi_type;
	signal fo2rasterizer : global_axis_miso_type;			

begin

	vertex_transform_axis_type_wrapper_1 : vertex_transform_axis_type_wrapper
		generic map (
			SCREEN_WIDTH  => SCREEN_WIDTH,
			SCREEN_HEIGHT => SCREEN_HEIGHT
		)
		port map (
			clk_i       => clk_i,
			rst_i       => rst_i,
			axis_mosi_i => axis_mosi_i,
			axis_miso_o => axis_miso_o,
			axis_mosi_o => vt2rasterizer,
			axis_miso_i => rasterizer2vt
		);	

	axis_in_1 : axis_in
		port map (
			clk     => clk_i,
			rst     => rst_i,
			s_i     => vt2rasterizer,
			ready_o => rasterizer2vt.axis_tready,
			s_o     => open

			--rasterizer2fo
			--fo2rasterizer
		);

	fragment_ops_axis_1 : fragment_ops_axis
		generic map (
			SCREEN_WIDTH  => SCREEN_WIDTH,
			SCREEN_HEIGHT => SCREEN_HEIGHT
		)
		port map (
			clk_i          => clk_i,
			rst_i          => rst_i,
			axistready_out => fo2rasterizer,
			axistire_out   => rasterizer2fo,
			axistready_in  => axis_miso_i,
			axistire_in    => axis_mosi_o
		);		
	
end architecture behavioral;