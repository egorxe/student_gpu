-- Demo stage which shows a way to work with in & out FIFOs (testbench part)

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.float_pkg.all;
    use std.textio.all;
    use ieee.std_logic_textio.all;
    
use work.gpu_pkg.all;
use work.file_helper_pkg.all;

entity fragment_ops_tb is
    generic (
        SCREEN_WIDTH    : integer   := 640;
        SCREEN_HEIGHT   : integer   := 480;
        IN_FIFO_NAME    : string := "in.fifo";
        OUT_FIFO_NAME   : string := "out.fifo"
    );
end fragment_ops_tb;

architecture fileio of fragment_ops_tb is

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
        ack_o       : out std_logic;
        
        data_o      : out vec32;
        stb_o       : out std_logic;
        ack_i       : in  std_logic

    );
end component;

constant CLK_PERIOD : time := 10 ns;

signal data_in  : vec32;    
signal data_out : vec32;

signal stb_out  : std_logic;
signal stb_in   : std_logic := '1';
signal ack_out  : std_logic;
signal ack_in   : std_logic := '1';

signal clk      : std_logic := '0';
signal rst      : std_logic := '1';
-- signal ack_in   : std_logic := '1';
begin

clk <= not clk after CLK_PERIOD/2;
rst <= '0' after CLK_PERIOD*10;

tv : fragment_ops
    generic map (
        SCREEN_WIDTH => SCREEN_WIDTH,
        SCREEN_HEIGHT => SCREEN_HEIGHT
    )
    port map (
        clk_i       => clk,
        rst_i       => rst,
        
        data_i      => data_in,
        stb_i       => stb_in,
        ack_o       => ack_out,
        
        data_o      => data_out,
        stb_o       => stb_out,
        ack_i       => ack_in
    );
    

-- Send vertices produced by fragment_ops indefinetely


process(clk)
    variable fstatus    : file_open_status := STATUS_ERROR;
    file f_out          : BinaryFile;
begin
    if Rising_edge(clk) then
        -- ack_in <= not ack_in;
        -- report "ack_in " & std_logic'image(ack_in);
        -- report "stb_out " & std_logic'image(stb_out);
        if rst = '1' then
            if fstatus = STATUS_ERROR then
                -- open output file once
                file_open(fstatus, f_out, OUT_FIFO_NAME, WRITE_MODE);
            end if;
        else
            -- report "ack_in " & std_logic'image(ack_in);
            if (stb_out = '1') and (ack_in = '1') then
                WriteUint32(f_out, data_out);
                if (data_out = GPU_PIPE_CMD_FRAME_END) then
                    flush(f_out);
                end if;
                -- report "write " & to_hstring(data_out);
            end if;
        end if;
    end if;
end process;

process(clk)
    variable fstatus    : file_open_status := STATUS_ERROR;
    variable status     : integer;
    variable datainbuff : vec32;
    file f_in           : BinaryFile;
begin
    if Rising_edge(clk) then
        if rst = '1' then
            if fstatus = STATUS_ERROR then
                -- open output file once
                file_open(fstatus, f_in, IN_FIFO_NAME, READ_MODE);
            end if;
        else
            -- report "ack_o " & std_logic'image(ack_out);
            if (ack_out = '1') then
                ReadUint32(f_in, datainbuff);
                -- report "read " & to_hstring(datainbuff);
                data_in <= datainbuff;
                stb_in <= '1';
            else
                stb_in <= '0';
            end if;
        end if;
    end if;
end process;

end fileio;
