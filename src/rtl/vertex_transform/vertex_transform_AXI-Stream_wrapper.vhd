library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gpu_pkg.all;

entity vertex_transform_AXIS_wrapper is
	generic (
		SCREEN_WIDTH  : integer := 640;
		SCREEN_HEIGHT : integer := 480
	);
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;

		s_axis_i: in global_axis_mosi_type;
		s_axis_ready_o : out global_axis_miso_type;

		m_axis_o: out global_axis_mosi_type;
		m_axis_ready_i: in global_axis_miso_type
	);
end vertex_transform_AXIS_wrapper;

architecture vertex_transform_AXIS_wrapper_arc of vertex_transform_AXIS_wrapper is

	component vertex_transform is
		generic (
			SCREEN_WIDTH : integer;
			SCREEN_HEIGHT : integer
		);
		port (
			clk_i   : in  std_logic;
			rst_i   : in  std_logic;

			data_i  : in  vec32;
			valid_i : in  std_logic;
			ready_o : out std_logic;

			data_o  : out vec32;
			valid_o : out std_logic;
			last_o : out std_logic;
			ready_i : in  std_logic
		);
	end component vertex_transform;		

	--type reg_type is record
	--	s_data : vec32;
	--	s_axis_ready : global_axis_miso_type;
	--	vt_ready : std_logic;

	--	m_axis : global_axis_mosi_type;
	--	vt_valid : std_logic;
	--end record;

	--constant rst_reg : reg_type := (s_data => (others => '0'),
	--								s_axis_ready => ('1'),
	--								vt_ready => '1', 

	--								m_axis => (	axis_tdata            => (others => '0'),
 --       										axis_tkeep            => (others => '1'),
 --       										axis_tvalid           => '0',
	--										    axis_tlast            => '0',
	--										    axis_tid              => (others => '0'),
	--										    axis_tdest            => (others => '0'),
	--										    axis_tuser            => (others => '0') 
	--										    ),
	--								vt_valid => '0'
	--								);
	--signal reg, reg_in : reg_type := rst_reg;

	--signal vt_valid_i : std_logic;
	--signal vt_ready_o : std_logic;
	--signal vt_data_o  : vec32;
	--signal vt_valid_o : std_logic;
	--signal vt_last_o : std_logic;
	--signal vt_ready_i : std_logic;	

begin

	--unused in slave: tkeep, tlast, tid, tdest, tuser
	m_axis_o.tkeep <= (others => '1');
	m_axis_o.tid <= (others => '0');
	m_axis_o.tdest <= (others => '0');
	m_axis_o.tuser <= (others => '0');

	vertex_transform_unit : vertex_transform
		generic map (
			SCREEN_WIDTH  => SCREEN_WIDTH,
			SCREEN_HEIGHT => SCREEN_HEIGHT
		)
		port map (
			clk_i   => clk_i,
			rst_i   => rst_i,
			data_i  => s_axis_i.axis_tdata,
			valid_i => s_axis_i.axis_tvalid,
			ready_o => s_axis_ready_o.axis_tready,
			data_o  => m_axis_o.axis_tdata,
			valid_o => m_axis_o.axis_tvalid,
			last_o  => m_axis_o.axis_tlast,
			ready_i => m_axis_ready_i.axis_tready
		);	

	--s_axis_ready_o <= reg_in.s_axis_ready;
	--m_axis_o <= reg_in.m_axis;

	--sync : process (clk_i)
	--begin
	--	if (rising_edge(clk_i)) then
	--		if (rst_i = '1') then
	--			reg <= rst_reg;
	--		else
	--			reg <= reg_in;
	--		end if;
	--	end if;
	--end process;

	--async : process (reg, s_axis_i, m_axis_ready_i, vt_ready_o, vt_valid_o, vt_last_o, vt_data_o)
	--	variable var : reg_type := rst_reg;

	--begin
	--	var := reg;

	--	--reception
	--	if (reg.s_axis_ready.axis_tready = '1' and s_axis_i.axis_tvalid = '1') then
	--		var.s_data := s_axis_i.axis_tdata;
	--		var.s_axis_ready.axis_tready := '0';
	--		var.vt_valid := '1';

	--	elsif (reg.s_axis_ready.axis_tready = '0' and vt_ready_o = '1') then
	--		var.s_axis_ready.axis_tready := '1';
	--		var.vt_valid := '0';
	--	end if;

	--	--transmission
	--	if (reg.m_axis.tvalid = '0' and vt_valid_o = '1') then
	--		var.m_axis.axis_tdata := vt_data_o;
	--		var.m_axis.axis_tvalid := '1';
	--		var.vt_ready := '0';

	--		if (vt_last_o = '1') then
	--			var.m_axis.axis_tlast := '1';
	--		end if;

	--	elsif (reg.m_axis.tvalid = '1' and m_axis_ready_i.axis_tready = '1') then
	--		var.m_axis.axis_tvalid := '0';
	--		var.m_axis.axis_tlast := '0';
	--		var.vt_ready := '1';
	--	end if;

	--	reg_in := var;
	--end process;

	--vertex_transform_unit : vertex_transform
	--	generic map (
	--		SCREEN_WIDTH  => SCREEN_WIDTH,
	--		SCREEN_HEIGHT => SCREEN_HEIGHT
	--	)
	--	port map (
	--		clk_i   => clk_i,
	--		rst_i   => rst_i,
	--		data_i  => reg_in.s_data,
	--		valid_i => reg_in.vt_valid,
	--		ready_o => vt_ready_o,
	--		data_o  => vt_data_o,
	--		valid_o => vt_valid_o,
	--		last_o => vt_last_o,
	--		ready_i => vt_ready_i
	--	);	

end vertex_transform_AXIS_wrapper_arc;