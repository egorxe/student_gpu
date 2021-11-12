-- Demo stage which shows a way to work with in & out FIFOs (testbench part)

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.float_pkg.all;
    
use work.gpu_pkg.all;
use work.file_helper_pkg.all;

entity test_vertices_fifotb is
    generic (
        SCREEN_WIDTH    : integer   := 640;
        SCREEN_HEIGHT   : integer   := 480;
        IN_FIFO_NAME    : string := "in.fifo";
        OUT_FIFO_NAME   : string := "out.fifo"
    );
end test_vertices_fifotb;

architecture fileio of test_vertices_fifotb is

component test_vertices is
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
        stb_o       : out std_logic
    );
end component;

constant CLK_PERIOD : time := 10 ns;

signal data_in  : vec32 := (others => '0');    -- not used
signal data_out : vec32;

signal stb_out  : std_logic;

signal clk      : std_logic := '0';
signal rst      : std_logic := '1';

begin

clk <= not clk after CLK_PERIOD/2;
rst <= '0' after CLK_PERIOD*10;

tv : test_vertices
    generic map (
        SCREEN_WIDTH => SCREEN_WIDTH,
        SCREEN_HEIGHT => SCREEN_HEIGHT
    )
    port map (
        clk_i       => clk,
        rst_i       => rst,
        
        data_i      => data_in,
        stb_i       => '0',
        
        data_o      => data_out,
        stb_o       => stb_out
    );
    

-- Send vertices produced by test_vertices indefinetely
process(clk)
    variable fstatus    : file_open_status := STATUS_ERROR;
    file f_out          : BinaryFile;
begin
    if Rising_edge(clk) then
        if rst = '1' then
            if fstatus = STATUS_ERROR then
                -- open output file once
                file_open(fstatus, f_out, OUT_FIFO_NAME, WRITE_MODE);
            end if;
        else
            if (stb_out = '1') then
                WriteUint32(f_out, data_out);
            end if;
        end if;
    end if;
end process;

end fileio;
