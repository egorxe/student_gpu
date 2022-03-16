library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;

use work.gpu_pkg.all;
use work.file_helper_pkg.all;


entity fragment_ops_axis is
    generic (
        SCREEN_WIDTH    : integer   := 640;
        SCREEN_HEIGHT   : integer   := 480
    );
    port (
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;
        
        axistready_in     : in global_axis_miso_type; --ready
        axistire_in       : out global_axis_mosi_type; --data
        
        axistready_out     : out global_axis_miso_type; --ready
        axistire_out       : in global_axis_mosi_type --data
    );
end fragment_ops_axis;

architecture axistire of fragment_ops_axis is

component fragment_ops is
    generic (
        SCREEN_WIDTH    : integer;
        SCREEN_HEIGHT   : integer
    );
    port (
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;
        
        data_i      : in  vec32;
        stb_i       : in  std_logic;
        
        data_o      : out vec32;
        stb_o       : out std_logic;

        ack_o       : out std_logic
    );
end component;

begin

process(clk_i)
begin
    if Rising_edge(clk_i) then
        
    end if;
end process;

end axistire;
