--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : VGA_adapter_640_480_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jun 13 19:04:33 2022
-- Last update : Mon Jun 13 19:44:51 2022
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

-----------------------------------------------------------

entity VGA_adapter_640_480_tb is

end entity VGA_adapter_640_480_tb;

-----------------------------------------------------------

architecture testbench of VGA_adapter_640_480_tb is

    -- Testbench DUT generics
    constant hTpw : integer := 96; --clocks
    constant hTbp : integer := 48;
    constant hTdisp : integer := 640;
    constant hTfp : integer := 16;

    constant vTpw : integer := 2; --lines
    constant vTbp : integer := 29;
    constant vTdisp : integer := 480;
    constant vTfp : integer := 10;

    -- Testbench DUT ports
    signal rst_i      : STD_LOGIC;
    signal clk100_i   : STD_LOGIC;
    signal red_o      : STD_LOGIC_vector (2 downto 0);
    signal green_o    : STD_LOGIC_vector (2 downto 0);
    signal blue_o     : STD_LOGIC_vector (1 downto 0);
    signal vSync_o    : STD_LOGIC;
    signal hSync_o    : STD_LOGIC;
    signal xVGA_o     : integer;
    signal yVGA_o     : integer;
    signal colorVGA_i : std_logic_vector (7 downto 0);

    -- Other constants
    constant C_CLK_PERIOD : time := 10 ns; -- NS

begin
    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        clk100_i <= '1';
        wait for C_CLK_PERIOD / 2;
        clk100_i <= '0';
        wait for C_CLK_PERIOD / 2;
    end process CLK_GEN;

    RESET_GEN : process
    begin
        rst_i <= '1';
        wait for 20.0*C_CLK_PERIOD;

        rst_i <= '0';
        colorVGA_i <= std_logic_vector(to_unsigned(yVGA_o + 1, colorVGA_i'length));
        
        v_check : for i in 1 to 521 loop
            h_check: for j in 1 to 800 loop
                wait for C_CLK_PERIOD*4; --25 MHz

                case j is
                when hTpw =>
                    assert hSync_o = '1' report "hSync_o /= 1" severity failure;
                
                when hTpw + hTbp + hTdisp + hTfp => 
                    assert hSync_o = '0' report "hSync_o /= 0" severity failure;
                
                when others =>
                    next;
                end case;
            end loop;

            case i is
            when vTpw =>
                assert vSync_o = '1' report "vSync_o /= 1" severity failure;
            
            when vTpw + vTbp + vTdisp + vTfp => 
                assert vSync_o = '0' report "vSync_o /= 0" severity failure;
            
            when others =>
                next;
            end case;
        end loop v_check;

        wait;
    end process RESET_GEN;

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : entity work.VGA_adapter_640_480
        port map (
            rst_i      => rst_i,
            clk100_i   => clk100_i,
            red_o      => red_o,
            green_o    => green_o,
            blue_o     => blue_o,
            vSync_o    => vSync_o,
            hSync_o    => hSync_o,
            xVGA_o     => xVGA_o,
            yVGA_o     => yVGA_o,
            colorVGA_i => colorVGA_i
        );

end architecture testbench;