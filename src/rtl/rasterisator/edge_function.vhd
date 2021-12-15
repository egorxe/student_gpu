----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/09/2021 09:56:55 PM
-- Design Name: 
-- Module Name: edge_function - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


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
    );
    Port (  clk : in std_logic;
            rst : in std_logic;
        );
           
end edge_function;

architecture Behavioral of edge_function is

type vec4 is array (0 to 3) of float32;
type bound is array (0 to 4) of float32;



type file_real is file of float32;

begin   
  
    unsinc: process
    variable w0 : float32;  
    variable w1 : float32;
    variable w2 : float32;
    variable area_inv : float32;
    variable back_face : std_logic := '0';
    
    variable wn : float32;
    file f_in : BinaryFile;
    file f_out : BinaryFile;
    
    variable x : float32;
    variable y : float32;
    variable z : float32;

    variable r : vec32;
    variable g : vec32;
    variable b : vec32;

    variable y_max : float32;
    variable y_min : float32;
    variable x_max : float32;
    variable x_min : float32;

    variable x_b : bound;
    variable y_b : bound;

    variable v0 : vec4;
    variable v1 : vec4;
    variable v2 : vec4;
    
    variable c0 : vec4;
    variable c1 : vec4;
    variable c2 : vec4;
    
    variable p : vec4;
    variable cmd : vec32;
    
    variable pipline_max_z : float32 := to_float(to_vec32(2**16));
    
    begin
    
       file_open(f_in, "in.fifo", read_mode);
       file_open(f_out, "out.fifo", write_mode);
        report "F_in was opened";
        
    while not endfile(f_in) loop
        
        ReadUint32(f_in, cmd);
        if cmd /= GPU_PIPE_CMD_POLY_VERTEX then
            WriteUint32(f_out, cmd);
            WriteUint32(f_out, zero32);
            report "New frame";

        else
        
        ReadFloat(f_in, v0(0));
        ReadFloat(f_in, v0(1));
        ReadFloat(f_in, v0(2));
        ReadFloat(f_in, v0(3));
        ReadFloat(f_in, c0(0));
        ReadFloat(f_in, c0(1));
        ReadFloat(f_in, c0(2));
        ReadFloat(f_in, c0(3));
        
        ReadFloat(f_in, v1(0));
        ReadFloat(f_in, v1(1));
        ReadFloat(f_in, v1(2));
        ReadFloat(f_in, v1(3));
        ReadFloat(f_in, c1(0));
        ReadFloat(f_in, c1(1));
        ReadFloat(f_in, c1(2));
        ReadFloat(f_in, c1(3));
        
        
        ReadFloat(f_in, v2(0));
        ReadFloat(f_in, v2(1));
        ReadFloat(f_in, v2(2));
        ReadFloat(f_in, v2(3));
        ReadFloat(f_in, c2(0));
        ReadFloat(f_in, c2(1));
        ReadFloat(f_in, c2(2));
        ReadFloat(f_in, c2(3));      

        
        report "Read f_in";
        
    
        area_inv := to_float(1.0) / ((v2(0) - v0(0))*(v1(1) - v0(1)) - (v2(1) - v0(1))*(v1(0) - v0(0)));
        back_face := '0';
        if area_inv < to_float(0.0) then 
            back_face := '1';
        end if;
        
        if v0(0) > v1(0) then
            x_max := v0(0);
            x_min := v1(0);
        else
            x_max := v1(0);
            x_min := v0(0);
        end if;
            
        if v2(0) > x_max then
            x_max := v2(0);
        end if;
            
        if v2(0) < x_min then 
            x_min := v2(0);
        end if;
            
        if x_max > max_width then
            x_max := max_width;
        end if;
            
        if x_min < 0.0 then
            x_min := to_float(0.0);
        end if;

        
        
        
        if v0(1) > v1(1) then
            y_max := v0(1);
            y_min := v1(1);
        else
            y_max := v1(1);
            y_min := v0(1);
        end if;
            
        if v2(1) > y_max then
            y_max := v2(1);
        end if;
            
        if v2(1) < y_min then
            y_min := v2(1);
        end if;
        
        if y_max > max_heigh then
            y_max := max_heigh;
        end if;
        if y_min < 0.0 then
            y_min := to_float(0.0);  
        end if;
        
            
        if (x_max >= 0) and (y_max >= 0) and (x_min <= max_width) and (y_min <= max_heigh) then
        
        
        --report integer'image(x_min)&" "&integer'image(x_max)&" "&integer'image(y_min)&" "&integer'image(y_max);
        
        report "max and min have been founded";
        
        for i in to_uint(x_min) to to_uint(x_max) loop  --как преобразовать к integer?
            for j in to_uint(y_min) to to_uint(y_max) loop
                p(0) := i + to_float(0.5);   --what is f in c++ code?
                p(1) := j + to_float(0.5);
                p(2) := to_float(0.0);
                p(3) := to_float(0.0);
                
                w0 := (p(0) - v1(0))*(v2(1) - v1(1)) - (p(1) - v1(1))*(v2(0) - v1(0));
                w1 := (p(0) - v2(0))*(v0(1) - v2(1)) - (p(1) - v2(1))*(v0(0) - v2(0));
                w2 := (p(0) - v0(0))*(v1(1) - v0(1)) - (p(1) - v0(1))*(v1(0) - v0(0));
                
               -- report "Edge functions have been calculated";
                
                if (((w0 >= to_float(0.0)) and (w1 >= to_float(0.0)) and (w2 >= to_float(0.0)) and (back_face = '0')) or ((w0 <= to_float(0.0)) and (w1 <= to_float(0.0)) and (w2 <= to_float(0.0)) and (back_face = '1'))) then
                    
                    w0 := w0 * area_inv;
                    w1 := w1 * area_inv;
                    w2 := w2 * area_inv;
                    
                    z := (v0(2) * w0 + v1(2) * w1 + v2(2) * w2) * PIPLINE_MAX_Z; 
                    wn := w0 * v0(3) + w1 * v1(3) + w2 * v2(3);
                    
                    --report integer'image(i)&" "&integer'image(j);
                    
                    r := to_vec32((w0 * c0(0) + w1 * c1(0) + w2 * c2(0)) * 255);
                    g := to_vec32((w0 * c0(1) + w1 * c1(1) + w2 * c2(1)) * 255);
                    b := to_vec32((w0 * c0(2) + w1 * c1(2) + w2 * c2(2)) * 255);
       
                    WriteUint32(f_out, GPU_PIPE_CMD_FRAGMENT);
                    WriteUint32(f_out, to_vec32(i));
                    WriteUint32(f_out, to_vec32(j));
                    WriteUint32(f_out, to_vec32(0));
                    WriteUint32(f_out, "00000000" & r(7 downto 0) & g(7 downto 0) & b(7 downto 0));
                    --WriteUint32(f_out, "00000000" & "11111111" & "11111111" & "11111111");
                    
              
                end if;
            end loop;
        end loop;
        end if;
        end if;
    end loop;
                
    file_close(f_in);
    file_close(f_out);
                    
    wait;
    end process;

end Behavioral;






















