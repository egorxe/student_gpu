library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.M4_mul_V4_pack.all;
use work.fpupack.all;

entity M4_mul_V4 is
	port (
		rst_i : in std_logic;
		clk_i : in std_logic;

		matrix_i : in  M44;
		vector_i : in  V4;
		vector_o : out V4;

		set_i          : in  std_logic;
		start_i        : in  std_logic;
		result_ready_o : out std_logic;
		load_ready_o   : out std_logic;

		ine_o       : out std_logic; -- inexact
		overflow_o  : out std_logic; -- overflow
		underflow_o : out std_logic; -- underflow
		div_zero_o  : out std_logic; -- divide by zero
		inf_o       : out std_logic; -- infinity
		zero_o      : out std_logic; -- zero
		qnan_o      : out std_logic; -- queit Not-a-Number
		snan_o      : out std_logic  -- signaling Not-a-Number
	);
end entity M4_mul_V4;

architecture rtl of M4_mul_V4 is

	component fpu is
		port (
			clk_i : in std_logic;
			--   31|30........23|22............................0
			-- sign|exponent+127|mantissa without MSB (equals 1) 
			-- 0 01111111 00000000000000000000000 = 1
			opa_i : in std_logic_vector(FP_WIDTH-1 downto 0); -- Default: FP_WIDTH=32 
			opb_i : in std_logic_vector(FP_WIDTH-1 downto 0);
			-- 000 = add, 
			-- 001 = substract, 
			-- 010 = multiply, 
			-- 011 = divide,
			-- 100 = square root
			fpu_op_i : in std_logic_vector(2 downto 0);
			-- 00 = round to nearest even(default), 
			-- 01 = round to zero, 
			-- 10 = round up, 
			-- 11 = round down
			rmode_i : in std_logic_vector(1 downto 0);

			output_o : out std_logic_vector(FP_WIDTH-1 downto 0);

			start_i : in  std_logic; -- is also restart signal
			ready_o : out std_logic;

			ine_o       : out std_logic; -- inexact
			overflow_o  : out std_logic; -- overflow
			underflow_o : out std_logic; -- underflow
			div_zero_o  : out std_logic; -- divide by zero
			inf_o       : out std_logic; -- infinity
			zero_o      : out std_logic; -- zero
			qnan_o      : out std_logic; -- queit Not-a-Number
			snan_o      : out std_logic  -- signaling Not-a-Number
		);
	end component fpu;

	function intToSVec(intValue : integer;
			vecLength : integer
		) return std_logic_vector is
	begin
		return std_logic_vector(to_signed(intValue, vecLength));
	end function;

	function max(vecLength : integer
		) return std_logic_vector is
	begin 
		return intToSVec(-1, vecLength);
	end function;

	function zero(vecLength : integer
		) return std_logic_vector is
	begin 
		return intToSVec(0, vecLength);
	end function;

	type reg_type is record
		products_busy, sums_12_34_busy, sums_all_busy, set_i, start_i, result_ready : std_logic;
		products_ready                                                              : std_logic_vector(15 downto 0);
		sums_12_34_ready                                                            : std_logic_vector(7 downto 0);
		sums_all_ready                                                              : std_logic_vector(3 downto 0);
		matrix_i, products                                                          : M44;
		sums_12_34                                                                  : M42;
		vector_i, sums_all                                                          : V4;
	end record;

	signal reg_in, reg : reg_type := ('0', '0', '0', '0', '0', '0',
			x"0000",
			x"00",
			x"0",
			(others => (others => (others => '0'))),
			(others => (others => (others => '0'))),
			(others => (others => (others => '0'))),
			(others => (others => '0')),
			(others => (others => '0'))
	);
	signal s_products                                       : M44       := (others => (others => (others => '0')));
	signal s_sums_12_34                                     : M42       := (others => (others => (others => '0')));
	signal s_sums_all                                       : V4        := (others => (others => '0'));
	signal products_start, sums_12_34_start, sums_all_start : std_logic := '0';

	signal s_products_ready   : std_logic_vector(15 downto 0) := (others => '0');
	signal s_sums_12_34_ready : std_logic_vector(7 downto 0)  := (others => '0');
	signal s_sums_all_ready   : std_logic_vector(3 downto 0)  := (others => '0');

	signal s_ine_o       : std_logic_vector(27 downto 0) := (others => '0'); --16 + 8 + 4 = 28
	signal s_overflow_o  : std_logic_vector(27 downto 0) := (others => '0');
	signal s_underflow_o : std_logic_vector(27 downto 0) := (others => '0');
	signal s_div_zero_o  : std_logic_vector(27 downto 0) := (others => '0');
	signal s_inf_o       : std_logic_vector(27 downto 0) := (others => '0');
	signal s_zero_o      : std_logic_vector(27 downto 0) := (others => '0');
	signal s_qnan_o      : std_logic_vector(27 downto 0) := (others => '0');
	signal s_snan_o      : std_logic_vector(27 downto 0) := (others => '0');

begin

	sync : process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (rst_i = '1') then
				reg <= (products_busy => '0',
						sums_12_34_busy  => '0',
						sums_all_busy    => '0',
						set_i            => '0',
						start_i          => '0',
						result_ready     => '0',
						products_ready   => x"0000",
						sums_12_34_ready => x"00",
						sums_all_ready   => x"0",
						matrix_i         => (others => (others => (others => '0'))),
						products         => (others => (others => (others => '0'))),
						sums_12_34       => (others => (others => (others => '0'))),
						vector_i         => (others => (others => '0')),
						sums_all         => (others => (others => '0'))
				);
			else
				reg <= reg_in;
			end if;
		end if;
	end process;

	async : process (reg, start_i, set_i, rst_i, s_products_ready, s_sums_12_34_ready, s_sums_all_ready)

		variable var : reg_type := ('0', '0', '0', '0', '0', '0',
				x"0000",
				x"00",
				x"0",
				(others => (others => (others => '0'))),
				(others => (others => (others => '0'))),
				(others => (others => (others => '0'))),
				(others => (others => '0')),
				(others => (others => '0'))
		);
		variable v_products_start, v_sum_12_34_start, v_sum_all_start : std_logic;
		variable v_start_i, v_start_i_in                              : std_logic_vector(0 downto 0);

		procedure calculate(rst : in std_logic;
				is_ready_prev_in : in  std_logic_vector;
				is_ready_prev    : in  std_logic_vector;
				is_busy_in       : out std_logic;
				is_busy          : in  std_logic;
				is_ready_in      : in  std_logic_vector;
				is_ready         : in  std_logic_vector;
				start            : out std_logic
			) is
		begin
			if (rst = '1') then
				start      := '0';
				is_busy_in := '0';
			else
				if (is_busy = '0' and is_ready_prev_in = max(is_ready_prev_in'length) and is_ready_prev = zero(is_ready_prev'length)) then
					start := '1';
				else
					start := '0';
				end if;

				if (is_busy = '0' and is_ready_prev_in = max(is_ready_prev_in'length) and is_ready_prev = zero(is_ready_prev'length)) then
					is_busy_in := '1';
				elsif (is_busy = '1' and is_ready_in = max(is_ready_in'length) and is_ready = zero(is_ready'length)) then
					is_busy_in := '0';
				else
					is_busy_in := is_busy;
				end if;
			end if;
		end procedure;

	begin

		var.products_ready   := s_products_ready;
		var.sums_12_34_ready := s_sums_12_34_ready;
		var.sums_all_ready   := s_sums_all_ready;

		--input
		if (rst_i = '1') then
			var.set_i   := '0';
			var.start_i := '0';
		else
			var.set_i   := set_i;
			var.start_i := start_i;

			if (set_i = '1' and reg.set_i = '0') then
				var.matrix_i := matrix_i;
			else
				var.matrix_i := reg.matrix_i;
			end if;

			if (start_i = '1' and reg.start_i = '0') then
				var.vector_i := vector_i;
			else
				var.vector_i := reg.vector_i;
			end if;
		end if;

		--products calculation
		v_start_i_in(0) := start_i;
		v_start_i(0)    := reg.start_i;
		calculate(rst_i,
			v_start_i_in,
			v_start_i,
			var.products_busy,
			reg.products_busy,
			s_products_ready,
			reg.products_ready,
			v_products_start);

		calculate(rst_i,
			s_products_ready,
			reg.products_ready,
			var.sums_12_34_busy,
			reg.sums_12_34_busy,
			s_sums_12_34_ready,
			reg.sums_12_34_ready,
			v_sum_12_34_start);

		calculate(rst_i,
			s_sums_12_34_ready,
			reg.sums_12_34_ready,
			var.sums_all_busy,
			reg.sums_all_busy,
			s_sums_all_ready,
			reg.sums_all_ready,
			v_sum_all_start);

		var.result_ready := s_sums_all_ready(0) and s_sums_all_ready(1) and s_sums_all_ready(2) and s_sums_all_ready(3);

		if (rst_i = '1') then
			var.sums_all   := (others => (others => '0'));
			var.sums_12_34 := (others => (others => (others => '0')));
			var.products   := (others => (others => (others => '0')));
		else
			if (s_products_ready = max(s_products_ready'length) and reg.products_ready = zero(reg.products_ready'length)) then
				var.products := s_products;
			else
				var.products := reg.products;
			end if;
			if (s_sums_12_34_ready = max(s_sums_12_34_ready'length) and reg.sums_12_34_ready = zero(reg.sums_12_34_ready'length)) then
				var.sums_12_34 := s_sums_12_34;
			else
				var.sums_12_34 := reg.sums_12_34;
			end if;
			if (s_sums_all_ready = max(s_sums_all_ready'length) and reg.sums_all_ready = zero(reg.sums_all_ready'length)) then
				var.sums_all := s_sums_all;
			else
				var.sums_all := reg.sums_all;
			end if;
		end if;

		products_start   <= v_products_start;
		sums_12_34_start <= v_sum_12_34_start;
		sums_all_start   <= v_sum_all_start;
		reg_in           <= var;

	end process;

	load_ready_o   <= '1' when (reg_in.products_ready = max(reg_in.products_ready'length)) else '0';
	vector_o       <= reg_in.sums_all;
	result_ready_o <= reg_in.result_ready;

	ine_o       <= '0' when (s_ine_o = zero(s_ine_o'length)) else '1';
	overflow_o  <= '0' when (s_overflow_o = zero(s_overflow_o'length)) else '1';
	underflow_o <= '0' when (s_underflow_o = zero(s_underflow_o'length)) else '1';
	div_zero_o  <= '0' when (s_div_zero_o = zero(s_div_zero_o'length)) else '1';
	inf_o       <= '0' when (s_inf_o = zero(s_inf_o'length)) else '1';
	zero_o      <= '0' when (s_zero_o = zero(s_zero_o'length)) else '1';
	qnan_o      <= '0' when (s_qnan_o = zero(s_qnan_o'length)) else '1';
	snan_o      <= '0' when (s_snan_o = zero(s_snan_o'length)) else '1';

	multipliers_gen : for i in 0 to 15 generate
	begin
		FPU_multiplier : fpu
			port map (
				clk_i       => clk_i,
				opa_i       => reg_in.vector_i(i rem 4),
				opb_i       => reg_in.matrix_i(i/4)(i rem 4),
				fpu_op_i    => "010",
				rmode_i     => "00",
				output_o    => s_products(i/4)(i rem 4),
				start_i     => products_start,
				ready_o     => s_products_ready(i),
				ine_o       => s_ine_o(i),
				overflow_o  => s_overflow_o(i),
				underflow_o => s_underflow_o(i),
				div_zero_o  => s_div_zero_o(i),
				inf_o       => s_inf_o(i),
				zero_o      => s_zero_o(i),
				qnan_o      => s_qnan_o(i),
				snan_o      => s_snan_o(i)
			);
	end generate;

	adders_12_34_gen : for i in 0 to 7 generate
	begin
		FPU_adder_12_34 : fpu
			port map (
				clk_i       => clk_i,
				opa_i       => reg_in.products(i/2)((i rem 2)*2),
				opb_i       => reg_in.products(i/2)((i rem 2)*2 + 1),
				fpu_op_i    => "000",
				rmode_i     => "00",
				output_o    => s_sums_12_34(i/2)(i rem 2),
				start_i     => sums_12_34_start,
				ready_o     => s_sums_12_34_ready(i),
				ine_o       => s_ine_o(i + 16),
				overflow_o  => s_overflow_o(i + 16),
				underflow_o => s_underflow_o(i + 16),
				div_zero_o  => s_div_zero_o(i + 16),
				inf_o       => s_inf_o(i + 16),
				zero_o      => s_zero_o(i + 16),
				qnan_o      => s_qnan_o(i + 16),
				snan_o      => s_snan_o(i + 16)
			);
	end generate;

	adders_all_gen : for i in 0 to 3 generate
	begin
		FPU_adder_all : fpu
			port map (
				clk_i       => clk_i,
				opa_i       => reg_in.sums_12_34(i)(0),
				opb_i       => reg_in.sums_12_34(i)(1),
				fpu_op_i    => "000",
				rmode_i     => "00",
				output_o    => s_sums_all(i),
				start_i     => sums_all_start,
				ready_o     => s_sums_all_ready(i),
				ine_o       => s_ine_o(i + 16 + 8),
				overflow_o  => s_overflow_o(i + 16 + 8),
				underflow_o => s_underflow_o(i + 16 + 8),
				div_zero_o  => s_div_zero_o(i + 16 + 8),
				inf_o       => s_inf_o(i + 16 + 8),
				zero_o      => s_zero_o(i + 16 + 8),
				qnan_o      => s_qnan_o(i + 16 + 8),
				snan_o      => s_snan_o(i + 16 + 8)
			);
	end generate;

end rtl;