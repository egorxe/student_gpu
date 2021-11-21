----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/10/2021 06:57:45 PM
-- Design Name: 
-- Module Name: rasterisator_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use IEEE.std_logic_textio.all;
use IEEE.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use ieee.float_pkg.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rasterisator_tb is
end rasterisator_tb;   

architecture Behavioral of rasterisator_tb is

component edge_function is

    Generic (
        constant max_width : float32 := to_float(1080.0);
        constant max_heigh : float32 := to_float(920.0)
    );
    Port (  clk : in std_logic;
            rst : in std_logic
        );
        
end component;

signal clk_tb : std_logic := '0';
signal rst_tb : std_logic := '0';

begin
 

    map_edge_function : edge_function
        generic map (
            max_width => to_float(640),
            max_heigh => to_float(480)
        )
        port map (
            clk => clk_tb,
            rst => rst_tb
        );

    
        clk_tb <= not clk_tb after 5 ns;
        



end Behavioral;





















