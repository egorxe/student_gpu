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
    IN_FIFO_NAME    : string := "in.fifo";
    OUT_FIFO_NAME   : string := "out.fifo"
  );
end fragment_ops;

architecture core of fragment_ops is
begin
  process
  file f_out          : BinaryFile;
  file f_in           : BinaryFile;
  variable data_out: vec32;
  begin
    file_open(f_out, OUT_FIFO_NAME, WRITE_MODE);
    file_open(f_in, IN_FIFO_NAME, READ_MODE);
    while true loop
      ReadUint32(f_in, data_out);

      WriteUint32(f_out, data_out);
    end loop;

  end process;
end core;
