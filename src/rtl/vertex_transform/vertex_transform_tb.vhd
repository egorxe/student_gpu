--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : vertex_transform_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 17 19:06:31 2021
-- Last update : Wed Dec  1 12:51:38 2021
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library work;
use work.gpu_pkg.all;
use work.file_helper_pkg.all;

-----------------------------------------------------------

entity vertex_transform_tb is
	generic (
		SCREEN_WIDTH  : integer := 640;
		SCREEN_HEIGHT : integer := 480;
		IN_FIFO_NAME  : string  := "in.fifo";
		OUT_FIFO_NAME : string  := "out.fifo"
	);
end entity vertex_transform_tb;

-----------------------------------------------------------

architecture testbench of vertex_transform_tb is

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
	signal clk_i   : std_logic := '0';
	signal rst_i   : std_logic := '1';
	signal data_i  : vec32     := (others => '0');
	signal read_o  : std_logic;
	signal data_o  : vec32;
	signal write_o : std_logic;
	signal s_i     : integer := 0;

	-- Other constants
	constant CLK_PERIOD : time := 10 ns;

begin

	-- Common clk and rst definition
	clk_i <= not clk_i after CLK_PERIOD/2;
	rst_i <= '0' after CLK_PERIOD*10;

	-- Reading/writing from/to fifo files
	process(clk_i)
		file f_out, f_in               : BinaryFile;
		variable fInStatus, fOutStatus : file_open_status := STATUS_ERROR;
		variable v_data_i              : vec32 := (others => '0');
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				-- open output and input files once
				if fInStatus = STATUS_ERROR then
					file_open(fInStatus, f_in, IN_FIFO_NAME, READ_MODE);
				end if;

				if fOutStatus = STATUS_ERROR then
					file_open(fOutStatus, f_out, OUT_FIFO_NAME, WRITE_MODE);
				end if;

			else
				-- writing
				if (write_o = '1') then
					WriteUint32(f_out, data_o);
					if (data_o = GPU_PIPE_CMD_FRAME_END) then
						flush(f_out);
					end if;
				end if;

				--reading
				if (read_o = '1') then
					ReadUint32(f_in, v_data_i);
				end if;

			end if;
		end if;

		data_i <= v_data_i;

	end process;

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