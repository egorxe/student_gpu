--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : vertex_transform_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 17 19:06:31 2021
-- Last update : Wed Dec 15 19:34:29 2021
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2021 User Company Name
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------TODO: NEED TO MAKE IT RELEVANT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library work;
use work.gpu_pkg.all;
--use work.file_helper_pkg.all;

-----------------------------------------------------------

entity vertex_transform_trivial_tb is
	generic (
	        SCREEN_WIDTH    : integer   := 640;
	        SCREEN_HEIGHT   : integer   := 480;
	        IN_FIFO_NAME    : string := "in.fifo";
	        OUT_FIFO_NAME   : string := "out.fifo"
	    );
end entity vertex_transform_trivial_tb;

-----------------------------------------------------------

architecture testbench of vertex_transform_trivial_tb is

	component vertex_transform is
		generic (
			SCREEN_WIDTH  : integer;
			SCREEN_HEIGHT : integer
		);
		port (
			clk_i   : in  std_logic;
			rst_i   : in  std_logic;
			data_i  : in  vec32;
			read_o  : out std_logic;
			data_o  : out vec32;
			write_o : out std_logic
		);
	end component;	

	-- Testbench DUT ports
	signal clk_i   : std_logic;
	signal rst_i   : std_logic;
	signal data_i  : vec32;
	signal read_o  : std_logic;
	signal data_o  : vec32;
	signal write_o : std_logic;
	signal s_i : integer := 0;

	constant DATA_AMOUNT : integer := 49;
	type memory_type is array (0 to DATA_AMOUNT - 1) of vec32;
	constant ONE32 : std_logic_vector(31 downto 0) := ("0" & "01111111" & "00000000000000000000000");
	constant TWO32 : std_logic_vector(31 downto 0) := ("0" & "10000000" & "00000000000000000000000");
	signal memory : memory_type := (
		GPU_PIPE_CMD_POLY_VERTEX,

		ONE32,
		ONE32,
		ONE32,
		TWO32,
		TWO32,
		TWO32,
		TWO32,

		ONE32,
		ONE32,
		ONE32,
		TWO32,
		TWO32,
		TWO32,
		TWO32,

		ONE32,
		ONE32,
		ONE32,
		TWO32,
		TWO32,
		TWO32,
		TWO32,

		GPU_PIPE_CMD_FRAME_END,
		GPU_PIPE_CMD_FRAME_END,
		GPU_PIPE_CMD_FRAME_END,
		GPU_PIPE_CMD_FRAME_END,
		GPU_PIPE_CMD_FRAGMENT,

		GPU_PIPE_CMD_POLY_VERTEX,

		ONE32,
		ONE32,
		ONE32,
		TWO32,
		TWO32,
		TWO32,
		TWO32,

		ONE32,
		ONE32,
		ONE32,
		TWO32,
		TWO32,
		TWO32,
		TWO32,

		ONE32,
		ONE32,
		ONE32,
		TWO32,
		TWO32,
		TWO32,
		TWO32

		);

	-- Other constants
	constant C_CLK_PERIOD : time := 10 ns;

begin
	-----------------------------------------------------------
	-- Clocks
	-----------------------------------------------------------
	CLK_GEN : process
	begin
		clk_i <= '1';
		wait for C_CLK_PERIOD / 2;
		clk_i <= '0';
		wait for C_CLK_PERIOD / 2;
	end process CLK_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	RESET_GEN : process
		--variable fstatus    : file_open_status := STATUS_ERROR;
  --  	file f_in          : BinaryFile;
	begin
		rst_i <= '1';
		wait for 20*C_CLK_PERIOD;
		rst_i <= '0';
		--file_open(fstatus, f_in, OUT_FIFO_NAME, WRITE_MODE);
		load_loop : for i in 0 to (DATA_AMOUNT - 1) loop
			wait until read_o = '1';
			data_i <= memory(i);
			s_i <= i;
			--data_i <= ReadUint32(f_in, data_out);
			wait until read_o = '0';
		end loop load_loop;
		wait;
	end process RESET_GEN;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : vertex_transform
		generic map (
			SCREEN_WIDTH  => SCREEN_WIDTH,
			SCREEN_HEIGHT => SCREEN_HEIGHT
		)
		port map (
			clk_i   => clk_i,
			rst_i   => rst_i,
			data_i  => data_i,
			read_o  => read_o,
			data_o  => data_o,
			write_o => write_o
		);

end architecture testbench;