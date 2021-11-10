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
use IEEE.std.textio.all;
use IEEE.std_logic_textio.all;
use IEEE.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity edge_function is

    Generic (
        constant max_width : real := 1080.0;
        constant max_heigh : real := 920.0
    );
    Port ( x1 : in STD_LOGIC;   --Как устроть прем данныx?
           x2 : in STD_LOGIC;
           x3 : in STD_LOGIC);
           
end edge_function;

architecture Behavioral of edge_function is

type vec4 is array (0 to 3) of real;
type bound is array (0 to 4) of real;


signal y_max : real;
signal y_min : real;
signal x_max : real;
signal x_min : real;

signal x : real;
signal y : real;
signal z : real;

signal r : real;
signal g : real;
signal b : real;



signal a : vec4;
signal b : vec4;
signal c : vec4;
signal p : vec4;

signal x_b : bound;
signal y_b : bound;


begin   

    unsinc: process
    variable w0 : real;  --What is variable?
    variable w1 : real;
    variable w2 : real;
    variable area_inv : real;
    variable back_face : std_logic := '0';
    
    variable wn : real;
    
    
    begin
    
        area_inv := 1.0 / ((c(0) - a(0))*(b(1) - a(1)) - (c(1) - a(1))*(b(0) - a(0)));
        
        if area_inv < 0.0 then 
            back_face := '1';
        end if;
        
    
        x_b(0) <= a(0);
        x_b(1) <= b(0);
        x_b(2) <= c(0);
        x_b(3) <= 0.0;
        x_b(4) <= max_width; 
        
        y_b(0) <= a(1);
        y_b(1) <= b(1);
        y_b(2) <= c(1);
        y_b(3) <= 0.0;
        y_b(4) <= max_heigh; 
        
        x_min <= x_b(0);
        x_max <= x_b(0);
        y_min <= y_b(0);
        y_max <= y_b(0);
            
        for i in 0 to 4 loop
            if x_b(i) > x_max then
                x_max <= x_b(i);
            end if;
            
            if x_b(i) < x_min then
                x_min <= x_b(i);
            end if;
            
            if y_b(i) > y_max then
                y_max <= y_b(i);
            end if;
            
            if y_b(i) < y_min then
                y_min <= y_b(i);
            end if;
        end loop;
        
        for i in x_min to x_max loop  --как преобразовать к integer?
            for j in y_min to y_max loop
                p(0) <= i + 0.5;   --what is f in c++ code?
                p(1) <= j + 0.5;
                p(2) <= 0.0;
                p(3) <= 0.0;
                
                w0 := (p(0) - b(0))*(c(1) - b(1)) - (p(1) - b(1))*(c(0) - b(0));
                w1 := (p(0) - c(0))*(a(1) - c(1)) - (p(1) - c(1))*(a(0) - c(0));
                w2 := (p(0) - a(0))*(b(1) - a(1)) - (p(1) - a(1))*(b(0) - a(0));
                
                if ((w0 >= 0.0) and (w1 >= 0.0) and (w2 >= 0.0) and not back_face) or ((w0 <= 0.0) and (w1 <= 0.0) and (w2 <= 0.0) and back_face) then
                    
                    z <= (a(2) * w0 + b(2) * w1 + c(2) * w2) * PIPLINE_MAX_Z;   --What is PIPLINE_MAX_Z?
                    wn := w0 * a(3) + w1 * b(3) + w2 * c(3);
                    
                    r <= --Разобратьс с ветом
                end if;
            end loop;
        end loop;
                
        
    end process;

end Behavioral;






















