-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: FPU package wich contains constants and functions needed in the FPU core
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library  ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package fpupack is


	-- Data width of floating-point number. Deafult: 32
	constant FP_WIDTH : integer := 32;
	
	-- Data width of fraction. Deafult: 23
	constant FRAC_WIDTH : integer := 23;
	
	-- Data width of exponent. Deafult: 8
	constant EXP_WIDTH : integer := 8;

	--Zero vector
	constant ZERO_VECTOR: std_logic_vector(30 downto 0) := "0000000000000000000000000000000";
	
	-- Infinty FP format
	constant INF  : std_logic_vector(30 downto 0) := "1111111100000000000000000000000";
	
	-- QNaN (Quit Not a Number) FP format (without sign bit)
    constant QNAN : std_logic_vector(30 downto 0) := "1111111110000000000000000000000";
    
    -- SNaN (Signaling Not a Number) FP format (without sign bit)
    constant SNAN : std_logic_vector(30 downto 0) := "1111111100000000000000000000001";
    
    -- count the  zeros starting from left
    function count_l_zeros (signal s_vector: std_logic_vector) return std_logic_vector;
    
    -- count the zeros starting from right
	function count_r_zeros (signal s_vector: std_logic_vector) return std_logic_vector;
    
end fpupack;

package body fpupack is
    
    -- count the  zeros starting from left
	function count_l_zeros (signal s_vector: std_logic_vector) return std_logic_vector is
		variable v_count : std_logic_vector(5 downto 0);	
	begin
		v_count := "000000";
		for i in s_vector'range loop
			case s_vector(i) is
				when '0' => v_count := v_count + "000001";
				when others => exit;
			end case;
		end loop;
		return v_count;	
	end count_l_zeros;


	-- count the zeros starting from right
	function count_r_zeros (signal s_vector: std_logic_vector) return std_logic_vector is
		variable v_count : std_logic_vector(5 downto 0);	
	begin
		v_count := "000000";
		for i in 0 to s_vector'length-1 loop
			case s_vector(i) is
				when '0' => v_count := v_count + "000001";
				when others => exit;
			end case;
		end loop;
		return v_count;	
	end count_r_zeros;


		
end fpupack;-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: addition/subtraction entity for the addition/subtraction unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use IEEE.std_logic_arith.all;

library work;
use work.fpupack.all;

entity addsub_28 is
	port(
			clk_i 			: in std_logic;
			fpu_op_i		: in std_logic;
			fracta_i		: in std_logic_vector(FRAC_WIDTH+4 downto 0); -- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			fractb_i		: in std_logic_vector(FRAC_WIDTH+4 downto 0);
			signa_i 		: in std_logic;
			signb_i 		: in std_logic;
			fract_o			: out std_logic_vector(FRAC_WIDTH+4 downto 0);
			sign_o 			: out std_logic);
end addsub_28;


architecture rtl of addsub_28 is

signal s_fracta_i, s_fractb_i : std_logic_vector(FRAC_WIDTH+4 downto 0);
signal s_fract_o : std_logic_vector(FRAC_WIDTH+4 downto 0);
signal s_signa_i, s_signb_i, s_sign_o : std_logic;
signal s_fpu_op_i : std_logic;

signal fracta_lt_fractb : std_logic;
signal s_addop: std_logic;

begin

-- Input Register
--process(clk_i)
--begin
--	if rising_edge(clk_i) then	
		s_fracta_i <= fracta_i;
		s_fractb_i <= fractb_i;
		s_signa_i<= signa_i;
		s_signb_i<= signb_i;
		s_fpu_op_i <= fpu_op_i;
--	end if;
--end process;	

-- Output Register
process(clk_i)
begin
	if rising_edge(clk_i) then	
		fract_o <= s_fract_o;
		sign_o <= s_sign_o;	
	end if;
end process;

fracta_lt_fractb <= '1' when s_fracta_i > s_fractb_i else '0';

-- check if its a subtraction or an addition operation
s_addop <= ((s_signa_i xor s_signb_i)and not (s_fpu_op_i)) or ((s_signa_i xnor s_signb_i)and (s_fpu_op_i));

-- sign of result
s_sign_o <= '0' when s_fract_o = conv_std_logic_vector(0,28) and (s_signa_i and s_signb_i)='0' else 
										((not s_signa_i) and ((not fracta_lt_fractb) and (fpu_op_i xor s_signb_i))) or
										((s_signa_i) and (fracta_lt_fractb or (fpu_op_i xor s_signb_i)));

-- add/substract
process(s_fracta_i, s_fractb_i, s_addop, fracta_lt_fractb)
begin
	if s_addop='0' then
		s_fract_o <= s_fracta_i + s_fractb_i;
	else
		if fracta_lt_fractb = '1' then 
			s_fract_o <= s_fracta_i - s_fractb_i;
		else
			s_fract_o <= s_fractb_i - s_fracta_i;				
		end if;
	end if;
end process;




end rtl;

-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: component package
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library  ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.fpupack.all;

package comppack is


--- Component Declartions ---	

	--***Add/Substract units***
	
	component pre_norm_addsub is
	port(clk_i 			: in std_logic;
			 opa_i			: in std_logic_vector(31 downto 0);
			 opb_i			: in std_logic_vector(31 downto 0);
			 fracta_28_o		: out std_logic_vector(27 downto 0);	-- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			 fractb_28_o		: out std_logic_vector(27 downto 0);
			 exp_o			: out std_logic_vector(7 downto 0));
	end component;
	
	component addsub_28 is
	port(clk_i 			  : in std_logic;
			 fpu_op_i		   : in std_logic;
			 fracta_i			: in std_logic_vector(27 downto 0); -- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			 fractb_i			: in std_logic_vector(27 downto 0);
			 signa_i 			: in std_logic;
			 signb_i 			: in std_logic;
			 fract_o			: out std_logic_vector(27 downto 0);
			 sign_o 			: out std_logic);
	end component;
	
	component post_norm_addsub is
	port(clk_i 				: in std_logic;
			 opa_i 				: in std_logic_vector(31 downto 0);
			 opb_i 				: in std_logic_vector(31 downto 0);
			 fract_28_i		: in std_logic_vector(27 downto 0);	-- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			 exp_i			  : in std_logic_vector(7 downto 0);
			 sign_i			  : in std_logic;
			 fpu_op_i			: in std_logic;
			 rmode_i			: in std_logic_vector(1 downto 0);
			 output_o			: out std_logic_vector(31 downto 0);
			 ine_o				: out std_logic
		);
	end component;
	
	--***Multiplication units***
	
	component pre_norm_mul is
	port(
			 clk_i		  : in std_logic;
			 opa_i			: in std_logic_vector(31 downto 0);
			 opb_i			: in std_logic_vector(31 downto 0);
			 exp_10_o			: out std_logic_vector(9 downto 0);
			 fracta_24_o		: out std_logic_vector(23 downto 0);	-- hidden(1) & fraction(23)
			 fractb_24_o		: out std_logic_vector(23 downto 0)
		);
	end component;
	
	component mul_24 is
	port(
			 clk_i 			  : in std_logic;
			 fracta_i			: in std_logic_vector(23 downto 0); -- hidden(1) & fraction(23)
			 fractb_i			: in std_logic_vector(23 downto 0);
			 signa_i 			: in std_logic;
			 signb_i 			: in std_logic;
			 start_i			: in std_logic;
			 fract_o			: out std_logic_vector(47 downto 0);
			 sign_o 			: out std_logic;
			 ready_o			: out std_logic
			 );
	end component;
	
	component serial_mul is
	port(
			 clk_i 			  	: in std_logic;
			 fracta_i			: in std_logic_vector(FRAC_WIDTH downto 0); -- hidden(1) & fraction(23)
			 fractb_i			: in std_logic_vector(FRAC_WIDTH downto 0);
			 signa_i 			: in std_logic;
			 signb_i 			: in std_logic;
			 start_i			: in std_logic;
			 fract_o			: out std_logic_vector(2*FRAC_WIDTH+1 downto 0);
			 sign_o 			: out std_logic;
			 ready_o			: out std_logic
			 );
	end component;
	
	component post_norm_mul is
	port(
			 clk_i		  		: in std_logic;
			 opa_i					: in std_logic_vector(31 downto 0);
			 opb_i					: in std_logic_vector(31 downto 0);
			 exp_10_i			: in std_logic_vector(9 downto 0);
			 fract_48_i		: in std_logic_vector(47 downto 0);	-- hidden(1) & fraction(23)
			 sign_i					: in std_logic;
			 rmode_i			: in std_logic_vector(1 downto 0);
			 output_o				: out std_logic_vector(31 downto 0);
			 ine_o					: out std_logic
		);
	end component;
	
	--***Division units***
	
	component pre_norm_div is
	port(
			 clk_i		  	: in std_logic;
			 opa_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			 opb_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			 exp_10_o		: out std_logic_vector(EXP_WIDTH+1 downto 0);
			 dvdnd_50_o		: out std_logic_vector(2*(FRAC_WIDTH+2)-1 downto 0); 
			 dvsor_27_o		: out std_logic_vector(FRAC_WIDTH+3 downto 0)
		);
	end component;
	
	component serial_div is
	port(
			 clk_i 			  	: in std_logic;
			 dvdnd_i			: in std_logic_vector(2*(FRAC_WIDTH+2)-1 downto 0); -- hidden(1) & fraction(23)
			 dvsor_i			: in std_logic_vector(FRAC_WIDTH+3 downto 0);
			 sign_dvd_i 		: in std_logic;
			 sign_div_i 		: in std_logic;
			 start_i			: in std_logic;
			 ready_o			: out std_logic;
			 qutnt_o			: out std_logic_vector(FRAC_WIDTH+3 downto 0);
			 rmndr_o			: out std_logic_vector(FRAC_WIDTH+3 downto 0);
			 sign_o 			: out std_logic;
			 div_zero_o			: out std_logic
			 );
	end component;	
	
	component post_norm_div is
	port(
			 clk_i		  		: in std_logic;
			 opa_i				: in std_logic_vector(FP_WIDTH-1 downto 0);
			 opb_i				: in std_logic_vector(FP_WIDTH-1 downto 0);
			 qutnt_i			: in std_logic_vector(FRAC_WIDTH+3 downto 0);
			 rmndr_i			: in std_logic_vector(FRAC_WIDTH+3 downto 0);
			 exp_10_i			: in std_logic_vector(EXP_WIDTH+1 downto 0);
			 sign_i				: in std_logic;
			 rmode_i			: in std_logic_vector(1 downto 0);
			 output_o			: out std_logic_vector(FP_WIDTH-1 downto 0);
			 ine_o				: out std_logic
		);
	end component;	
	
	
	--***Square units***
	
	component pre_norm_sqrt is
		port(
			 clk_i		  : in std_logic;
			 opa_i			: in std_logic_vector(31 downto 0);
			 fracta_52_o		: out std_logic_vector(51 downto 0);
			 exp_o				: out std_logic_vector(7 downto 0));
	end component;
	
	component sqrt is
		generic	(RD_WIDTH: integer; SQ_WIDTH: integer); -- SQ_WIDTH = RD_WIDTH/2 (+ 1 if odd)
		port(
			 clk_i 			 : in std_logic;
			 rad_i			: in std_logic_vector(RD_WIDTH-1 downto 0); -- hidden(1) & fraction(23)
			 start_i			: in std_logic;
			 ready_o			: out std_logic;
			 sqr_o			: out std_logic_vector(SQ_WIDTH-1 downto 0);
			 ine_o			: out std_logic);
	end component;
	
	
	component post_norm_sqrt is
	port(	 clk_i		  		: in std_logic;
			 opa_i					: in std_logic_vector(31 downto 0);
			 fract_26_i		: in std_logic_vector(25 downto 0);	-- hidden(1) & fraction(11)
			 exp_i				: in std_logic_vector(7 downto 0);
			 ine_i				: in std_logic;
			 rmode_i			: in std_logic_vector(1 downto 0);
			 output_o				: out std_logic_vector(31 downto 0);
			 ine_o					: out std_logic);
	end component;
	
		
end comppack;-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: multiplication entity for the multiplication unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.fpupack.all;

entity mul_24 is
	port(
			 clk_i 			  	: in std_logic;
			 fracta_i			: in std_logic_vector(FRAC_WIDTH downto 0); -- hidden(1) & fraction(23)
			 fractb_i			: in std_logic_vector(FRAC_WIDTH downto 0);
			 signa_i 			: in std_logic;
			 signb_i 			: in std_logic;
			 start_i			: in std_logic;
			 fract_o			: out std_logic_vector(2*FRAC_WIDTH+1 downto 0);
			 sign_o 			: out std_logic;
			 ready_o			: out std_logic
			 );
end mul_24;

architecture rtl of mul_24 is



signal s_fracta_i, s_fractb_i : std_logic_vector(FRAC_WIDTH downto 0);
signal s_signa_i, s_signb_i, s_sign_o : std_logic;
signal s_fract_o: std_logic_vector(2*FRAC_WIDTH+1 downto 0);
signal s_start_i, s_ready_o : std_logic;

signal a_h, a_l, b_h, b_l : std_logic_vector(11 downto 0);
signal a_h_h, a_h_l, b_h_h, b_h_l, a_l_h, a_l_l, b_l_h, b_l_l : std_logic_vector(5 downto 0);

type op_6 is array (7 downto 0) of std_logic_vector(5 downto 0);
type prod_6 is array (3 downto 0) of op_6;

type prod_48 is array (4 downto 0) of std_logic_vector(47 downto 0);
type sum_24 is array (3 downto 0) of std_logic_vector(23 downto 0);

type a is array (3 downto 0) of std_logic_vector(23 downto 0);
type prod_24 is array (3 downto 0) of a;

signal prod : prod_6;
signal sum : sum_24;
signal prod_a_b : prod_48;

signal count : integer range 0 to 4;


type t_state is (waiting,busy);
signal s_state : t_state;

signal prod2 : prod_24;
begin


-- Input Register
process(clk_i)
begin
	if rising_edge(clk_i) then	
		s_fracta_i <= fracta_i;
		s_fractb_i <= fractb_i;
		s_signa_i<= signa_i;
		s_signb_i<= signb_i;
		s_start_i<=start_i;
	end if;
end process;	

-- Output Register
--process(clk_i)
--begin
--	if rising_edge(clk_i) then	
		fract_o <= s_fract_o;
		sign_o <= s_sign_o;
		ready_o<=s_ready_o;
--	end if;
--end process;


-- FSM
process(clk_i)
begin
	if rising_edge(clk_i) then
		if s_start_i ='1' then
			s_state <= busy;
			count <= 0; 
		elsif count=4 and s_state=busy then
			s_state <= waiting;
			s_ready_o <= '1';
			count <=0; 
		elsif s_state=busy then
			count <= count + 1;
		else
			s_state <= waiting;
			s_ready_o <= '0';
		end if;
	end if;	
end process;

s_sign_o <= s_signa_i xor s_signb_i;

--"000000000000"
-- A = A_h x 2^N + A_l , B = B_h x 2^N + B_l
-- A x B = A_hxB_hx2^2N + (A_h xB_l + A_lxB_h)2^N + A_lxB_l
a_h <= s_fracta_i(23 downto 12);
a_l <= s_fracta_i(11 downto 0);
b_h <= s_fractb_i(23 downto 12);
b_l <= s_fractb_i(11 downto 0);



a_h_h <= a_h(11 downto 6);
a_h_l <= a_h(5 downto 0);
b_h_h <= b_h(11 downto 6);
b_h_l <= b_h(5 downto 0);

a_l_h <= a_l(11 downto 6);
a_l_l <= a_l(5 downto 0);
b_l_h <= b_l(11 downto 6);
b_l_l <= b_l(5 downto 0);


prod(0)(0) <= a_h_h; prod(0)(1) <= b_h_h;
prod(0)(2) <= a_h_h; prod(0)(3) <= b_h_l; 
prod(0)(4) <= a_h_l; prod(0)(5) <= b_h_h;
prod(0)(6) <= a_h_l; prod(0)(7) <= b_h_l;


prod(1)(0) <= a_h_h; prod(1)(1) <= b_l_h;
prod(1)(2) <= a_h_h; prod(1)(3) <= b_l_l;
prod(1)(4) <= a_h_l; prod(1)(5) <= b_l_h;
prod(1)(6) <= a_h_l; prod(1)(7) <= b_l_l;

prod(2)(0) <= a_l_h; prod(2)(1) <= b_h_h;
prod(2)(2) <= a_l_h; prod(2)(3) <= b_h_l;
prod(2)(4) <= a_l_l; prod(2)(5) <= b_h_h;
prod(2)(6) <= a_l_l; prod(2)(7) <= b_h_l;

prod(3)(0) <= a_l_h; prod(3)(1) <= b_l_h;
prod(3)(2) <= a_l_h; prod(3)(3) <= b_l_l;
prod(3)(4) <= a_l_l; prod(3)(5) <= b_l_h;
prod(3)(6) <= a_l_l; prod(3)(7) <= b_l_l;



process(clk_i)
begin
if rising_edge(clk_i) then
	if count < 4 then
		prod2(count)(0)  <= (prod(count)(0)*prod(count)(1))&"000000000000"; 
		prod2(count)(1) <= "000000"&(prod(count)(2)*prod(count)(3))&"000000";
		prod2(count)(2) <= "000000"&(prod(count)(4)*prod(count)(5))&"000000";
		prod2(count)(3) <= "000000000000"&(prod(count)(6)*prod(count)(7));
	end if;
end if;
end process;



process(clk_i)
begin
if rising_edge(clk_i) then
	if count > 0 and s_state=busy then
		sum(count-1) <= prod2(count-1)(0) + prod2(count-1)(1) + prod2(count-1)(2) + prod2(count-1)(3);
	end if;
end if;
end process;



-- Last stage


	prod_a_b(0) <= sum(0)&"000000000000000000000000";
	prod_a_b(1) <= "000000000000"&sum(1)&"000000000000";
	prod_a_b(2) <= "000000000000"&sum(2)&"000000000000";
	prod_a_b(3) <= "000000000000000000000000"&sum(3);

	prod_a_b(4) <= prod_a_b(0) + prod_a_b(1) + prod_a_b(2) + prod_a_b(3);

	s_fract_o <= prod_a_b(4);



end rtl;

-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: post-normalization entity for the addition/subtraction unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;

entity post_norm_addsub is
	port(
			clk_i 			: in std_logic;
			opa_i 			: in std_logic_vector(FP_WIDTH-1 downto 0);
			opb_i 			: in std_logic_vector(FP_WIDTH-1 downto 0);
			fract_28_i		: in std_logic_vector(FRAC_WIDTH+4 downto 0);	-- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			exp_i			: in std_logic_vector(EXP_WIDTH-1 downto 0);
			sign_i			: in std_logic;
			fpu_op_i		: in std_logic;
			rmode_i			: in std_logic_vector(1 downto 0);
			output_o		: out std_logic_vector(FP_WIDTH-1 downto 0);
			ine_o			: out std_logic
		);
end post_norm_addsub;


architecture rtl of post_norm_addsub is


signal s_opa_i, s_opb_i 	: std_logic_vector(FP_WIDTH-1 downto 0);
signal s_fract_28_i			: std_logic_vector(FRAC_WIDTH+4 downto 0);	
signal s_exp_i				: std_logic_vector(EXP_WIDTH-1 downto 0);
signal s_sign_i				: std_logic;
signal s_fpu_op_i			: std_logic;
signal s_rmode_i			: std_logic_vector(1 downto 0);
signal s_output_o			: std_logic_vector(FP_WIDTH-1 downto 0);
signal s_ine_o 				: std_logic;
signal s_overflow			: std_logic;
	
signal s_zeros, s_shr1, s_shl1 : std_logic_vector(5 downto 0);
signal s_shr2, s_carry : std_logic;

signal s_exp10: std_logic_vector(9 downto 0);
signal s_expo9_1, s_expo9_2, s_expo9_3: std_logic_vector(EXP_WIDTH downto 0);

signal s_fracto28_1, s_fracto28_2, s_fracto28_rnd : std_logic_vector(FRAC_WIDTH+4 downto 0);

signal s_roundup : std_logic;
signal s_sticky : std_logic;

signal s_zero_fract : std_logic;	
signal s_lost : std_logic;
signal s_infa, s_infb : std_logic;
signal s_nan_in, s_nan_op, s_nan_a, s_nan_b, s_nan_sign : std_logic;
	
begin
	
	-- Input Register
	--process(clk_i)
	--begin
	--	if rising_edge(clk_i) then	
			s_opa_i <= opa_i;
			s_opb_i <= opb_i;
			s_fract_28_i <= fract_28_i;
			s_exp_i <= exp_i;
			s_sign_i <= sign_i;
			s_fpu_op_i <= fpu_op_i;
			s_rmode_i <= rmode_i;
	--	end if;
	--end process;	

	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			output_o <= s_output_o;
			ine_o <= s_ine_o;
		end if;
	end process;
	
	--*** Stage 1 ****
	-- figure out the output exponent and howmuch the fraction has to be shiftd right/left
	
	s_carry <= s_fract_28_i(27);
	

	s_zeros <= count_l_zeros(s_fract_28_i(26 downto 0)) when s_fract_28_i(27)='0' else "000000";


	s_exp10 <= ("00"&s_exp_i) + ("000000000"&s_carry) - ("0000"&s_zeros); -- negative flag & large flag & exp		

	process(clk_i)
	begin
	if rising_edge(clk_i) then
			if s_exp10(9)='1' or s_exp10="0000000000" then
				s_shr1 <= (others =>'0');
				if or_reduce(s_exp_i)/='0' then
					s_shl1 <= s_exp_i(5 downto 0) - "000001";
				else
					s_shl1 <= "000000";
				end if;
				s_expo9_1 <= "000000001";
			elsif s_exp10(8)='1' then
				s_shr1 <= (others =>'0');
				s_shl1 <= (others =>'0');
				s_expo9_1 <= "011111111";
			else
				s_shr1 <= ("00000"&s_carry);
				s_shl1 <= s_zeros;
				s_expo9_1 <= s_exp10(8 downto 0);
			end if;
	end if;
	end process;

---
	-- *** Stage 2 ***
	-- Shifting the fraction and rounding
	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_shr1 /= "000000" then
				s_fracto28_1 <= shr(s_fract_28_i, s_shr1);
			else 
				s_fracto28_1 <= shl(s_fract_28_i, s_shl1); 
			end if;
		end if;
	end process;
	
	s_expo9_2 <= s_expo9_1 - "000000001" when s_fracto28_1(27 downto 26)="00" else s_expo9_1;

	-- round
	s_sticky <='1' when s_fracto28_1(0)='1' or (s_fract_28_i(0) and s_fract_28_i(27))='1' else '0'; --check last bit, before and after right-shift
	
	s_roundup <= s_fracto28_1(2) and ((s_fracto28_1(1) or s_sticky)or s_fracto28_1(3)) when s_rmode_i="00" else -- round to nearset even
							 (s_fracto28_1(2) or s_fracto28_1(1) or s_sticky) and (not s_sign_i) when s_rmode_i="10" else -- round up
							 (s_fracto28_1(2) or s_fracto28_1(1) or s_sticky) and (s_sign_i) when s_rmode_i="11" else -- round down
							 '0'; -- round to zero(truncate = no rounding)
	
	s_fracto28_rnd <= s_fracto28_1 + "0000000000000000000000001000" when s_roundup='1' else s_fracto28_1;
	
	-- ***Stage 3***
	-- right-shift after rounding (if necessary)
	s_shr2 <= s_fracto28_rnd(27); 
	
	s_expo9_3 <= s_expo9_2 + "000000001" when s_shr2='1' and s_expo9_2 /= "011111111" else s_expo9_2;
	s_fracto28_2 <= ("0"&s_fracto28_rnd(27 downto 1)) when s_shr2='1' else s_fracto28_rnd;	
-----
	
	s_infa <= '1' when s_opa_i(30 downto 23)="11111111"  else '0';
	s_infb <= '1' when s_opb_i(30 downto 23)="11111111"  else '0';

	s_nan_a <= '1' when (s_infa='1' and or_reduce (s_opa_i(22 downto 0))='1') else '0';
	s_nan_b <= '1' when (s_infb='1' and or_reduce (s_opb_i(22 downto 0))='1') else '0';
	s_nan_in <= '1' when s_nan_a='1' or  s_nan_b='1' else '0';
	s_nan_op <= '1' when (s_infa and s_infb)='1' and (s_opa_i(31) xor (s_fpu_op_i xor s_opb_i(31)) )='1' else '0'; -- inf-inf=Nan
	
	s_nan_sign <= s_sign_i when (s_nan_a and s_nan_b)='1' else
								s_opa_i(31) when s_nan_a='1' else 
								s_opb_i(31);
								
	-- check if result is inexact;
	s_lost <= (s_shr1(0) and s_fract_28_i(0)) or (s_shr2 and s_fracto28_rnd(0)) or or_reduce(s_fracto28_2(2 downto 0));
	s_ine_o <= '1' when (s_lost or s_overflow)='1' and (s_infa or s_infb)='0' else '0';	
	
	s_overflow <='1' when s_expo9_3="011111111" and (s_infa or s_infb)='0' else '0'; 
	s_zero_fract <= '1' when s_zeros=27 and s_fract_28_i(27)='0' else '0'; -- '1' if fraction result is zero
								
	process(s_sign_i, s_expo9_3, s_fracto28_2, s_nan_in, s_nan_op, s_nan_sign, s_infa, s_infb, s_overflow, s_zero_fract)
	begin
		if (s_nan_in or s_nan_op)='1' then
			s_output_o <= s_nan_sign & QNAN;
		elsif (s_infa or s_infb)='1' or s_overflow='1' then
				s_output_o <= s_sign_i & INF;	
		elsif s_zero_fract='1' then
				s_output_o <= s_sign_i & ZERO_VECTOR;
		else
				s_output_o <= s_sign_i & s_expo9_3(7 downto 0) & s_fracto28_2(25 downto 3);
		end if;
	end process;

	
end rtl;
-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: post-normalization entity for the division unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;


entity post_norm_div is
	port(
			 clk_i		  		: in std_logic;
			 opa_i				: in std_logic_vector(FP_WIDTH-1 downto 0);
			 opb_i				: in std_logic_vector(FP_WIDTH-1 downto 0);
			 qutnt_i			: in std_logic_vector(FRAC_WIDTH+3 downto 0);
			 rmndr_i			: in std_logic_vector(FRAC_WIDTH+3 downto 0);
			 exp_10_i			: in std_logic_vector(EXP_WIDTH+1 downto 0);
			 sign_i				: in std_logic;
			 rmode_i			: in std_logic_vector(1 downto 0);
			 output_o			: out std_logic_vector(FP_WIDTH-1 downto 0);
			 ine_o				: out std_logic
		);
end post_norm_div;

architecture rtl of post_norm_div is


-- input&output register signals
signal s_opa_i, s_opb_i : std_logic_vector(FP_WIDTH-1 downto 0);
signal s_expa, s_expb : std_logic_vector(EXP_WIDTH-1 downto 0);
signal s_qutnt_i, s_rmndr_i : std_logic_vector(FRAC_WIDTH+3 downto 0);
signal s_r_zeros	: std_logic_vector(5 downto 0);
signal s_exp_10_i			: std_logic_vector(EXP_WIDTH+1 downto 0);
signal s_sign_i 			: std_logic;
signal s_rmode_i			: std_logic_vector(1 downto 0);
signal s_output_o			 : std_logic_vector(FP_WIDTH-1 downto 0);
signal s_ine_o, s_overflow : std_logic;

signal s_opa_dn, s_opb_dn : std_logic; 
signal s_qutdn : std_logic;

signal s_exp_10b : std_logic_vector(9 downto 0);
signal s_shr1, s_shl1 : std_logic_vector(5 downto 0);
signal s_shr2 : std_logic;
signal s_expo1, s_expo2, s_expo3 : std_logic_vector(8 downto 0);
signal s_fraco1 : std_logic_vector(26 downto 0);
signal s_frac_rnd, s_fraco2 : std_logic_vector(24 downto 0);
signal s_guard, s_round, s_sticky, s_roundup : std_logic;
signal s_lost : std_logic;

signal s_op_0, s_opab_0, s_opb_0 : std_logic;
signal s_infa, s_infb : std_logic;
signal s_nan_in, s_nan_op, s_nan_a, s_nan_b : std_logic;
signal s_inf_result: std_logic;

begin

	-- Input Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			s_opa_i <= opa_i;
			s_opb_i <= opb_i;	
			s_expa <= opa_i(30 downto 23);
			s_expb <= opb_i(30 downto 23);
			s_qutnt_i <= qutnt_i;
			s_rmndr_i <= rmndr_i;
			s_exp_10_i <= exp_10_i;			
			s_sign_i <= sign_i;
			s_rmode_i <= rmode_i;
		end if;
	end process;	

	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			output_o <= s_output_o;
			ine_o	<= s_ine_o;
		end if;
	end process;	 

    -- qutnt_i
    -- 26 25                    3
    -- |  |                     | 
    -- h  fffffffffffffffffffffff grs

	--*** Stage 1 ****
	-- figure out the exponent and howmuch the fraction has to be shiftd right/left
	
	s_opa_dn <= '1' when or_reduce(s_expa)='0' and or_reduce(opa_i(22 downto 0))='1' else '0';
	s_opb_dn <= '1' when or_reduce(s_expb)='0' and or_reduce(opb_i(22 downto 0))='1' else '0';

	s_qutdn <= not s_qutnt_i(26);
	

	s_exp_10b <= s_exp_10_i - ("000000000"&s_qutdn);		

	
	
	process(clk_i)
		variable v_shr, v_shl : std_logic_vector(9 downto 0); 
	begin
		if rising_edge(clk_i) then
		if s_exp_10b(9)='1' or s_exp_10b="0000000000" then
			v_shr := ("0000000001" - s_exp_10b) - s_qutdn;
			v_shl := (others =>'0');
			s_expo1 <= "000000001";
		elsif s_exp_10b(8)='1' then
			v_shr := (others =>'0');
			v_shl := (others =>'0');
			s_expo1 <= s_exp_10b(8 downto 0);
		else
			v_shr := (others =>'0');
			v_shl :=  "000000000"& s_qutdn;
			s_expo1 <= s_exp_10b(8 downto 0);
		end if;
		if  v_shr(6)='1' then
			s_shr1 <= "111111";
		else
			s_shr1 <= v_shr(5 downto 0);
		end if;
		s_shl1 <= v_shl(5 downto 0);
		end if;
	end process;
		

	-- *** Stage 2 ***
	-- Shifting the fraction and rounding
		
		
	-- shift the fraction
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_shr1 /= "000000" then
				s_fraco1 <= shr(s_qutnt_i, s_shr1);
			else 
				s_fraco1 <= shl(s_qutnt_i, s_shl1); 
			end if;
		end if;
	end process;
	
	s_expo2 <= s_expo1 - "000000001" when s_fraco1(26)='0' else s_expo1;
	

	s_r_zeros <= count_r_zeros(s_qutnt_i);

	
	s_lost <= '1' when (s_shr1+("00000"&s_shr2)) > s_r_zeros else '0';

	-- ***Stage 3***
	-- Rounding

	s_guard <= s_fraco1(2);
	s_round <= s_fraco1(1);
	s_sticky <= s_fraco1(0) or or_reduce(s_rmndr_i);
	
	s_roundup <= s_guard and ((s_round or s_sticky)or s_fraco1(3)) when s_rmode_i="00" else -- round to nearset even
				 ( s_guard or s_round or s_sticky) and (not s_sign_i) when s_rmode_i="10" else -- round up
				 ( s_guard or s_round or s_sticky) and (s_sign_i) when s_rmode_i="11" else -- round down
				 '0'; -- round to zero(truncate = no rounding)
				 	

	s_frac_rnd <= ("0"&s_fraco1(26 downto 3)) + '1' when s_roundup='1' else "0"&s_fraco1(26 downto 3);
	s_shr2 <= s_frac_rnd(24);

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_shr2='1' then
				s_expo3 <= s_expo2 + "1";
				s_fraco2 <= "0"&s_frac_rnd(24 downto 1);
			else 
				s_expo3 <= s_expo2;
				s_fraco2 <= s_frac_rnd;
			end if;
		end if;
	end process;


	---

	---***Stage 4****
	-- Output
		
	s_op_0 <= not ( or_reduce(s_opa_i(30 downto 0)) and or_reduce(s_opb_i(30 downto 0)) );
	s_opab_0 <= not ( or_reduce(s_opa_i(30 downto 0)) or or_reduce(s_opb_i(30 downto 0)) );
	s_opb_0 <= not or_reduce(s_opb_i(30 downto 0));
	
	s_infa <= '1' when s_expa="11111111"  else '0';
	s_infb <= '1' when s_expb="11111111"  else '0';

	s_nan_a <= '1' when (s_infa='1' and or_reduce (s_opa_i(22 downto 0))='1') else '0';
	s_nan_b <= '1' when (s_infb='1' and or_reduce (s_opb_i(22 downto 0))='1') else '0';
	s_nan_in <= '1' when s_nan_a='1' or  s_nan_b='1' else '0';
	s_nan_op <= '1' when (s_infa and s_infb)='1' or s_opab_0='1' else '0';-- 0 / 0, inf / inf

	s_inf_result <= '1' when (and_reduce(s_expo3(7 downto 0)) or s_expo3(8))='1' or s_opb_0='1' else '0';

	s_overflow <= '1' when s_inf_result='1'  and (s_infa or s_infb)='0' and s_opb_0='0' else '0';

	s_ine_o <= '1' when s_op_0='0' and (s_lost or or_reduce(s_fraco1(2 downto 0)) or s_overflow or or_reduce(s_rmndr_i))='1' else '0';
	
	process(s_sign_i, s_expo3, s_fraco2, s_nan_in, s_nan_op, s_infa, s_infb, s_overflow, s_inf_result, s_op_0)
	begin
		if (s_nan_in or s_nan_op)='1' then
			s_output_o <= '1' & QNAN;
		elsif (s_infa or s_infb)='1' or s_overflow='1' or s_inf_result='1' then
				s_output_o <= s_sign_i & INF;
		elsif s_op_0='1' then
				s_output_o <= s_sign_i & ZERO_VECTOR;					
		else
				s_output_o <= s_sign_i & s_expo3(7 downto 0) & s_fraco2(22 downto 0);
		end if;
	end process;

end rtl;-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: post-normalization entity for the multiplication unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;

entity post_norm_mul is
	port(
			 clk_i		  		: in std_logic;
			 opa_i				: in std_logic_vector(FP_WIDTH-1 downto 0);
			 opb_i				: in std_logic_vector(FP_WIDTH-1 downto 0);
			 exp_10_i			: in std_logic_vector(EXP_WIDTH+1 downto 0);
			 fract_48_i			: in std_logic_vector(2*FRAC_WIDTH+1 downto 0);	-- hidden(1) & fraction(23)
			 sign_i				: in std_logic;
			 rmode_i			: in std_logic_vector(1 downto 0);
			 output_o			: out std_logic_vector(FP_WIDTH-1 downto 0);
			 ine_o				: out std_logic
		);
end post_norm_mul;

architecture rtl of post_norm_mul is

signal s_expa, s_expb : std_logic_vector(EXP_WIDTH-1 downto 0);
signal s_exp_10_i : std_logic_vector(EXP_WIDTH+1 downto 0);
signal s_fract_48_i : std_logic_vector(2*FRAC_WIDTH+1 downto 0);
signal s_sign_i 			: std_logic;
signal s_output_o			 : std_logic_vector(FP_WIDTH-1 downto 0);
signal s_ine_o, s_overflow : std_logic;
signal s_opa_i, s_opb_i : std_logic_vector(FP_WIDTH-1 downto 0);
signal s_rmode_i			: std_logic_vector(1 downto 0);

signal s_zeros  : std_logic_vector(5 downto 0);
signal s_carry   : std_logic;
signal s_shr2, s_shl2 : std_logic_vector(5 downto 0);
signal s_expo1, s_expo2b : std_logic_vector(8 downto 0);
signal s_exp_10a, s_exp_10b : std_logic_vector(9 downto 0); 
signal s_frac2a : std_logic_vector(47 downto 0);

signal s_sticky, s_guard, s_round : std_logic;
signal s_roundup : std_logic;
signal s_frac_rnd, s_frac3 : std_logic_vector(24 downto 0);
signal s_shr3 : std_logic;
signal s_r_zeros : std_logic_vector(5 downto 0);
signal s_lost : std_logic;
signal s_op_0 : std_logic;
signal s_expo3 : std_logic_vector(8 downto 0);

signal s_infa, s_infb : std_logic;
signal s_nan_in, s_nan_op, s_nan_a, s_nan_b : std_logic;

begin

	-- Input Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			s_opa_i <= opa_i;
			s_opb_i <= opb_i;	
			s_expa <= opa_i(30 downto 23);
			s_expb <= opb_i(30 downto 23);
			s_exp_10_i <= exp_10_i;
			s_fract_48_i <= fract_48_i;
			s_sign_i <= sign_i;
			s_rmode_i <= rmode_i;
		end if;
	end process;	

	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			output_o <= s_output_o;
			ine_o	<= s_ine_o;
		end if;
	end process;	 

	--*** Stage 1 ****
	-- figure out the exponent and howmuch the fraction has to be shiftd right/left
	
	s_carry <= s_fract_48_i(47);
	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_fract_48_i(47)='0' then	
				s_zeros <= count_l_zeros(s_fract_48_i(46 downto 1));
			else 
				s_zeros <= "000000";
			end if;
			s_r_zeros <= count_r_zeros(s_fract_48_i);
		end if;
	end process;

	s_exp_10a <= s_exp_10_i + ("000000000"&s_carry);		
	s_exp_10b <= s_exp_10a - ("0000"&s_zeros);
	
	process(clk_i)
		variable v_shr1, v_shl1 : std_logic_vector(9 downto 0); 
	begin
	if rising_edge(clk_i) then
		if s_exp_10a(9)='1' or s_exp_10a="0000000000" then
			v_shr1 := "0000000001" - s_exp_10a + ("000000000"&s_carry);
			v_shl1 := (others =>'0');
			s_expo1 <= "000000001";
		else
			if s_exp_10b(9)='1' or s_exp_10b="0000000000" then
				v_shr1 := (others =>'0');
				v_shl1 := ("0000"&s_zeros) - s_exp_10a;
				s_expo1 <= "000000001";
			elsif s_exp_10b(8)='1' then
				v_shr1 := (others =>'0');
				v_shl1 := (others =>'0');
				s_expo1 <= "011111111";
			else
				v_shr1 := ("000000000"&s_carry);
				v_shl1 := ("0000"&s_zeros);
				s_expo1 <= s_exp_10b(8 downto 0);
			end if;
		end if;
		if  v_shr1(6)='1' then --"110000" = 48; maximal shift-right postions
	    	s_shr2 <= "111111";
	    else 
			s_shr2 <= v_shr1(5 downto 0);
		end if;
		s_shl2 <= v_shl1(5 downto 0);
		end if;
	end process;

	
	-- *** Stage 2 ***
	-- Shifting the fraction and rounding
		
		
	-- shift the fraction
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_shr2 /= "000000" then
				s_frac2a <= shr(s_fract_48_i, s_shr2);
			else 
				s_frac2a <= shl(s_fract_48_i, s_shl2); 
			end if;
		end if;
	end process;
	
	s_expo2b <= s_expo1 - "000000001" when s_frac2a(46)='0' else s_expo1;

	

	-- signals if precision was last during the right-shift above
	s_lost <= '1' when (s_shr2+("00000"&s_shr3)) > s_r_zeros else '0';
	
	
	-- ***Stage 3***
	-- Rounding

	--								   23
	--									|	
	-- 			xx00000000000000000000000grsxxxxxxxxxxxxxxxxxxxx
	-- guard bit: s_frac2a(23) (LSB of output)
    -- round bit: s_frac2a(22)
	s_guard <= s_frac2a(22);
	s_round <= s_frac2a(21);
	s_sticky <= or_reduce(s_frac2a(20 downto 0)) or s_lost;
	
	s_roundup <= s_guard and ((s_round or s_sticky)or s_frac2a(23)) when s_rmode_i="00" else -- round to nearset even
				 ( s_guard or s_round or s_sticky) and (not s_sign_i) when s_rmode_i="10" else -- round up
				 ( s_guard or s_round or s_sticky) and (s_sign_i) when s_rmode_i="11" else -- round down
				 '0'; -- round to zero(truncate = no rounding)
				 	
	
	process(clk_i)
	begin
	if rising_edge(clk_i) then
		if s_roundup='1' then 
			s_frac_rnd <= (s_frac2a(47 downto 23)) + "1"; 
		else 
			s_frac_rnd <= (s_frac2a(47 downto 23));
		end if;
	end if;
	end process;
	
	s_shr3 <= s_frac_rnd(24);


	
	s_expo3 <= s_expo2b + '1' when s_shr3='1' and s_expo2b /= "011111111" else s_expo2b;
	s_frac3 <= ("0"&s_frac_rnd(24 downto 1)) when s_shr3='1' and s_expo2b /= "011111111" else s_frac_rnd; 
	

	---***Stage 4****
	-- Output
		
	s_op_0 <= not ( or_reduce(s_opa_i(30 downto 0)) and or_reduce(s_opb_i(30 downto 0)) );
	
	s_infa <= '1' when s_expa="11111111"  else '0';
	s_infb <= '1' when s_expb="11111111"  else '0';

	s_nan_a <= '1' when (s_infa='1' and or_reduce (s_opa_i(22 downto 0))='1') else '0';
	s_nan_b <= '1' when (s_infb='1' and or_reduce (s_opb_i(22 downto 0))='1') else '0';
	s_nan_in <= '1' when s_nan_a='1' or  s_nan_b='1' else '0';
	s_nan_op <= '1' when (s_infa or s_infb)='1' and s_op_0='1' else '0';-- 0 * inf = nan


	s_overflow <= '1' when s_expo3 = "011111111" and (s_infa or s_infb)='0' else '0';

	s_ine_o <= '1' when s_op_0='0' and (s_lost or or_reduce(s_frac2a(22 downto 0)) or s_overflow)='1' else '0';
	
	process(s_sign_i, s_expo3, s_frac3, s_nan_in, s_nan_op, s_infa, s_infb, s_overflow, s_r_zeros)
	begin
		if (s_nan_in or s_nan_op)='1' then
			s_output_o <= s_sign_i & QNAN;
		elsif (s_infa or s_infb)='1' or s_overflow='1' then
				s_output_o <= s_sign_i & INF;	
		elsif s_r_zeros=48 then
				s_output_o <= s_sign_i & ZERO_VECTOR;			
		else
				s_output_o <= s_sign_i & s_expo3(7 downto 0) & s_frac3(22 downto 0);

		end if;
	end process;

end rtl;-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: post-normalization entity for the square-root unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;

entity post_norm_sqrt is
	port(	 
			clk_i		  	: in std_logic;
			opa_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			fract_26_i		: in std_logic_vector(FRAC_WIDTH+2 downto 0);	-- hidden(1) & fraction(11)
			exp_i			: in std_logic_vector(EXP_WIDTH-1 downto 0);
			ine_i			: in std_logic;
			rmode_i			: in std_logic_vector(1 downto 0);
			output_o		: out std_logic_vector(FP_WIDTH-1 downto 0);
			ine_o			: out std_logic
		);
end post_norm_sqrt;

architecture rtl of post_norm_sqrt is

signal s_expa, s_exp_i : std_logic_vector(EXP_WIDTH-1 downto 0);
signal s_fract_26_i : std_logic_vector(FRAC_WIDTH+2 downto 0);
signal s_ine_i		: std_logic;
signal s_rmode_i			: std_logic_vector(1 downto 0);
signal s_output_o	: std_logic_vector(FP_WIDTH-1 downto 0);
signal s_sign_i : std_logic;
signal s_opa_i : std_logic_vector(FP_WIDTH-1 downto 0);
signal s_ine_o : std_logic;

signal s_expo : std_logic_vector(EXP_WIDTH-1 downto 0);
signal s_fraco1 : std_logic_vector(FRAC_WIDTH+2 downto 0);

signal s_guard, s_round, s_sticky, s_roundup : std_logic;
signal s_frac_rnd : std_logic_vector(FRAC_WIDTH downto 0);


signal s_infa : std_logic;
signal s_nan_op, s_nan_a: std_logic;

begin

	-- Input Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			s_opa_i <= opa_i;	
			s_expa <= opa_i(30 downto 23);
			s_sign_i <= opa_i(31);
			s_fract_26_i <= fract_26_i;
			s_ine_i <= ine_i;
			s_exp_i <= exp_i;
			s_rmode_i <= rmode_i;
		end if;
	end process;	

	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			output_o <= s_output_o;
			ine_o <= s_ine_o;
		end if;
	end process;	 


	-- *** Stage 1 ***
	
	s_expo <= s_exp_i;
	
	s_fraco1 <= s_fract_26_i;
	

	-- ***Stage 2***
	-- Rounding
	
	s_guard <= s_fraco1(1);
	s_round <= s_fraco1(0);
	s_sticky <= s_ine_i;
	
	s_roundup <= s_guard and ((s_round or s_sticky)or s_fraco1(3)) when s_rmode_i="00" else -- round to nearset even
				 ( s_guard or s_round or s_sticky) and (not s_sign_i) when s_rmode_i="10" else -- round up
				 ( s_guard or s_round or s_sticky) and (s_sign_i) when s_rmode_i="11" else -- round down
				 '0'; -- round to zero(truncate = no rounding)
				 	
	process(clk_i)
	begin
	if rising_edge(clk_i) then
		if s_roundup='1' then 
			s_frac_rnd <= s_fraco1(25 downto 2) + '1'; 
		else 
			s_frac_rnd <= s_fraco1(25 downto 2);
		end if;
	end if;
	end process;
	
	
	
	-- ***Stage 3***
	-- Output
	
	s_infa <= '1' when s_expa="11111111"  else '0';
	s_nan_a <= '1' when (s_infa='1' and or_reduce (s_opa_i(22 downto 0))='1') else '0';
	s_nan_op <= '1' when s_sign_i='1' and or_reduce(s_opa_i(30 downto 0))='1' else '0'; -- sqrt(-x) = NaN
	
	s_ine_o <= '1' when s_ine_i='1' and (s_infa or s_nan_a or s_nan_op)='0' else '0';
	
	process( s_nan_a, s_nan_op, s_infa, s_sign_i, s_expo, s_frac_rnd)
	begin
		if (s_nan_a or s_nan_op)='1' then
			s_output_o <= s_sign_i & QNAN;
		elsif s_infa ='1'  then
				s_output_o <= s_sign_i & INF;	
		else
				s_output_o <= s_sign_i & s_expo & s_frac_rnd(22 downto 0);

		end if;
	end process;

end rtl;-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: pre-normalization entity for the addition/subtraction unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;

entity pre_norm_addsub is
	port(
			clk_i 			: in std_logic;
			opa_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			opb_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			fracta_28_o		: out std_logic_vector(FRAC_WIDTH+4 downto 0);	-- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			fractb_28_o		: out std_logic_vector(FRAC_WIDTH+4 downto 0);
			exp_o			: out std_logic_vector(EXP_WIDTH-1 downto 0)
		);
end pre_norm_addsub;


architecture rtl of pre_norm_addsub is


	signal s_exp_o : std_logic_vector(EXP_WIDTH-1 downto 0);
	signal s_fracta_28_o, s_fractb_28_o : std_logic_vector(FRAC_WIDTH+4 downto 0);
	signal s_expa, s_expb : std_logic_vector(EXP_WIDTH-1 downto 0);
	signal s_fracta, s_fractb : std_logic_vector(FRAC_WIDTH-1 downto 0);
	
	signal s_fracta_28, s_fractb_28, s_fract_sm_28, s_fract_shr_28 : std_logic_vector(FRAC_WIDTH+4 downto 0);
	
	signal s_exp_diff : std_logic_vector(EXP_WIDTH-1 downto 0);
	signal s_rzeros : std_logic_vector(5 downto 0);

	signal s_expa_eq_expb : std_logic;
	signal s_expa_lt_expb : std_logic;
	signal s_fracta_1 : std_logic;
	signal s_fractb_1 : std_logic;
	signal s_op_dn,s_opa_dn, s_opb_dn : std_logic;
	signal s_mux_diff : std_logic_vector(1 downto 0);
	signal s_mux_exp : std_logic;
	signal s_sticky : std_logic;
begin

	-- Input Register
	--process(clk_i)
	--begin
	--	if rising_edge(clk_i) then	
			s_expa <= opa_i(30 downto 23);
			s_expb <= opb_i(30 downto 23);
			s_fracta <= opa_i(22 downto 0);
			s_fractb <= opb_i(22 downto 0);
	--	end if;
	--end process;		
	
	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
		exp_o <= s_exp_o;
		fracta_28_o <= s_fracta_28_o;
		fractb_28_o <= s_fractb_28_o;	
		end if;
	end process;	
	
	s_expa_eq_expb <= '1' when s_expa = s_expb else '0';
	s_expa_lt_expb <= '1' when s_expa > s_expb else '0';
	
	-- '1' if fraction is not zero
	s_fracta_1 <= or_reduce(s_fracta);
	s_fractb_1 <= or_reduce(s_fractb); 
	
	-- opa or Opb is denormalized
	s_op_dn <= s_opa_dn or s_opb_dn; 
	s_opa_dn <= not or_reduce(s_expa);
	s_opb_dn <= not or_reduce(s_expb);
	
	-- output the larger exponent 
	s_mux_exp <= s_expa_lt_expb;
	process(clk_i)
	begin
		if rising_edge(clk_i) then	 
			case s_mux_exp is
				when '0' => s_exp_o <= s_expb;
				when '1' => s_exp_o <= s_expa;
				when others => s_exp_o <= "11111111";
			end case; 
		end if;
	end process;
	
	-- convert to an easy to handle floating-point format
	s_fracta_28 <= "01" & s_fracta & "000" when s_opa_dn='0' else "00" & s_fracta & "000";
	s_fractb_28 <= "01" & s_fractb & "000" when s_opb_dn='0' else "00" & s_fractb & "000";
	
	
	s_mux_diff <= s_expa_lt_expb & (s_opa_dn xor s_opb_dn);
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			-- calculate howmany postions the fraction will be shifted
			case s_mux_diff is
				when "00"=> s_exp_diff <= s_expb - s_expa;
				when "01"=>	s_exp_diff <= s_expb - (s_expa+"00000001");
				when "10"=> s_exp_diff <= s_expa - s_expb;
				when "11"=> s_exp_diff <= s_expa - (s_expb+"00000001");
				when others => s_exp_diff <= "11110000";
			end case;
		end if;
	end process;
	
	
	s_fract_sm_28 <= s_fracta_28 when s_expa_lt_expb='0' else s_fractb_28;
	
	-- shift-right the fraction if necessary
	s_fract_shr_28 <= shr(s_fract_sm_28, s_exp_diff);
	
	-- count the zeros from right to check if result is inexact
	s_rzeros <= count_r_zeros(s_fract_sm_28);
	s_sticky <= '1' when s_exp_diff > s_rzeros and or_reduce(s_fract_sm_28)='1' else '0';
	
	s_fracta_28_o <= s_fracta_28 when s_expa_lt_expb='1' else s_fract_shr_28(27 downto 1) & (s_sticky or s_fract_shr_28(0));
	s_fractb_28_o <= s_fractb_28 when s_expa_lt_expb='0' else s_fract_shr_28(27 downto 1) & (s_sticky or s_fract_shr_28(0));
	

end rtl;
-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: pre-normalization entity for the division unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;

entity pre_norm_div is
	port(
			 clk_i		  	: in std_logic;
			 opa_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			 opb_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			 exp_10_o		: out std_logic_vector(EXP_WIDTH+1 downto 0);
			 dvdnd_50_o		: out std_logic_vector(2*(FRAC_WIDTH+2)-1 downto 0); 
			 dvsor_27_o		: out std_logic_vector(FRAC_WIDTH+3 downto 0)
		);
end pre_norm_div;

architecture rtl of pre_norm_div is


signal s_expa, s_expb : std_logic_vector(EXP_WIDTH-1 downto 0);
signal s_fracta, s_fractb : std_logic_vector(FRAC_WIDTH-1 downto 0);
signal s_dvdnd_50_o : std_logic_vector(2*(FRAC_WIDTH+2)-1 downto 0); 
signal s_dvsor_27_o : std_logic_vector(FRAC_WIDTH+3 downto 0); 
signal s_dvd_zeros, s_div_zeros: std_logic_vector(5 downto 0);
signal s_exp_10_o		: std_logic_vector(EXP_WIDTH+1 downto 0);

signal s_expa_in, s_expb_in	: std_logic_vector(EXP_WIDTH+1 downto 0);
signal s_opa_dn, s_opb_dn : std_logic;
signal s_fracta_24, s_fractb_24 : std_logic_vector(FRAC_WIDTH downto 0);

begin

		s_expa <= opa_i(30 downto 23);
		s_expb <= opb_i(30 downto 23);
		s_fracta <= opa_i(22 downto 0);
		s_fractb <= opb_i(22 downto 0);
		dvdnd_50_o <= s_dvdnd_50_o;
		dvsor_27_o	<= s_dvsor_27_o;
	
	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			exp_10_o <= s_exp_10_o;
		end if;
	end process;
 
 
	s_opa_dn <= not or_reduce(s_expa);
	s_opb_dn <= not or_reduce(s_expb);
	
	s_fracta_24 <= (not s_opa_dn) & s_fracta;
	s_fractb_24 <= (not s_opb_dn) & s_fractb;
	
	-- count leading zeros
	s_dvd_zeros <= count_l_zeros( s_fracta_24 );
	s_div_zeros <= count_l_zeros( s_fractb_24 );
	
	-- left-shift the dividend and divisor
	s_dvdnd_50_o <= shl(s_fracta_24, s_dvd_zeros) & "00000000000000000000000000";
	s_dvsor_27_o <= "000" & shl(s_fractb_24, s_div_zeros);
	

	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			-- pre-calculate exponent
			s_expa_in <= ("00"&s_expa) + ("000000000"&s_opa_dn);
			s_expb_in <= ("00"&s_expb) + ("000000000"&s_opb_dn);	
			s_exp_10_o <= s_expa_in - s_expb_in + "0001111111" -("0000"&s_dvd_zeros) + ("0000"&s_div_zeros);
		end if;
	end process;		
		



end rtl;
-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: pre-normalization entity for the multiplication unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;

entity pre_norm_mul is
	port(
			 clk_i		  : in std_logic;
			 opa_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			 opb_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			 exp_10_o			: out std_logic_vector(EXP_WIDTH+1 downto 0);
			 fracta_24_o		: out std_logic_vector(FRAC_WIDTH downto 0);	-- hidden(1) & fraction(23)
			 fractb_24_o		: out std_logic_vector(FRAC_WIDTH downto 0)
		);
end pre_norm_mul;

architecture rtl of pre_norm_mul is

signal s_expa, s_expb : std_logic_vector(EXP_WIDTH-1 downto 0);
signal s_fracta, s_fractb : std_logic_vector(FRAC_WIDTH-1 downto 0);
signal s_exp_10_o, s_expa_in, s_expb_in : std_logic_vector(EXP_WIDTH+1 downto 0);

signal s_opa_dn, s_opb_dn : std_logic;

begin

	
		s_expa <= opa_i(30 downto 23);
		s_expb <= opb_i(30 downto 23);
		s_fracta <= opa_i(22 downto 0);
		s_fractb <= opb_i(22 downto 0);

 	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			exp_10_o <= s_exp_10_o;
		end if;
	end process;
	
	-- opa or opb is denormalized
	s_opa_dn <= not or_reduce(s_expa);
	s_opb_dn <= not or_reduce(s_expb);
	
	
	fracta_24_o <= not(s_opa_dn) & s_fracta;
	fractb_24_o <= not(s_opb_dn) & s_fractb;

	s_expa_in <= ("00"&s_expa) + ("000000000"&s_opa_dn);
	s_expb_in <= ("00"&s_expb) + ("000000000"&s_opb_dn);

	

	s_exp_10_o <= s_expa_in + s_expb_in - "0001111111";		



end rtl;
-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: pre-normalization entity for the square-root unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;

entity pre_norm_sqrt is
	port(
			 clk_i		  	: in std_logic;
			 opa_i			: in std_logic_vector(FP_WIDTH-1 downto 0);
			 fracta_52_o	: out std_logic_vector(2*(FRAC_WIDTH+3)-1 downto 0);
			 exp_o			: out std_logic_vector(EXP_WIDTH-1 downto 0)
		);
end pre_norm_sqrt;

architecture rtl of pre_norm_sqrt is

signal s_expa : std_logic_vector(EXP_WIDTH-1 downto 0);
signal s_exp_o, s_exp_tem : std_logic_vector(EXP_WIDTH downto 0);
signal s_fracta : std_logic_vector(FRAC_WIDTH-1 downto 0);
signal s_fracta_24 : std_logic_vector(FRAC_WIDTH downto 0);
signal s_fracta_52_o, s_fracta1_52_o, s_fracta2_52_o : std_logic_vector(2*(FRAC_WIDTH+3)-1 downto 0);
signal s_sqr_zeros_o : std_logic_vector(5 downto 0);


signal s_opa_dn : std_logic;

begin

	s_expa <= opa_i(30 downto 23);
	s_fracta <= opa_i(22 downto 0);


	exp_o <= s_exp_o(7 downto 0);
	fracta_52_o <= s_fracta_52_o;	

	-- opa or opb is denormalized
	s_opa_dn <= not or_reduce(s_expa);
	
	s_fracta_24 <= (not s_opa_dn) & s_fracta;
	
	-- count leading zeros
	s_sqr_zeros_o <= count_l_zeros(s_fracta_24 ); 
	
	-- adjust the exponent
	s_exp_tem <= ("0"&s_expa)+"001111111" - ("000"&s_sqr_zeros_o);
	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if or_reduce(opa_i(30 downto 0))='1' then
				s_exp_o <= ("0"&s_exp_tem(8 downto 1)); 
			else 
				s_exp_o <= "000000000";
			end if;
		end if;
	end process;

	-- left-shift the radicand	
	s_fracta1_52_o <= shl(s_fracta_24, s_sqr_zeros_o) & "0000000000000000000000000000";
	s_fracta2_52_o <= '0' & shl(s_fracta_24, s_sqr_zeros_o) & "000000000000000000000000000";
	
	s_fracta_52_o <= s_fracta1_52_o when s_expa(0)='0' else s_fracta2_52_o; 

end rtl;
-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: division entity for the division unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;


entity serial_div is
	port(
			 clk_i 			  	: in std_logic;
			 dvdnd_i			: in std_logic_vector(2*(FRAC_WIDTH+2)-1 downto 0); -- hidden(1) & fraction(23)
			 dvsor_i			: in std_logic_vector(FRAC_WIDTH+3 downto 0);
			 sign_dvd_i 		: in std_logic;
			 sign_div_i 		: in std_logic;
			 start_i			: in std_logic;
			 ready_o			: out std_logic;
			 qutnt_o			: out std_logic_vector(FRAC_WIDTH+3 downto 0);
			 rmndr_o			: out std_logic_vector(FRAC_WIDTH+3 downto 0);
			 sign_o 			: out std_logic;
			 div_zero_o			: out std_logic
		);
end serial_div;

architecture rtl of serial_div is

type t_state is (waiting,busy);

signal s_qutnt_o, s_rmndr_o : std_logic_vector(FRAC_WIDTH+3 downto 0);

signal s_dvdnd_i : std_logic_vector(2*(FRAC_WIDTH+2)-1 downto 0);
signal s_dvsor_i : std_logic_vector(FRAC_WIDTH+3 downto 0);
signal s_sign_dvd_i, s_sign_div_i, s_sign_o : std_logic;
signal s_div_zero_o : std_logic;
signal s_start_i, s_ready_o : std_logic;
signal s_state : t_state;
signal s_count : integer range 0 to FRAC_WIDTH+3;
signal s_dvd : std_logic_vector(FRAC_WIDTH+3 downto 0);

begin


-- Input Register
process(clk_i)
begin
	if rising_edge(clk_i) then	
		s_dvdnd_i <= dvdnd_i;
		s_dvsor_i <= dvsor_i;
		s_sign_dvd_i<= sign_dvd_i;
		s_sign_div_i<= sign_div_i;
		s_start_i <= start_i;
	end if;
end process;	

-- Output Register
--process(clk_i)
--begin
--	if rising_edge(clk_i) then	
		qutnt_o <= s_qutnt_o;
		rmndr_o <= s_rmndr_o;
		sign_o <= s_sign_o;	
		ready_o <= s_ready_o;
		div_zero_o <= s_div_zero_o;
--	end if;
--end process;

s_sign_o <= sign_dvd_i xor sign_div_i;
s_div_zero_o <= '1' when or_reduce(s_dvsor_i)='0' and or_reduce(s_dvdnd_i)='1' else '0';

-- FSM
process(clk_i)
begin
	if rising_edge(clk_i) then
		if s_start_i ='1' then
			s_state <= busy;
			s_count <= 26; 
		elsif s_count=0 and s_state=busy then
			s_state <= waiting;
			s_ready_o <= '1';
			s_count <=26; 
		elsif s_state=busy then
			s_count <= s_count - 1;
		else
			s_state <= waiting;
			s_ready_o <= '0';
		end if;
	end if;	
end process;


process(clk_i)
variable v_div : std_logic_vector(26 downto 0);
begin
	if rising_edge(clk_i) then
		--Reset
		if s_start_i ='1' then
			s_qutnt_o <= (others =>'0');
			s_rmndr_o <= (others =>'0');
		elsif s_state=busy then
			if s_count=26 then
				v_div := "000" & s_dvdnd_i(49 downto 26);
			else	
				v_div:= s_dvd;
			end if;
			if v_div < s_dvsor_i then 
				s_qutnt_o(s_count) <= '0';
			else
				s_qutnt_o(s_count) <= '1';
				v_div:=v_div-s_dvsor_i; 
			end if;	
			s_rmndr_o <= v_div;
			s_dvd <= v_div(25 downto 0)&'0';  			
		end if;
	end if;	
end process;

end rtl;

-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: Serial multiplication entity for the multiplication unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.fpupack.all;

entity serial_mul is
	port(
			 clk_i 			  	: in std_logic;
			 fracta_i			: in std_logic_vector(FRAC_WIDTH downto 0); -- hidden(1) & fraction(23)
			 fractb_i			: in std_logic_vector(FRAC_WIDTH downto 0);
			 signa_i 			: in std_logic;
			 signb_i 			: in std_logic;
			 start_i			: in std_logic;
			 fract_o			: out std_logic_vector(2*FRAC_WIDTH+1 downto 0);
			 sign_o 			: out std_logic;
			 ready_o			: out std_logic
			 );
end serial_mul;

architecture rtl of serial_mul is

type t_state is (waiting,busy);

signal s_fract_o: std_logic_vector(47 downto 0);

signal s_fracta_i, s_fractb_i : std_logic_vector(23 downto 0);
signal s_signa_i, s_signb_i, s_sign_o : std_logic;
signal s_start_i, s_ready_o : std_logic;
signal s_state : t_state;
signal s_count : integer range 0 to 23;
signal s_tem_prod : std_logic_vector(23 downto 0);

begin

-- Input Register
process(clk_i)
begin
	if rising_edge(clk_i) then	
		s_fracta_i <= fracta_i;
		s_fractb_i <= fractb_i;
		s_signa_i<= signa_i;
		s_signb_i<= signb_i;
		s_start_i <= start_i;
	end if;
end process;	

-- Output Register
process(clk_i)
begin
	if rising_edge(clk_i) then	
		fract_o <= s_fract_o;
		sign_o <= s_sign_o;	
		ready_o <= s_ready_o;
	end if;
end process;

s_sign_o <= signa_i xor signb_i;

-- FSM
process(clk_i)
begin
	if rising_edge(clk_i) then
		if s_start_i ='1' then
			s_state <= busy;
			s_count <= 0;
		elsif s_count=23 then
			s_state <= waiting;
			s_ready_o <= '1';
			s_count <=0;
		elsif s_state=busy then
			s_count <= s_count + 1;
		else
			s_state <= waiting;
			s_ready_o <= '0';
		end if;
	end if;	
end process;

g1: for i in 0 to 23 generate
	s_tem_prod(i) <= s_fracta_i(i) and s_fractb_i(s_count);
end generate;	

process(clk_i)
variable v_prod_shl : std_logic_vector(47 downto 0);
begin
	if rising_edge(clk_i) then
		if s_state=busy then
			v_prod_shl := shl(conv_std_logic_vector(0,24)&s_tem_prod, conv_std_logic_vector(s_count,5));
			if s_count /= 0 then
				s_fract_o <= v_prod_shl + s_fract_o;
			else	
				s_fract_o <= v_prod_shl;
			end if;
		end if;
	end if;	
end process;

end rtl;

-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: square-root entity for the square-root unit
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sqrt is
	generic	(RD_WIDTH: integer:=52; SQ_WIDTH: integer:=26); -- SQ_WIDTH = RD_WIDTH/2 (+ 1 if odd)
	port(
			 clk_i 			 : in std_logic;
			 rad_i			: in std_logic_vector(RD_WIDTH-1 downto 0); -- hidden(1) & fraction(23)
			 start_i			: in std_logic;
			 ready_o			: out std_logic;
			 sqr_o			: out std_logic_vector(SQ_WIDTH-1 downto 0);
			 ine_o			: out std_logic
		);
end sqrt;

architecture rtl of sqrt is

signal s_rad_i: std_logic_vector(RD_WIDTH-1 downto 0);
signal s_start_i, s_ready_o : std_logic;
signal s_sqr_o: std_logic_vector(RD_WIDTH-1 downto 0);
signal s_ine_o : std_logic;

constant ITERATIONS : integer:= RD_WIDTH/2; -- iterations = N/2
constant WIDTH_C : integer:= 5; -- log2(ITERATIONS)
                            							  --0000000000000000000000000000000000000000000000000000
constant CONST_B : std_logic_vector(RD_WIDTH-1 downto 0) :="0000000000000000000000000010000000000000000000000000"; -- b = 2^(N/2 - 1)
constant CONST_B_2: std_logic_vector(RD_WIDTH-1 downto 0):="0100000000000000000000000000000000000000000000000000"; -- b^2
constant CONST_C : std_logic_vector(WIDTH_C-1 downto 0):= "11010"; -- c = N/2


signal s_count : integer range 0 to ITERATIONS;

type t_state is (waiting,busy);
signal s_state : t_state;

signal b, b_2, r0, r0_2, r1, r1_2 : std_logic_vector(RD_WIDTH-1 downto 0);
signal c : std_logic_vector(WIDTH_C-1 downto 0);

	signal s_op1, s_op2, s_sum1a, s_sum1b, s_sum2a, s_sum2b : std_logic_vector(RD_WIDTH-1 downto 0);
	
begin


	-- Input Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			s_rad_i <= rad_i;
			s_start_i <= start_i;
		end if;
	end process;	
	
	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			sqr_o <= s_sqr_o(SQ_WIDTH-1 downto 0);
			ine_o <= s_ine_o;
			ready_o <= s_ready_o;
		end if;
	end process;


	-- FSM
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_start_i ='1' then
				s_state <= busy;
				s_count <= ITERATIONS; 
			elsif s_count=0 and s_state=busy then
				s_state <= waiting;
				s_ready_o <= '1';
				s_count <=ITERATIONS; 
			elsif s_state=busy then
				s_count <= s_count - 1;
			else
				s_state <= waiting;
				s_ready_o <= '0';
			end if;
		end if;	
	end process;

	process(clk_i)
	begin
		if rising_edge(clk_i) then
				if s_start_i='1' then
					b    <= CONST_B;
					b_2  <= CONST_B_2;
					c    <= CONST_C;
				else
					b   <= '0'&b(RD_WIDTH-1 downto 1); -- shr 1
					b_2 <= "00"&b_2(RD_WIDTH-1 downto 2);-- shr 2	
					c <= c - '1';
				end if;
		end if;
	end process;
	

	
	s_op1 <= r0_2 + b_2;
	s_op2 <= shl(r0, c);
	s_sum1a <= "00000000000000000000000000"& (r0(25 downto 0) - b(25 downto 0));
	s_sum2a <= "00000000000000000000000000"& (r0(25 downto 0) + b(25 downto 0));
	s_sum1b <= s_op1 - s_op2;
	s_sum2b <= s_op1 + s_op2;	



	process(clk_i)
		variable v_r1, v_r1_2 : std_logic_vector(RD_WIDTH-1 downto 0);
	begin
		if rising_edge(clk_i) then
				if s_start_i='1' then
					r0   <= (others =>'0');
					r0_2 <= (others =>'0');
				elsif s_state=busy then
					if r0_2 > s_rad_i then
						v_r1 := s_sum1a;
						v_r1_2 := s_sum1b;
					else
						v_r1 := s_sum2a;
						v_r1_2 := s_sum2b;				
					end if;
					r0 <= v_r1;
					r0_2 <= v_r1_2;
					r1 <= v_r1;
					r1_2 <= v_r1_2;
				end if;
		end if;
	end process;
	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_start_i = '1' then
				s_sqr_o <= (others =>'0');
			elsif s_count=0 then
						if r1_2 > s_rad_i then
							s_sqr_o <= r1 - '1';
						else
							s_sqr_o <= r1;
						end if;		
			end if;
		end if;
	end process;
	
	
	-- check if result is inexact. In this way we saved 1 clk cycle!
	process(clk_i)
		variable v_r1_2 : std_logic_vector(RD_WIDTH-1 downto 0);
	begin
		if rising_edge(clk_i) then
			v_r1_2 := r1_2 - (r1(RD_WIDTH-2 downto 0)&"0") + '1';
			if s_count=0 then				
				if r1_2 = s_rad_i or v_r1_2=s_rad_i then
					s_ine_o <= '0';
				else
					s_ine_o <= '1';
				end if;
			end if;
			
		end if;
	end process;				
	
end rtl;-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: top entity
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.comppack.all;
use work.fpupack.all;


entity fpu is
    port (
        clk_i 			: in std_logic;

        -- Input Operands A & B
        opa_i        	: in std_logic_vector(FP_WIDTH-1 downto 0);  -- Default: FP_WIDTH=32 
        opb_i           : in std_logic_vector(FP_WIDTH-1 downto 0);
        
        -- fpu operations (fpu_op_i):
		-- ========================
		-- 000 = add, 
		-- 001 = substract, 
		-- 010 = multiply, 
		-- 011 = divide,
		-- 100 = square root
		-- 101 = unused
		-- 110 = unused
		-- 111 = unused
        fpu_op_i		: in std_logic_vector(2 downto 0);
        
        -- Rounding Mode: 
        -- ==============
        -- 00 = round to nearest even(default), 
        -- 01 = round to zero, 
        -- 10 = round up, 
        -- 11 = round down
        rmode_i 		: in std_logic_vector(1 downto 0);
        
        -- Output port   
        output_o        : out std_logic_vector(FP_WIDTH-1 downto 0);
        
        -- Control signals
        start_i			: in std_logic; -- is also restart signal
        ready_o 		: out std_logic;
        
        -- Exceptions
        ine_o 			: out std_logic; -- inexact
        overflow_o  	: out std_logic; -- overflow
        underflow_o 	: out std_logic; -- underflow
        div_zero_o  	: out std_logic; -- divide by zero
        inf_o			: out std_logic; -- infinity
        zero_o			: out std_logic; -- zero
        qnan_o			: out std_logic; -- queit Not-a-Number
        snan_o			: out std_logic -- signaling Not-a-Number
	);   
end fpu;

architecture rtl of fpu is
    

	constant MUL_SERIAL: integer range 0 to 1 := 0; -- 0 for parallel multiplier, 1 for serial
	constant MUL_COUNT: integer:= 11; --11 for parallel multiplier, 34 for serial
		
	-- Input/output registers
	signal s_opa_i, s_opb_i : std_logic_vector(FP_WIDTH-1 downto 0);
	signal s_fpu_op_i		: std_logic_vector(2 downto 0);
	signal s_rmode_i : std_logic_vector(1 downto 0);
	signal s_output_o : std_logic_vector(FP_WIDTH-1 downto 0);
    signal s_ine_o, s_overflow_o, s_underflow_o, s_div_zero_o, s_inf_o, s_zero_o, s_qnan_o, s_snan_o : std_logic;
	
	type   t_state is (waiting,busy);
	signal s_state : t_state;
	signal s_start_i : std_logic;
	signal s_count : integer;
	signal s_output1 : std_logic_vector(FP_WIDTH-1 downto 0);	
	signal s_infa, s_infb : std_logic;
	
	--	***Add/Substract units signals***

	signal prenorm_addsub_fracta_28_o, prenorm_addsub_fractb_28_o : std_logic_vector(27 downto 0);
	signal prenorm_addsub_exp_o : std_logic_vector(7 downto 0); 
	
	signal addsub_fract_o : std_logic_vector(27 downto 0); 
	signal addsub_sign_o : std_logic;
	
	signal postnorm_addsub_output_o : std_logic_vector(31 downto 0); 
	signal postnorm_addsub_ine_o : std_logic;
	
	--	***Multiply units signals***
	
	signal pre_norm_mul_exp_10 : std_logic_vector(9 downto 0);
	signal pre_norm_mul_fracta_24	: std_logic_vector(23 downto 0);
	signal pre_norm_mul_fractb_24	: std_logic_vector(23 downto 0);
	 	
	signal mul_24_fract_48 : std_logic_vector(47 downto 0);
	signal mul_24_sign	: std_logic;
	signal serial_mul_fract_48 : std_logic_vector(47 downto 0);
	signal serial_mul_sign	: std_logic;
	
	signal mul_fract_48: std_logic_vector(47 downto 0);
	signal mul_sign: std_logic;
	
	signal post_norm_mul_output	: std_logic_vector(31 downto 0);
	signal post_norm_mul_ine	: std_logic;
	
	--	***Division units signals***
	
	signal pre_norm_div_dvdnd : std_logic_vector(49 downto 0);
	signal pre_norm_div_dvsor : std_logic_vector(26 downto 0);
	signal pre_norm_div_exp	: std_logic_vector(EXP_WIDTH+1 downto 0);
	
	signal serial_div_qutnt : std_logic_vector(26 downto 0);
	signal serial_div_rmndr : std_logic_vector(26 downto 0);
	signal serial_div_sign : std_logic;
	signal serial_div_div_zero : std_logic;
	
	signal post_norm_div_output : std_logic_vector(31 downto 0);
	signal post_norm_div_ine : std_logic;
	
	--	***Square units***
	
	signal pre_norm_sqrt_fracta_o		: std_logic_vector(51 downto 0);
	signal pre_norm_sqrt_exp_o				: std_logic_vector(7 downto 0);
			 
	signal sqrt_sqr_o			: std_logic_vector(25 downto 0);
	signal sqrt_ine_o			: std_logic;

	signal post_norm_sqrt_output	: std_logic_vector(31 downto 0);
	signal post_norm_sqrt_ine_o		: std_logic;
	
	
begin
	--***Add/Substract units***
	
	i_prenorm_addsub: pre_norm_addsub
    	port map (
    	  clk_i => clk_i,
				opa_i => s_opa_i,
				opb_i => s_opb_i,
				fracta_28_o => prenorm_addsub_fracta_28_o,
				fractb_28_o => prenorm_addsub_fractb_28_o,
				exp_o=> prenorm_addsub_exp_o);
				
	i_addsub: addsub_28
		port map(
			 clk_i => clk_i, 			
			 fpu_op_i => s_fpu_op_i(0),		 
			 fracta_i	=> prenorm_addsub_fracta_28_o,	
			 fractb_i	=> prenorm_addsub_fractb_28_o,		
			 signa_i =>  s_opa_i(31),			
			 signb_i =>  s_opb_i(31),				
			 fract_o => addsub_fract_o,			
			 sign_o => addsub_sign_o);	
			 
	i_postnorm_addsub: post_norm_addsub
	port map(
		clk_i => clk_i,		
		opa_i => s_opa_i,
		opb_i => s_opb_i,	
		fract_28_i => addsub_fract_o,
		exp_i => prenorm_addsub_exp_o,
		sign_i => addsub_sign_o,
		fpu_op_i => s_fpu_op_i(0), 
		rmode_i => s_rmode_i,
		output_o => postnorm_addsub_output_o,
		ine_o => postnorm_addsub_ine_o
		);
	
	--***Multiply units***
	
	i_pre_norm_mul: pre_norm_mul
	port map(
		clk_i => clk_i,		
		opa_i => s_opa_i,
		opb_i => s_opb_i,
		exp_10_o => pre_norm_mul_exp_10,
		fracta_24_o	=> pre_norm_mul_fracta_24,
		fractb_24_o	=> pre_norm_mul_fractb_24);
			 	
	i_mul_24 : mul_24
	port map(
			 clk_i => clk_i,
			 fracta_i => pre_norm_mul_fracta_24,
			 fractb_i => pre_norm_mul_fractb_24,
			 signa_i => s_opa_i(31),
			 signb_i => s_opb_i(31),
			 start_i => start_i,
			 fract_o => mul_24_fract_48, 
			 sign_o =>	mul_24_sign,
			 ready_o => open);	
			 
	i_serial_mul : serial_mul
	port map(
			 clk_i => clk_i,
			 fracta_i => pre_norm_mul_fracta_24,
			 fractb_i => pre_norm_mul_fractb_24,
			 signa_i => s_opa_i(31),
			 signb_i => s_opb_i(31),
			 start_i => s_start_i,
			 fract_o => serial_mul_fract_48, 
			 sign_o =>	serial_mul_sign,
			 ready_o => open);	
	
	-- serial or parallel multiplier will be choosed depending on constant MUL_SERIAL
	mul_fract_48 <= mul_24_fract_48 when MUL_SERIAL=0 else serial_mul_fract_48;
	mul_sign <= mul_24_sign when MUL_SERIAL=0 else serial_mul_sign;
	
	i_post_norm_mul : post_norm_mul
	port map(
			 clk_i => clk_i,
			 opa_i => s_opa_i,
			 opb_i => s_opb_i,
			 exp_10_i => pre_norm_mul_exp_10,
			 fract_48_i	=> mul_fract_48,
			 sign_i	=> mul_sign,
			 rmode_i => s_rmode_i,
			 output_o => post_norm_mul_output,
			 ine_o => post_norm_mul_ine
			);
		
	--***Division units***
	
	i_pre_norm_div : pre_norm_div
	port map(
			 clk_i => clk_i,
			 opa_i => s_opa_i,
			 opb_i => s_opb_i,
			 exp_10_o => pre_norm_div_exp,
			 dvdnd_50_o	=> pre_norm_div_dvdnd,
			 dvsor_27_o	=> pre_norm_div_dvsor);
			 
	i_serial_div : serial_div
	port map(
			 clk_i=> clk_i,
			 dvdnd_i => pre_norm_div_dvdnd,
			 dvsor_i => pre_norm_div_dvsor,
			 sign_dvd_i => s_opa_i(31),
			 sign_div_i => s_opb_i(31),
			 start_i => s_start_i,
			 ready_o => open,
			 qutnt_o => serial_div_qutnt,
			 rmndr_o => serial_div_rmndr,
			 sign_o => serial_div_sign,
			 div_zero_o	=> serial_div_div_zero);
	
	i_post_norm_div : post_norm_div
	port map(
			 clk_i => clk_i,
			 opa_i => s_opa_i,
			 opb_i => s_opb_i,
			 qutnt_i =>	serial_div_qutnt,
			 rmndr_i => serial_div_rmndr,
			 exp_10_i => pre_norm_div_exp,
			 sign_i	=> serial_div_sign,
			 rmode_i =>	s_rmode_i,
			 output_o => post_norm_div_output,
			 ine_o => post_norm_div_ine);
			 
	
	--***Square units***

	i_pre_norm_sqrt : pre_norm_sqrt
	port map(
			 clk_i => clk_i,
			 opa_i => s_opa_i,
			 fracta_52_o => pre_norm_sqrt_fracta_o,
			 exp_o => pre_norm_sqrt_exp_o);
		
	i_sqrt: sqrt 
	generic map(RD_WIDTH=>52, SQ_WIDTH=>26) 
	port map(
			 clk_i => clk_i,
			 rad_i => pre_norm_sqrt_fracta_o, 
			 start_i => s_start_i, 
	   		 ready_o => open, 
	  		 sqr_o => sqrt_sqr_o,
			 ine_o => sqrt_ine_o);

	i_post_norm_sqrt : post_norm_sqrt
	port map(
			clk_i => clk_i,
			opa_i => s_opa_i,
			fract_26_i => sqrt_sqr_o,
			exp_i => pre_norm_sqrt_exp_o,
			ine_i => sqrt_ine_o,
			rmode_i => s_rmode_i,
			output_o => post_norm_sqrt_output,
			ine_o => post_norm_sqrt_ine_o);
			
			
			
-----------------------------------------------------------------			

	-- Input Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			s_opa_i <= opa_i;
			s_opb_i <= opb_i;
			s_fpu_op_i <= fpu_op_i;
			s_rmode_i <= rmode_i;
			s_start_i <= start_i;
		end if;
	end process;
	  
	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			output_o <= s_output_o;
			ine_o <= s_ine_o;
			overflow_o <= s_overflow_o;
			underflow_o <= s_underflow_o;
			div_zero_o <= s_div_zero_o;
			inf_o <= s_inf_o;
			zero_o <= s_zero_o;
			qnan_o <= s_qnan_o;
			snan_o <= s_snan_o;
		end if;
	end process;	

    
	-- FSM
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_start_i ='1' then
				s_state <= busy;
				s_count <= 0;
			elsif s_count=6 and ((fpu_op_i="000") or (fpu_op_i="001")) then
				s_state <= waiting;
				ready_o <= '1';
				s_count <=0;
			elsif s_count=MUL_COUNT and fpu_op_i="010" then
				s_state <= waiting;
				ready_o <= '1';
				s_count <=0;
			elsif s_count=33 and fpu_op_i="011" then
				s_state <= waiting;
				ready_o <= '1';
				s_count <=0;
			elsif s_count=33 and fpu_op_i="100" then
				s_state <= waiting;
				ready_o <= '1';
				s_count <=0;			
			elsif s_state=busy then
				s_count <= s_count + 1;
			else
				s_state <= waiting;
				ready_o <= '0';
			end if;
	end if;	
	end process;
	        
	-- Output Multiplexer
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if fpu_op_i="000" or fpu_op_i="001" then	
				s_output1 		<= postnorm_addsub_output_o;
				s_ine_o 		<= postnorm_addsub_ine_o;
			elsif fpu_op_i="010" then
				s_output1 	<= post_norm_mul_output;
				s_ine_o 		<= post_norm_mul_ine;
			elsif fpu_op_i="011" then
				s_output1 	<= post_norm_div_output;
				s_ine_o 		<= post_norm_div_ine;		
			elsif fpu_op_i="100" then
				s_output1 	<= post_norm_sqrt_output;
				s_ine_o 	<= post_norm_sqrt_ine_o;			
			else
				s_output1 	<= (others => '0');
				s_ine_o 		<= '0';
			end if;
		end if;
	end process;	

	
	s_infa <= '1' when s_opa_i(30 downto 23)="11111111"  else '0';
	s_infb <= '1' when s_opb_i(30 downto 23)="11111111"  else '0';
	

	--In round down: the subtraction of two equal numbers other than zero are always -0!!!
	process(s_output1, s_rmode_i, s_div_zero_o, s_infa, s_infb, s_qnan_o, s_snan_o, s_zero_o, s_fpu_op_i, s_opa_i, s_opb_i )
	begin
			if s_rmode_i="00" or (s_div_zero_o or (s_infa or s_infb) or s_qnan_o or s_snan_o)='1' then --round-to-nearest-even
				s_output_o <= s_output1;
			elsif s_rmode_i="01" and s_output1(30 downto 23)="11111111" then
				--In round-to-zero: the sum of two non-infinity operands is never infinity,even if an overflow occures
				s_output_o <= s_output1(31) & "1111111011111111111111111111111";
			elsif s_rmode_i="10" and s_output1(31 downto 23)="111111111" then
				--In round-up: the sum of two non-infinity operands is never negative infinity,even if an overflow occures
				s_output_o <= "11111111011111111111111111111111";
			elsif s_rmode_i="11" then
				--In round-down: a-a= -0
				if (s_fpu_op_i="000" or s_fpu_op_i="001") and s_zero_o='1' and (s_opa_i(31) or (s_fpu_op_i(0) xor s_opb_i(31)))='1' then
					s_output_o <= "1" & s_output1(30 downto 0);	
				--In round-down: the sum of two non-infinity operands is never postive infinity,even if an overflow occures
				elsif s_output1(31 downto 23)="011111111" then
					s_output_o <= "01111111011111111111111111111111";
				else
					s_output_o <= s_output1;
				end if;			
			else
				s_output_o <= s_output1;
			end if;
	end process;
		

	-- Generate Exceptions 
	s_underflow_o <= '1' when s_output1(30 downto 23)="00000000" and s_ine_o='1' else '0'; 
	s_overflow_o <= '1' when s_output1(30 downto 23)="11111111" and s_ine_o='1' else '0';
	s_div_zero_o <= serial_div_div_zero when fpu_op_i="011" else '0';
	s_inf_o <= '1' when s_output1(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
	s_zero_o <= '1' when or_reduce(s_output1(30 downto 0))='0' else '0';
	s_qnan_o <= '1' when s_output1(30 downto 0)=QNAN else '0';
    s_snan_o <= '1' when s_opa_i(30 downto 0)=SNAN or s_opb_i(30 downto 0)=SNAN else '0';


end rtl;