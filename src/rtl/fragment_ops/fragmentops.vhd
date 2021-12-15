library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;

use work.gpu_pkg.all;
use work.file_helper_pkg.all;

entity fragment_ops is
  generic (
    SCREEN_WIDTH    : integer   := 640;
    SCREEN_HEIGHT   : integer   := 480
  );
  port (
    clk_i       : in  std_logic;
    rst_i       : in  std_logic;
    
    data_i      : in  vec32;
    stb_i       : in  std_logic;
    
    data_o      : out vec32;
    stb_o       : out std_logic;

    ack_o       : out std_logic;
    rdr_o       : out std_logic
  );
end fragment_ops;

architecture core of fragment_ops is
  
  signal x          : vec32 := ZERO32;
  signal y          : vec32 := ZERO32;
  signal z          : vec32 := ZERO32;
  signal color      : vec32 := ZERO32;
  type buff is array (0 to SCREEN_WIDTH*SCREEN_HEIGHT) of vec32;  
  signal depth_buffer : buff;
begin
  process (clk_i, rst_i)
  variable cmd        : vec32 := ZERO32;
  -- variable c          : vec32; -- printf debug
  type state_type is (IDLE, SENT_ZERO, Z_TO_ZERO, XREAD, YREAD, ZREAD, COLORREAD, XYOUT, CHECK, COLOROUT);
  variable state      : state_type := IDLE;
  variable i          : integer;
  variable j          : integer;
  begin
    if Rising_edge(clk_i) then
      ack_o <= '0'; 
      stb_o <= '0';
      rdr_o <= '1';
      case state is
        when IDLE =>
          if stb_i = '1' then
            -- report "IDLE";
            cmd := data_i;
            -- report "data_i " & to_hstring(data_i);
            i := 0;
            j := 0;
            -- report "cmd " & to_hstring(cmd);
            if not(cmd = GPU_PIPE_CMD_FRAGMENT) then
              data_o <= cmd;
              stb_o <= '1';
              rdr_o <= '0';
              state := SENT_ZERO;
              -- report "FRAME";
            else
              state := XREAD;
            end if;
            -- stb_o 
            ack_o <= '1';  
          end if;

        when SENT_ZERO =>
        -- report "SENT_ZERO";
          data_o <= ZERO32;
          stb_o <= '1';
          rdr_o <= '0';
          state := Z_TO_ZERO;

        when Z_TO_ZERO =>
          rdr_o <= '0';
          if i < SCREEN_WIDTH then
            if j < SCREEN_HEIGHT then
              depth_buffer(i * SCREEN_HEIGHT + j) <= PIPELINE_MAX_Z;
              j := j+1;
            else
              j := 0;
              i := i+1;
            end if;
          else
            rdr_o <= '1';
            state := IDLE;
            -- report "Z_TO_ZERO_end";
          end if;
        
        when XREAD =>
        -- report "XREAD";
          if stb_i = '1' then
            x <= data_i;
            state := YREAD;
            ack_o <= '1';
          end if;
        when YREAD =>
        -- report "YREAD";
          if stb_i = '1' then
            y <= data_i;
            state := ZREAD;
            ack_o <= '1';
          end if;
        when ZREAD =>
        -- report "ZREAD";
          if stb_i = '1' then
            z <= data_i;
            state := COLORREAD;
            ack_o <= '1';
            rdr_o <= '0';
          end if;
        when COLORREAD =>
        -- report "COLORREAD";
        -- report "stb_i " & std_logic'image(stb_i);
          if stb_i = '1' then
            color <= data_i;
            state := CHECK;
            rdr_o <= '0';
            ack_o <= '1';
          end if;

        when CHECK =>
        -- report "CHECK";
        -- report to_hstring(x);
        -- report to_hstring(y);
        -- report to_hstring(z);
          if z >= depth_buffer(to_uint(x) * SCREEN_HEIGHT + to_uint(y)) then
            state := IDLE;
            rdr_o <= '1';
          else
            depth_buffer(to_sint(x) * SCREEN_HEIGHT + to_sint(y)) <= z;
            state := XYOUT;
            rdr_o <= '0';
          end if;
          
        when XYOUT =>
        -- report "XYOUT";
          data_o <= x or (y sll 16);
          stb_o <= '1';
          rdr_o <= '0';
          state := COLOROUT;
        when COLOROUT =>
        -- report "COLOROUT";
          data_o <= color;
          stb_o <= '1';
          -- rdr_o <= '0';
          state := IDLE;
      end case;
    end if;

  end process;
end core;
