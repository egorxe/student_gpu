----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/30/2019 09:12:30 PM
-- Design Name: 
-- Module Name: VGA - Behavioral
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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--Library UNISIM;
--use UNISIM.vcomponents.all;

entity VGA_adapter_640_480 is
    Port ( rst_i : in STD_LOGIC;
           clk100_i : in STD_LOGIC;
           red_o : out STD_LOGIC_vector (2 downto 0);
           green_o : out STD_LOGIC_vector (2 downto 0);
           blue_o : out STD_LOGIC_vector (1 downto 0);
           vSync_o : out STD_LOGIC;
           hSync_o : out STD_LOGIC;
           xVGA_o : out integer;
           yVGA_o : out integer;
           colorVGA_i : in std_logic_vector (7 downto 0));
end VGA_adapter_640_480;

architecture Behavioral of VGA_adapter_640_480 is
    signal vCnt : integer := 0;
    signal hCnt : integer := 0;
    signal freqCnt : integer := 0;
    signal isOutputOn, clk25 : std_logic := '0';
begin
    process (clk100_i) 
    begin
        if (rising_edge(clk100_i)) then
            if (rst_i = '1') then
                freqCnt <= 0;

            else
                if (freqCnt = 1) then
                    freqCnt <= 0;
                    clk25 <= not clk25;

                else
                    freqCnt <= freqCnt + 1;
                end if;
            end if;
        end if;
    end process;

    process (clk25)
    begin
        if (rising_edge(clk25)) then
            if (rst_i = '1') then
                hCnt <= 0;
                vCnt <= 0;

            else
                if hCnt = 799 then
                    hCnt <= 0;

                    if vCnt = 520 then
                        vCnt <= 0;
                    else
                        vCnt <= vCnt + 1;
                    end if;
                    
                else
                    hCnt <= hCnt + 1;
                end if;
            end if;
        end if;
    end process;
    
    vSync_o <= '0' when vCnt < 2 else '1';
    hSync_o <= '0' when hCnt < 96 else '1';
    isOutputOn <= '1' when hCnt >= 144 and hCnt < 784 and vCnt >= 31 and vCnt < 511 else '0';
    
    red_o <= colorVGA_i(7 downto 5) when isOutputOn = '1' else (others => '0');
    green_o <= colorVGA_i(4 downto 2) when isOutputOn = '1' else (others => '0');
    blue_o <= colorVGA_i(1 downto 0) when isOutputOn = '1' else (others => '0');
    
    xVGA_o <= hCnt - 144 when hCnt >= 144 and hCnt < 784 else 0;
    yVGA_o <= vCnt - 31 when vCnt >= 31 and vCnt < 511 else 0;
end Behavioral;
