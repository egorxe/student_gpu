--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : edge_function_dummy_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Apr  6 20:07:33 2022
-- Last update : Wed Apr  6 20:42:12 2022
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2022 User Company Name
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

library work;
use work.gpu_pkg.all;
-----------------------------------------------------------

entity edge_function_dummy_tb is

end entity edge_function_dummy_tb;

-----------------------------------------------------------

architecture testbench of edge_function_dummy_tb is

	-- Testbench DUT generics


	-- Testbench DUT ports
	signal clk_i          : std_logic;
	signal rst_i          : std_logic;
	signal valid_i        : std_logic;
	signal input_ready_o  : std_logic;
	signal result_ready_o : std_logic;
	signal x_i            : vec32;
	signal y_i            : vec32;
	signal v0x_i          : vec32;
	signal v0y_i          : vec32;
	signal v1x_i          : vec32;
	signal v1y_i          : vec32;
	signal result_o       : vec32;

	-- Other constants
	constant clk_period : time := 10 ns;
	constant reset_delay : time := 20 ns;

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	CLK_GEN : process
	begin
		clk_i <= '1';
		wait for clk_period / 2;
		clk_i <= '0';
		wait for clk_period / 2;
	end process CLK_GEN;

	RESET_GEN : process
	begin
		rst_i <= '1',
		         '0' after reset_delay;
		wait;
	end process RESET_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	-- E_01(P) = (P.x − V0.x)∗(V1.y − V0.y) − (P.y − V0.y)∗(V1.x − V0.x)

	stim_proc: process
	begin
		valid_i <= '0';
		x_i <= ZERO32;
		y_i <= ZERO32;
		v0x_i <= ZERO32;
		v0y_i <= ZERO32;
		v1x_i <= ZERO32;
		v1y_i <= ZERO32;

		wait for reset_delay;

		valid_i <= '1'; --(2 - 1)*(2 - 1) - (1 - 1)*(1 - 1)
		x_i <= TWO32;
		y_i <= ONE32;
		v0x_i <= ONE32;
		v0y_i <= ONE32;
		v1x_i <= ONE32;
		v1y_i <= TWO32;
		
		wait for clk_period;

		valid_i <= '0';
		wait until result_ready_o;

		assert result_o = ONE32 report "FAILURE" severity failure;

		assert false report "SUCCESS" severity failure;
		wait;
	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : entity work.edge_function
		port map (
			clk_i          => clk_i,
			rst_i          => rst_i,
			valid_i        => valid_i,
			input_ready_o  => input_ready_o,
			result_ready_o => result_ready_o,
			x_i            => x_i,
			y_i            => y_i,
			v0x_i          => v0x_i,
			v0y_i          => v0y_i,
			v1x_i          => v1x_i,
			v1y_i          => v1y_i,
			result_o       => result_o
		);

end architecture testbench;