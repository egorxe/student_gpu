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
    SCREEN_HEIGHT   : integer   := 480;
    IN_FIFO_NAME    : string    := "in.fifo";
    OUT_FIFO_NAME   : string    := "out.fifo";
    DRAW_DEPTH_BUF  : std_logic := '0';
    PIPELINE_MAX_Z  : vec32     := X"00010000"
  );
end fragment_ops;

architecture core of fragment_ops is
begin
  process
  file f_out          : BinaryFile;
  file f_in           : BinaryFile;
  variable cmd        : vec32 := ZERO32;
  -- variable data_out   : vec32 := ZERO32;
  variable x          : vec32 := ZERO32;
  variable y          : vec32 := ZERO32;
  variable z          : vec32 := ZERO32;
  variable color      : vec32 := ZERO32;
  type buff is array (0 to SCREEN_WIDTH*SCREEN_HEIGHT) of vec32;  
  variable depth_buffer : buff;
  variable c          : vec32;
  begin
    file_open(f_out, OUT_FIFO_NAME, WRITE_MODE);
    file_open(f_in,  IN_FIFO_NAME,  READ_MODE);
    for i in 0 to SCREEN_WIDTH-1 loop
      for j in 0 to SCREEN_HEIGHT-1 loop
        depth_buffer(i * SCREEN_HEIGHT + j) := PIPELINE_MAX_Z;

      end loop; -- for j in 0 to SCREEN_HEIGHT-1        
    end loop; -- for i in 0 to SCREEN_WIDTH-1
    while true loop
      ReadUint32(f_in, cmd);
      if not(cmd = X"FFFFFF02") then
        if DRAW_DEPTH_BUF then
          for i in 0 to SCREEN_WIDTH-1 loop
            for j in 0 to SCREEN_HEIGHT-1 loop
              WriteUint32(f_out, to_vec32(i) or (to_vec32(j) sll 16));
              c := to_vec32(to_sint(PIPELINE_MAX_Z - depth_buffer(i * SCREEN_HEIGHT + j)) * 255 / to_sint(PIPELINE_MAX_Z));
              -- report to_hstring(c);
              WriteUint32(f_out, (c sll 16) or (c sll 8) or c);
            end loop; -- for j in 0 to SCREEN_HEIGHT-1        
          end loop; -- for i in 0 to SCREEN_WIDTH-1
        end if;
        WriteUint32(f_out, cmd);
        WriteUint32(f_out, ZERO32);
        for i in 0 to SCREEN_WIDTH-1 loop
          for j in 0 to SCREEN_HEIGHT-1 loop
            depth_buffer(i * SCREEN_HEIGHT + j) := PIPELINE_MAX_Z;
          end loop; -- for j in 0 to SCREEN_HEIGHT-1        
        end loop; -- for i in 0 to SCREEN_WIDTH-1
        next;
      end if;
      ReadUint32(f_in, x);
      ReadUint32(f_in, y);
      ReadUint32(f_in, z);
      ReadUint32(f_in, color);
      -- report to_hstring(x) &" "& to_hstring(y) &" "& to_hstring(z) &" "& to_hstring(color);
      if z >= depth_buffer(to_uint(x) * SCREEN_HEIGHT + to_uint(y)) then
        next;
      end if;
      depth_buffer(to_sint(x) * SCREEN_HEIGHT + to_sint(y)) := z;
      if not DRAW_DEPTH_BUF then
        WriteUint32(f_out, x or (y sll 16));
        WriteUint32(f_out, color);
      end if;
    end loop;

  end process;
end core;
