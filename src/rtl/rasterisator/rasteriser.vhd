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

entity edge_function is

    Generic (
        constant max_width : float32 := to_float(640.0);
        constant max_heigh : float32 := to_float(480.0)
        constant n : integer := 
    );
    Port (  clk : in std_logic;
            rst : in std_logic;
            vec_i : in RV;
            vec_o : out RV;
            ready_i : in std_logic;
        );
           
end edge_function;

architecture Behavioral of edge_function is

type vec4 is array (0 to 3) of float32;
type bound is array (0 to 4) of float32;



type file_real is file of float32;

type ef_array is array (0 to n-1) of ef; 
type w_array  is array (0 to n-1) of float32;

type state is (idle, framing, calculate_edge_function);
type reg_type is record
    state     : state;
    vec_buf   : rv;
    x_max     : float32;
    x_min     : float32;
    y_max     : float32;
    y_min     : float32;
    x         : integer := 0;
    y         : integer := 0;
    i         : integer := 0;
    ver_ef    : ef_array;
    w0        : w_array;
    w1        : w_array;
    w2        : w_array;
    valid_buf : std_logic;
    mask      : std_logic; 
    
end record;




component calculate_edge_function is

    Generic (
        
    );
    Port (  clk : in std_logic;
            rst : in std_logic;
            
            x   : in float32;
            y   : in float32;
            a0x : in float32;
            a0y : in float32;
            a1x : in float32;
            a1y : in float32;
            a2x : in float32;
            a2y : in float32;
            
            w0   : out float32;
            w1   : out float32;
            w2   : out float32;
            
            mask : in std_logic;
            
            ready : out std_logic;
            valid : in  std_logic
            
        );
           
end component;

signal ready_buf : std_logic;



begin   
    
    EDGE_FUNCTIONS : for i in 0 to n-1 generate
    begin

        map_pixel_1 : calculate_edge_function
            generic map ()
            port map (
                clk <= clk,
                rst <= rst,
                x   <= r.ver_ef(i).x,
                y   <= r.ver_ef(i).y,
                a0x <= r.ver_ef(i).a1x,
                a0y <= r.ver_ef(i).a1y,
                a1x <= r.ver_ef(i).a1x,
                a1y <= r.ver_ef(i).a1y,
                a2x <= r.ver_ef(i).a2x,
                a2y <= r.ver_ef(i).a2y,
                
                mask <= r.mask;
                
                w0   <= r.ver_ef(i).w0,
                w1   <= r.ver_ef(i).w1,
                w2   <= r.ver_ef(i).w2,
                
                ready <= ready_buf,
                valid <= r.valid_buf
                
            );
    end generate;

    buffer_of_vertixes : process(ready_i, r)
    variable v : reg_type;
    begin
        v := r;
        
        case v.state is
        
            when idle =>
                
                if ready_i = '1' then
                    v.vec_buf := vec_i;
                    v.state := framing;
                end if;
                
            when framing =>
            
                if v.vec_buf(0).x > v.vec_buf(1).x then
                    v.x_max := v.vec_buf(0).x;
                    v.x_min := v.vec_buf(1).x;
                else
                    v.x_max := v.vec_buf(1).x;
                    v.x_min := v.vec_buf(0).x;
                end if;
            
                if v.vec_buf(2).x > v.x_max then
                    v.x_max := v.vec_buf(2).x;
                end if;
            
                if v.vec_buf(2).x < v.x_min then 
                    v.x_min := v.vec_buf(2).x;
                end if;
            
                if v.x_max > max_width then
                    v.x_max := max_width;
                end if;
            
                if v.x_min < 0.0 then
                    v.x_min := tf(0.0);
                end if;
                
                
                
                if v.vec_buf(0).y > v.vec_buf(1).y then
                    v.x_max := v.vec_buf(0).y;
                    v.x_min := v.vec_buf(1).y;
                else
                    v.x_max := v.vec_buf(1).y;
                    v.x_min := v.vec_buf(0).y;
                end if;
            
                if v.vec_buf(2).y > v.y_max then
                    v.y_max := v.vec_buf(2).y;
                end if;
            
                if v.vec_buf(2).y < v.y_min then 
                   v.y_min := v.vec_buf(2).y;
                end if;
            
                if v.y_max > max_heigh then
                    v.y_max := max_heigh;
                end if;
            
                if v.y_min < 0.0 then
                    v.y_min := tf(0.0);
                end if;
                
                if (v.x_max >= 0) and (v.y_max >= 0) and (v.x_min <= max_width) and (v.y_min <= max_heigh) then
                    v.i := to_uint(v.x_min);
                    v.j := to_uint(v.y_min);
                    v.state := calculate_edge_function;
                else
                    ...
                    v.state := idle;
            
            when calculate_edge_function_0 => 
                if v.y < to_uint(v.y_max) then  
                        for i in 0 to n - 1 loop
                            v.ver_ef(i).x := itf(v.x);
                            v.ver_ef(i).y := itf(v.y);
                            v.ver_ef(i).a1x := v.vec_buf(1).x;
                            v.ver_ef(i).a2x := v.vec_buf(2).x;
                            v.ver_ef(i).a1y := v.vec_buf(1).y;
                            v.ver_ef(i).a2y := v.vec_buf(2).y;
                            v.x := v.x + 1;
                            
                            if (v.x = to_uint(v.x_max)) and (v.y /= to_uint(v.y_max))  then
                                v.x := v.x_min;
                                v.y := v.y + 1;
                            end if;
                            
                            if (v.y = to_uint(v.y_max) - 1) and (v.x >= to_uint(v.x_max)) then
                                v.ver_ef(i).mask := '1';
                            else
                                v.ver_ef(i).mask := '0';
                            end if;
                                
                            
                        end loop;    
                        v.valid_buf := '1';
                        v.state := waiting_0;                    
                end if;
                
            when waiting_0 =>
                if ready_buf = '1' then
                    for i in 0 to n - 1 loop
                        v.w0(i) := v.ver_ef(i).w0;
                        
                    end loop;

                end if;
                        
                    
                        
                
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    


