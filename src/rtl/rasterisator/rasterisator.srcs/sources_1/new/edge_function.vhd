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
            rst : in std_logic
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

    variable r : float32;
    variable g : float32;
    variable b : float32;

    variable y_max : integer;
    variable y_min : integer;
    variable x_max : integer;
    variable x_min : integer;

    variable x_b : bound;
    variable y_b : bound;

    variable v0 : vec4;
    variable v1 : vec4;
    variable v2 : vec4;
    
    variable c0 : vec4;
    variable c1 : vec4;
    variable c2 : vec4;
    
    variable p : vec4;
    
    variable pipline_max_z : float32 := to_float(100000000);
    
    begin
    
       file_open(f_in, "in.fifo", read_mode);
       file_open(f_out, "out.fifo", write_mode);
        report "F_in was opened";
        
    while not endfile(f_in) loop
        
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
            
        if v2(0) > x_max then
            x_max := v2(0);
            
        if v2(0) < x_min then 
            x_min := v2(0);
            
        if x_max > max_width then
            x_max := max_width;
            
        if x_min < 0 then
            x_min := 0;
            

        
        
        
        if v0(1) > v1(1) then
            y_max := v0(1);
            y_min := v1(1);
        else
            y_max := v1(1);
            y_min := v0(1);
            
        if v2(1) > y_max then
            y_max := v2(1);
            
        if v2(1) < y_min then
            y_min := v2(1);
        
        if y_max > max_height then
            y_max := max_height;
        if y_min < 0 then
            y_min := 0;    
        
            
        
        
        
        
        
        
    
--        x_b(0) := v0(0);
--        x_b(1) := v1(0);
--        x_b(2) := v2(0);
--        x_b(3) := to_float(0.0);
--        x_b(4) := max_width; 
        
--        y_b(0) := v0(1);
--        y_b(1) := v1(1);
--        y_b(2) := v2(1);
--        y_b(3) := to_float(0.0);
--        y_b(4) := max_heigh; 
        
--        x_min := to_integer(x_b(0));
--        x_max := to_integer(x_b(0));
--        y_min := to_integer(y_b(0));
--        y_max := to_integer(y_b(0));
            
--        for i in 0 to 4 loop
--            if x_b(i) > x_max then
--                x_max := to_integer(x_b(i));
--            end if;
            
--            if x_b(i) < x_min then
--                x_min := to_integer(x_b(i));
--            end if;
            
--            if y_b(i) > y_max then
--                y_max := to_integer(y_b(i));
--            end if;
            
--            if y_b(i) < y_min then
--                y_min := to_integer(y_b(i));
--            end if;
--        end loop;

        
        if (x_max >= 0) and (y_max >= 0) and (x_min <= max_width) and (y_min <= max_height) then
        
        
        report integer'image(x_min)&" "&integer'image(x_max)&" "&integer'image(y_min)&" "&integer'image(y_max);
        
        report "max and min have been founded";
        
        for i in x_min to x_max loop  --?????? ?????????????????????????? ?? integer?
            for j in y_min to y_max loop
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
                    
                    z := (v0(2) * w0 + v1(2) * w1 + v2(2) * w2) * PIPLINE_MAX_Z;   --What is PIPLINE_MAX_Z?
                    wn := w0 * v0(3) + w1 * v1(3) + w2 * v2(3);
                    
                    report integer'image(i)&" "&integer'image(j);
                    
                    r := w0 * c0(0) + w1 * c1(0) + w2 * c2(0);
                    g := w0 * c0(1) + w1 * c1(1) + w2 * c2(1);
                    b := w0 * c0(2) + w1 * c1(2) + w2 * c2(2);
       
                    
                    WriteFloat(f_out, to_float(i));
                    WriteFloat(f_out, to_float(j));
                    WriteFloat(f_out, z);
                    WriteFloat(f_out, r);
                    WriteFloat(f_out, g);
                    WriteFloat(f_out, b);
                    
                    
              
                end if;
            end loop;
        end loop;
        end if;
    end loop;
                
    file_close(f_in);
    file_close(f_out);
                    
    wait;
    end process;

end Behavioral;






















