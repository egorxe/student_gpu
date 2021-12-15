library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
use ieee.std_logic_textio.all;

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
  signal cmd        : vec32 := ZERO32;
  signal x          : vec32 := ZERO32;
  signal y          : vec32 := ZERO32;
  signal z          : vec32 := ZERO32;
  signal color      : vec32 := ZERO32;
  type buff is array (0 to SCREEN_WIDTH*SCREEN_HEIGHT) of vec32;  
  signal depth_buffer : buff;
begin
  process (clk_i, rst_i)
  variable c          : vec32; -- printf debug
  type state_type is (IDLE, XREAD, YREAD, ZREAD, COLORREAD, XYOUT, CHECK, COLOROUT);
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
            cmd <= data_i;
            i := 0;
            j := 0;
            if not(cmd = GPU_PIPE_CMD_FRAGMENT) then
              if i < SCREEN_WIDTH then
                if i < SCREEN_HEIGHT then
                  depth_buffer(i * SCREEN_HEIGHT + j) <= PIPELINE_MAX_Z;
                  j := j+1;
                else
                  j := 0;
                  i := i+1;
                end if;
              end if;
            else
              state := XREAD;
            end if;
            -- stb_o 
            ack_o <= '1';  
          end if;
        when XREAD =>
          if stb_i = '1' then
            x <= data_i;
            state := YREAD;
            ack_o <= '1';
          end if;
        when YREAD =>
          if stb_i = '1' then
            y <= data_i;
            state := ZREAD;
            ack_o <= '1';
          end if;
        when ZREAD =>
          if stb_i = '1' then
            z <= data_i;
            state := COLORREAD;
            ack_o <= '1';
          end if;
        when COLORREAD =>
          if stb_i = '1' then
            color <= data_i;
            state := CHECK;
            rdr_o <= '0';
            ack_o <= '1';
          end if;
        when CHECK =>
          if z >= depth_buffer(to_uint(x) * SCREEN_HEIGHT + to_uint(y)) then
            state := IDLE;
            rdr_o <= '1';
          else
            depth_buffer(to_sint(x) * SCREEN_HEIGHT + to_sint(y)) <= z;
            state := XYOUT;
            rdr_o <= '0';
          end if;
          
        when XYOUT =>
          data_o <= x or (y sll 16);
          stb_o <= '1';
          rdr_o <= '0';
          state := COLOROUT;
        when COLOROUT =>
          data_o <= color;
          stb_o <= '1';
          -- rdr_o <= '0';
          state := IDLE;
      end case;
-----------------------------------
      -- cmd <= data_i; -- ReadUint32(f_in, cmd);
      -- while true loop
      --   if not(cmd = X"FFFFFF02") then
      --     for i in 0 to SCREEN_WIDTH-1 loop
      --       for j in 0 to SCREEN_HEIGHT-1 loop
      --         depth_buffer(i * SCREEN_HEIGHT + j) <= PIPELINE_MAX_Z;
      --       end loop; -- for j in 0 to SCREEN_HEIGHT-1        
      --     end loop; -- for i in 0 to SCREEN_WIDTH-1
      --     next;
      --   end if;
      --   x <= data_i;-- ReadUint32(f_in, x);
      --   y <= data_i;-- ReadUint32(f_in, y);
      --   z <= data_i;-- ReadUint32(f_in, z);
      --   color <= data_i;-- ReadUint32(f_in, color);
      --   if z >= depth_buffer(to_uint(x) * SCREEN_HEIGHT + to_uint(y)) then
      --     next;
      --   end if;
      --   depth_buffer(to_sint(x) * SCREEN_HEIGHT + to_sint(y)) <= z;
      --   data_o <= x or (y sll 16);
      --   data_o <= color;
      -- end loop;
    end if;

  end process;
end core;
