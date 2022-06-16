--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : frame_buffer_axis_type_wrapper_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu Jun 16 21:06:47 2022
-- Last update : Thu Jun 16 21:30:30 2022
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
use std.textio.all;
use ieee.std_logic_textio.all;

library work;
use work.gpu_pkg.all;

-----------------------------------------------------------

entity frame_buffer_axis_type_wrapper_tb is

end entity frame_buffer_axis_type_wrapper_tb;

-----------------------------------------------------------

architecture testbench of frame_buffer_axis_type_wrapper_tb is

	-- Testbench DUT generics
	constant SCREEN_WIDTH  : integer := 10;
	constant SCREEN_HEIGHT : integer := 10;

	-- Testbench DUT ports
	signal clk_i       : std_logic;
	signal rst_i       : std_logic;
	signal axis_mosi_i : global_axis_mosi_type;
	signal axis_miso_o : global_axis_miso_type;
	signal xVGA_i      : integer;
	signal yVGA_i      : integer;
	signal colorVGA_o  : vec32;	

	-- Other constants
	constant C_CLK_PERIOD : time := 10 ns; -- NS

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	CLK_GEN : process
	begin
		clk_i <= '1';
		wait for C_CLK_PERIOD / 2;
		clk_i <= '0';
		wait for C_CLK_PERIOD / 2;
	end process CLK_GEN;

	RESET_GEN : process
	begin
        report "Start!";
		xVGA_i <= 0;
		yVGA_i <= 0;
		axis_mosi_i.axis_tvalid <= '0';
		axis_mosi_i.axis_tdata <= (others => '0');
		rst_i <= '1';
		wait for 20*C_CLK_PERIOD;

		rst_i <= '0';
		load_y_loop : for i in 0 to SCREEN_HEIGHT - 1 loop
			load_x_loop : for j in 0 to SCREEN_WIDTH - 1 loop
				axis_mosi_i.axis_tdata <= std_logic_vector(to_unsigned(i, 16)) & std_logic_vector(to_unsigned(j, 16));
				axis_mosi_i.axis_tvalid <= '1';
				wait for C_CLK_PERIOD * 2;
			end loop;
		end loop;
		axis_mosi_i.axis_tvalid <= '0';

		check_y_loop: for i in 0 to SCREEN_HEIGHT - 1 loop
			check_x_loop: for j in 0 to SCREEN_WIDTH - 1 loop
				yVGA_i <= i;
				xVGA_i <= j;
				wait for C_CLK_PERIOD*2;

				assert colorVGA_o = std_logic_vector(to_unsigned(i, 16)) & std_logic_vector(to_unsigned(j, 16)) 
				report "FAILURE: x = " & integer'image(j) & 
						", y = " & integer'image(i) & 
						", expected color = " & to_hstring(std_logic_vector(to_unsigned(i, 16)) & std_logic_vector(to_unsigned(j, 16))) &
						", received color = " & to_hstring(colorVGA_o)
				severity failure;
			end loop;
		end loop;

        report "Finished!";
		wait;
	end process RESET_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT: entity work.frame_buffer_axis_type_wrapper
		generic map (
			SCREEN_WIDTH  => SCREEN_WIDTH,
			SCREEN_HEIGHT => SCREEN_HEIGHT
		)
		port map (
			clk_i       => clk_i,
			rst_i       => rst_i,
			axis_mosi_i => axis_mosi_i,
			axis_miso_o => axis_miso_o,
			xVGA_i      => xVGA_i,
			yVGA_i      => yVGA_i,
			colorVGA_o  => colorVGA_o
		);	

end architecture testbench;