--Hardware realization of edge function:
--E_01(P) = (P.x − V0.x)∗(V1.y − V0.y) − (P.y − V0.y)∗(V1.x − V0.x)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;

library work;
use work.gpu_pkg.all;
use work.fpupack.all;

entity edge_function is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;

		valid_i : in  std_logic;
        input_ready_o : out std_logic;
        result_ready_o : out std_logic;

        x_i   : in vec32;
        y_i   : in vec32;
        v0x_i : in vec32;
        v0y_i : in vec32;
        v1x_i : in vec32;
        v1y_i : in vec32;
        result_o : out vec32  
	);
end edge_function;

architecture behavioral of edge_function is

	component fpu is
		port (
			clk_i       : in  std_logic;

			opa_i       : in  vec32;
			opb_i       : in  vec32;
			fpu_op_i    : in  std_logic_vector(2 downto 0);
			rmode_i     : in  std_logic_vector(1 downto 0);
			output_o    : out vec32;

			start_i     : in  std_logic;
			ready_o     : out std_logic;

			ine_o       : out std_logic;
			overflow_o  : out std_logic;
			underflow_o : out std_logic;
			div_zero_o  : out std_logic;
			inf_o       : out std_logic;
			zero_o      : out std_logic;
			qnan_o      : out std_logic;
			snan_o      : out std_logic
		);
	end component fpu;

	function is_all_true(x : std_logic_vector
		) return boolean is
	begin
		for i in 0 to x'length - 1 loop
			if (x(i) = '0') then
				return false;
			end if;
		end loop;

		return true;
	end function;

	function is_all_false(x : std_logic_vector
		) return boolean is
	begin
		for i in 0 to x'length - 1 loop
			if (x(i) = '1') then
				return false;
			end if;
		end loop;

		return true;
	end function;

	type V2 is array (0 to 1) of vec32;

	type rec_type is record
		min1_opa, min1_opb, min1_output : V4;
		min1_ready : std_logic_vector(3 downto 0); --needed for initial conditions
		min1_buf_free : std_logic;

		mult2_opa, mult2_opb, mult2_output : V2;
		mult2_ready : std_logic_vector(1 downto 0); --needed for initial conditions
		mult2_buf_free : std_logic;

		min3_opa, min3_opb, min3_output : vec32;
		min3_ready : std_logic; --needed for initial conditions
	end record;

	constant rst_rec : rec_type := (min1_opa => (others => (others => '0')), 
									min1_opb => (others => (others => '0')), 
									min1_output => (others => (others => '0')),
									min1_ready => (others => '1'),
									min1_buf_free => '1',

									mult2_opa => (others => (others => '0')), 
									mult2_opb => (others => (others => '0')), 
									mult2_output => (others => (others => '0')),
									mult2_ready => (others => '1'),
									mult2_buf_free => '1',

									min3_opa => (others => '0'), 
									min3_opb => (others => '0'), 
									min3_output => (others => '0'),
									min3_ready => '1'
									);

	signal rec, rec_in : rec_type := rst_rec;  

	signal min1_output    	: V4;
	signal min1_start     	: std_logic;
	signal min1_ready     	: std_logic_vector(3 downto 0);

	signal mult2_output    	: V2;
	signal mult2_start     	: std_logic;
	signal mult2_ready     	: std_logic_vector(1 downto 0);

	signal min3_output    	: vec32;
	signal min3_start     	: std_logic;
	signal min3_ready     	: std_logic;

begin

	sync : process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (rst_i = '1') then
				rec <= rst_rec;

			else
				rec <= rec_in;
			end if;
		end if;
	end process;

	async : process(rec, valid_i, x_i, y_i, v0x_i, v0y_i, v1x_i, v1y_i)
		variable var : rec_type := rst_rec;

	begin
		var := rec;
		min1_start <= '0';
		mult2_start <= '0';
		min3_start <= '0';

		--substruction in brackets: 7 clock cycles

		if (valid_i = '1' and is_all_true(rec.min1_ready) and rec.min1_buf_free = '1') then
			var.min1_opa(0) := x_i;		--P.x - V0.x
			var.min1_opb(0) := v0x_i;	
			var.min1_opa(1) := v1y_i;	--V1.y - V0.y
			var.min1_opb(1) := v0y_i;
			var.min1_opa(2) := y_i;		--P.y - V0.y
			var.min1_opb(2) := v0y_i;
			var.min1_opa(3) := v1x_i;	--V1.x - V0.x
			var.min1_opb(3) := v0x_i;
			min1_start <= '1';
			var.min1_ready := (others => '0');
		end if;

		if (is_all_true(min1_ready) and is_all_false(rec.min1_ready) and rec.min1_buf_free = '1') then
			var.min1_ready := (others => '1');
			var.min1_output := min1_output;
			var.min1_buf_free := '0';
		end if;

		--multiplication: 12 clock cycles

		if (rec.min1_buf_free = '0' and is_all_true(rec.mult2_ready) and rec.mult2_buf_free = '1') then
			 var.mult2_opa(0) := rec.min1_output(0); --(P.x - V0.x)*(V1.y - V0.y)
			 var.mult2_opb(0) := rec.min1_output(1);
			 var.mult2_opa(0) := rec.min1_output(2); --(P.y - V0.y)*(V1.x - V0.x)
			 var.mult2_opb(0) := rec.min1_output(3);
			 mult2_start <= '1';
			 var.mult2_ready := (others => '0');
			 var.min1_buf_free := '1';
		end if;

		if (is_all_true(mult2_ready) and is_all_false(rec.mult2_ready) and rec.mult2_buf_free = '1') then
			var.mult2_ready := (others => '1');
			var.mult2_output := mult2_output;
			var.mult2_buf_free := '0';
		end if;

		--substraction between brackets: 7 clock cycles

		if (rec.mult2_buf_free = '0' and rec.min3_ready = '1') then
			var.min3_opa := rec.mult2_output(0);
			var.min3_opb := rec.mult2_output(1);
			min3_start <= '1';
			var.min3_ready := '0';
			var.mult2_buf_free := '1';
		end if;

		if (min3_ready = '1' and rec.min3_ready = '0') then
			var.min3_ready := '1';
			var.min3_output := min3_output;
		end if;

		result_o <= var.min3_output;
		input_ready_o <= var.mult2_ready(1) and var.mult2_ready(0);
		result_ready_o <= var.min3_ready;
		rec_in <= var;
	end process;

	min1_gen : for i in 0 to 3 generate
	begin
		fpu_min1 : fpu
			port map (
				clk_i       => clk_i,
				opa_i       => rec_in.min1_opa(i),
				opb_i       => rec_in.min1_opb(i),
				fpu_op_i    => "001",
				rmode_i     => "00",
				output_o    => min1_output(i),
				start_i     => min1_start,
				ready_o     => min1_ready(i),
				ine_o       => open,
				overflow_o  => open,
				underflow_o => open,
				div_zero_o  => open,
				inf_o       => open,
				zero_o      => open,
				qnan_o      => open,
				snan_o      => open
			);	
	end generate;

	mult2_gen : for i in 0 to 1 generate
	begin
		fpu_mult2: fpu
			port map (
				clk_i       => clk_i,
				opa_i       => rec_in.mult2_opa(i),
				opb_i       => rec_in.mult2_opb(i),
				fpu_op_i    => "010",
				rmode_i     => "00",
				output_o    => mult2_output(i),
				start_i     => mult2_start,
				ready_o     => mult2_ready(i),
				ine_o       => open,
				overflow_o  => open,
				underflow_o => open,
				div_zero_o  => open,
				inf_o       => open,
				zero_o      => open,
				qnan_o      => open,
				snan_o      => open
			);	
	end generate;

	fpu_min3: fpu
		port map (
			clk_i       => clk_i,
			opa_i       => rec_in.min3_opa,
			opb_i       => rec_in.min3_opb,
			fpu_op_i    => "001",
			rmode_i     => "00",
			output_o    => min3_output,
			start_i     => min3_start,
			ready_o     => min3_ready,
			ine_o       => open,
			overflow_o  => open,
			underflow_o => open,
			div_zero_o  => open,
			inf_o       => open,
			zero_o      => open,
			qnan_o      => open,
			snan_o      => open
		);	
	
end architecture behavioral;