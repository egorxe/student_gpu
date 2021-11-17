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
    DRAW_DEPTH_BUF  : std_logic := '1';
    PIPELINE_MAX_Z  : vec32     := X"00010000"
  );
end fragment_ops;

architecture core of fragment_ops is
type buff is array (0 to SCREEN_WIDTH*SCREEN_HEIGHT) of vec32;  
signal depth_buffer : buff;

begin
  process
  file f_out          : BinaryFile;
  file f_in           : BinaryFile;
  variable data_out   : vec32;
  variable c          : vec32;
  begin
    file_open(f_out, OUT_FIFO_NAME, WRITE_MODE);
    file_open(f_in, IN_FIFO_NAME, READ_MODE);
    for i in 0 to SCREEN_WIDTH loop
      for j in 0 to SCREEN_HEIGHT loop
        depth_buffer(to_vec32(i * SCREEN_HEIGHT + j)) <= PIPELINE_MAX_Z;
      end loop; -- for j in 0 to SCREEN_HEIGHT        
    end loop; -- for i in 0 to SCREEN_WIDTH
    while true loop
      ReadUint32(f_in, data_out);
      if DRAW_DEPTH_BUF then
        for x in 0 to SCREEN_WIDTH loop
          for y in 0 to SCREEN_HEIGHT loop
            data_out := to_vec32(x) or (to_vec32(y) sll 16);
            -- WriteUint32(f_out, data_out);
            c := (PIPELINE_MAX_Z - depth_buffer(to_vec32(x * SCREEN_HEIGHT + y)));
            data_out := (c sll 16) or (c sll 8) or c;
            -- WriteUint32(f_out, data_out);
          end loop; -- for j in 0 to SCREEN_HEIGHT        
        end loop; -- for i in 0 to SCREEN_WIDTH
      end if;
      
      --  for i in 0 to SCREEN_WIDTH loop
      --   for j in 0 to SCREEN_HEIGHT loop

      --   end loop; -- for j in 0 to SCREEN_HEIGHT        
      --  end loop; -- for i in 0 to SCREEN_WIDTH
      WriteUint32(f_out, data_out);
    end loop;

  end process;
end core;
