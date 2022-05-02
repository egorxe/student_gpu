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
        
        axistready_out    : in global_axis_miso_type; --ready
        axistire_out      : out global_axis_mosi_type; --data
        
        axistready_in     : out global_axis_miso_type; --ready
        axistire_in       : in global_axis_mosi_type --data
    );
end fragment_ops_axis;

architecture core of fragment_ops_axis is
    signal x          : vecaxisdata := (others => '0');
    signal y          : vecaxisdata := (others => '0');
    signal z          : vecaxisdata := (others => '0');
    signal color      : vecaxisdata := (others => '0');
    type buff is array (0 to SCREEN_WIDTH*SCREEN_HEIGHT) of vecaxisdata;  
    signal depth_buffer : buff;
begin
    process (clk_i, rst_i)
    variable cmd        : vecaxisdata := (others => '0');
    -- variable c          : vec32; -- printf debug
    type state_type is (IDLE, SENT_ZERO, Z_TO_ZERO, XREAD, YREAD, ZREAD, COLORREAD, CHECK, XYOUT, COLOROUT);
    variable state      : state_type := IDLE;
    variable i          : integer;
    variable j          : integer;

    begin
        if Rising_edge(clk_i) then
            axistready_in.axis_tready <= '0';
            axistire_out.axis_tvalid <= '0';
            axistire_out.axis_tlast <= '0';
            case state is
                when IDLE =>
                if axistire_in.axis_tvalid = '1' then
                    cmd := axistire_in.axis_tdata;
                    i := 0;
                    j := 0;
                    if not(cmd = GPU_PIPE_CMD_FRAGMENT) then
                        if axistready_out.axis_tready = '1' then
                            axistire_out.axis_tdata <= cmd;
                            state := SENT_ZERO;
                        end if;
                        -- ack_o <= '0';
                        -- report "FRAME";
                    else
                        -- stb_o <= '0';
                        axistready_in.axis_tready <= '1';
                        state := XREAD;
                    end if;
                else
                    axistready_in.axis_tready <= '1';
                end if;

                when SENT_ZERO =>
                if axistready_out.axis_tready = '1' then
                    axistire_out.axis_tdata <= (others => '0');
                    axistire_out.axis_tvalid <= '1';
                    state := Z_TO_ZERO;
                end if;

                when Z_TO_ZERO =>
                if i < SCREEN_WIDTH then
                    if j < SCREEN_HEIGHT then
                        depth_buffer(i * SCREEN_HEIGHT + j) <= PIPELINE_MAX_Z;
                        j := j+1;
                    else
                        j := 0;
                        i := i+1;
                    end if;
                else
                    axistready_in.axis_tready <= '1';
                    state := IDLE;
                end if;

                when XREAD =>
                if axistire_in.axis_tvalid = '1' then
                    x <= axistire_in.axis_tdata;
                    axistready_in.axis_tready <= '1';
                    state := YREAD;
                end if;

                when YREAD =>
                if axistire_in.axis_tvalid = '1' then
                    y <= axistire_in.axis_tdata;
                    axistready_in.axis_tready <= '1';
                    state := ZREAD;
                end if;
                
                when ZREAD =>
                if axistire_in.axis_tvalid = '1' then
                    z <= axistire_in.axis_tdata;
                    axistready_in.axis_tready <= '1';
                    state := COLORREAD;
                end if;
                
                when COLORREAD =>
                if axistire_in.axis_tvalid = '1' then
                    color <= axistire_in.axis_tdata;
                    state := CHECK;
                end if;
                
                when CHECK =>
                if z >= depth_buffer(to_uint(x) * SCREEN_HEIGHT + to_uint(y)) then
                    axistready_in.axis_tready <= '1';
                    state := IDLE;
                else
                    depth_buffer(to_sint(x) * SCREEN_HEIGHT + to_sint(y)) <= z;
                    state := XYOUT;
                    -- ack_o <= '0';
                end if;

                when XYOUT =>
                if axistready_out.axis_tready = '1' then
                    axistire_out.axis_tdata <= x or (y sll GLOBAL_AXIS_DATA_WIDTH/2);
                    state := COLOROUT;
                end if;

                when COLOROUT =>
                if axistready_out.axis_tready = '1' then
                    axistire_out.axis_tdata <= color;
                    axistready_in.axis_tready <= '1';
                    state := IDLE;
                end if;
            end case;
        end if;
    end process;

end core;
