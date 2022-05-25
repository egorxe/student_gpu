-- Demo stage which shows a way to work with in & out FIFOs (testbench part)

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.float_pkg.all;
    use std.textio.all;
    use ieee.std_logic_textio.all;
    
use work.gpu_pkg.all;
use work.file_helper_pkg.all;

entity fragment_ops_axis_tb is
    generic (
        SCREEN_WIDTH    : integer   := 640;
        SCREEN_HEIGHT   : integer   := 480;
        IN_FIFO_NAME    : string := "in.fifo";
        OUT_FIFO_NAME   : string := "out.fifo"
    );
end fragment_ops_axis_tb;

architecture fileio_axis of fragment_ops_axis_tb is

component fragment_ops_axis is
    generic (
        SCREEN_WIDTH    : integer;
        SCREEN_HEIGHT   : integer
    );
    port (
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;
        
        axistready_o    : in global_axis_miso_type; --ready
        axistire_o      : out global_axis_mosi_type; --data
        
        axistready_i     : out global_axis_miso_type; --ready
        axistire_i       : in global_axis_mosi_type --data
    );
end component;

constant CLK_PERIOD : time := 10 ns;

signal axistready_out   : global_axis_miso_type; --ready
signal axistire_out     : global_axis_mosi_type; --data

signal axistready_in    : global_axis_miso_type; --ready
signal axistire_in      : global_axis_mosi_type; --data

signal clk      : std_logic := '0';
signal rst      : std_logic := '1';

signal counter  : integer   :=  0;
signal clikcounter : integer := 0;
-- signal ack_in   : std_logic := '1';
begin

clk <= not clk after CLK_PERIOD/2;
rst <= '0' after CLK_PERIOD*10;

tv : fragment_ops_axis
    generic map (
        SCREEN_WIDTH => SCREEN_WIDTH,
        SCREEN_HEIGHT => SCREEN_HEIGHT
    )
    port map (
        clk_i       => clk,
        rst_i       => rst,
        
        axistready_o   => axistready_out,
        axistire_o     => axistire_out,
        axistready_i   => axistready_in,  
        axistire_i     => axistire_in
    );
    

-- Send vertices produced by fragment_ops indefinetely


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

            if counter > 64 then
                -- report "clik" & integer'image(clikcounter);
                clikcounter <= clikcounter + 1;
                axistire_in.axis_tvalid <= '1';
                counter <= 0;
            elsif counter > 32 then
                axistire_in.axis_tvalid <= '0';
                counter <= counter + 1;
            else
                axistire_in.axis_tvalid <= '1';
                counter <= counter + 1;
            end if;

            if (axistready_in.axis_tready = '1') and (axistire_in.axis_tvalid = '1') then
                WriteUint32(f_out, axistire_out.axis_tdata);
                if (axistire_out.axis_tdata = GPU_PIPE_CMD_FRAME_END) then
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
            report "ack_o " & std_logic'image(axistready_out.axis_tready);
            report "stb_i " & std_logic'image(axistire_in.axis_tvalid);
            if (axistready_out.axis_tready = '1') then
                ReadUint32(f_in, datainbuff);
                -- report "read " & to_hstring(datainbuff);
                axistire_in.axis_tdata <= datainbuff;
                axistire_in.axis_tvalid <= '1';
            else
                axistire_in.axis_tvalid <= '0';
            end if;
        end if;
    end if;
end process;

end fileio_axis;
