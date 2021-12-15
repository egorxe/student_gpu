library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use IEEE.std_logic_textio.all;
use IEEE.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use ieee.float_pkg.all;
use ieee.fixed_pkg.all;

use work.gpu_pkg.all;
use work.file_helper_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axis_in is

    Generic (
    );
    Port (  clk : in std_logic;
            rst : in std_logic;
            
            s_i : in global_axis_mosi_type;
            
            s_o : out RV;
            
            ready_o : out std_logic
            
            
        );
           
end axis_in;

architecture Behavioral of axis_in is

type state is (idle, read_x, read_y, read_z, read_w, read_r, read_g, read_b, read_a,
                     wait_x, wait_y, wait_z, wait_w, wait_r, wair_g, wait_b, wait_a);


type my_type is record
    state : state;
    data  : RV;
    ready : std_logic;
    ready_out : std_logic;
    i     : integer := 0;
    buf   : RV;
end record;


signal r, rin : my_type;



begin

    s_o     <= r.buf;
    ready_o <= r.ready_out;

    asinc : process (r, s_i.axis_tvalid)
    variable v : my_type;
    begin
    
        v := r;
        case state is
        
            when idle =>
                v.i := 0;
                v.ready_out := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := wait_x;
                end if;
                
            when wait_x =>
                v.ready := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := read_x;
                end if;
            
            
            when read_x =>
                v.data.x := to_float(s_i.axis_tdata);
                report "x: "& float32'image(v.data.x);
                v.ready  := '1';
                v.state  := wait_y;
                
            when wait_y =>
                v.ready := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := read_y;
                end if;
                
            when read_y =>
                v.data.y := to_float(s_i.axis_tdata);
                report "y: "& float32'image(v.data.y);
                v.ready  := '1';
                v.state  := wait_z;
                
            when wait_z =>
                v.ready := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := read_z;
                end if;
                
            when read_z =>
                v.data.z := to_float(s_i.axis_tdata);
                report "z: "& float32'image(v.data.z);
                v.ready  := '1';
                v.state  := wait_w;
                
            when wait_w =>
                v.ready := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := read_w;
                end if;
                
            when read_w =>
                v.data.w := to_float(s_i.axis_tdata);
                report "w: "& float32'image(v.data.w);
                v.ready  := '1';
                v.state  := wait_r;
                
            
            when wait_r =>
                v.ready := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := read_r;
                end if;
                
            when read_r =>
                v.data.r := to_float(s_i.axis_tdata);
                report "r: "& float32'image(v.data.r);
                v.ready  := '1';
                v.state  := wait_g;
                
            when wait_g =>
                v.ready := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := read_g;
                end if;
                
            when read_g =>
                v.data.g := to_float(s_i.axis_tdata);
                report "g: "& float32'image(v.data.g);
                v.ready  := '1';
                v.state  := wait_b;
                
            when wait_b =>
                v.ready := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := read_b;
                end if;
                
            when read_b =>
                v.data.b := to_float(s_i.axis_tdata);
                report "b: "& float32'image(v.data.b);
                v.ready  := '1';
                v.state  := wait_a;
                
            when wait_a =>
                v.ready := '0';
                if s_i.axis_tvalid = '1' then
                    v.state := read_a;
                end if;
                
            when read_a =>
                v.data.a := to_float(s_i.axis_tdata);
                report "a: "& float32'image(v.data.a);
                v.ready  := '1';
                v.state  := write_buf;
                
            when write_buf =>
                if v.i < 3 then
                    v.buf := v.data;
                    v.i := v.i + 1;
                    v.state := wait_x;
                else
                    v.ready_out <= '1';
                    
                    v.state := idle;
                end if;
                
        end case;
    
    rin <= r;
    end process;
    
    sync : process (clk);
    
    begin
    
        if rising_edge(clk) then
            if rst = '1' then
                r.state     <= idle;
                r.data      <= rast_vertex_default;
                r.i         <= 0;
                r.buf       <= (others => rast_vertex_default);
                r.ready     <= '0';
                r.ready_out <= '0';
            else
                r <= rin;
            end if;
        end if;
    end process;
                

            


end Behavioral;








































