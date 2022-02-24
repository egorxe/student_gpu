library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;
--use std.textio.all;
--use ieee.std_logic_textio.all;

library work;
use work.fpupack.all;
use work.gpu_pkg.all;

entity vertex_transform is
	generic (
		SCREEN_WIDTH  : integer := 640;
		SCREEN_HEIGHT : integer := 480
	);
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;

		data_i : in  vec32;
		valid_i : in std_logic; --input handshake mechanism
		ready_o : out std_logic; --input handshake mechanism

		data_o  : out vec32;
		valid_o : out std_logic;  --output handshake mechanism
		ready_i : in std_logic; --output handshake mechanism
		last_o : out std_logic --only for AXI-Stream wrapper
	);
end vertex_transform;

architecture rtl of vertex_transform is

	component M4_mul_V4 is
		port (
			rst_i          : in  std_logic;
			clk_i          : in  std_logic;
			matrix_i       : in  M44;
			vector_i       : in  V4;
			vector_o       : out V4;
			set_i          : in  std_logic;
			start_i        : in  std_logic;
			result_ready_o : out std_logic;
			load_ready_o   : out std_logic;
			ine_o          : out std_logic;
			overflow_o     : out std_logic;
			underflow_o    : out std_logic;
			div_zero_o     : out std_logic;
			inf_o          : out std_logic;
			zero_o         : out std_logic;
			qnan_o         : out std_logic;
			snan_o         : out std_logic
		);
	end component M4_mul_V4;

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

	constant model_matrix : M44 := (
			(to_slv(0.804738), to_slv(-0.310617), to_slv(0.505879), to_slv(0.0)),
			(to_slv(0.505879), to_slv(0.804738), to_slv(-0.310617), to_slv(0.0)),
			(to_slv(-0.310617), to_slv(0.505879), to_slv(0.804738), to_slv(-3.0)),
			(to_slv(0.0), to_slv(0.0), to_slv(0.0), to_slv(1.0))
		);

	constant proj_matrix : M44 := (
			(to_slv(1.810660), 	to_slv(0.0), 		to_slv(0.0), 		to_slv(0.0)),
			(to_slv(0.0), 		to_slv(2.414214), 	to_slv(0.0), 		to_slv(0.0)),
			(to_slv(0.0), 		to_slv(0.0), 		to_slv(-1.020202), 	to_slv(-0.202020)),
			(to_slv(0.0), 		to_slv(0.0), 		to_slv(-1.000000), 	to_slv(0.0))
		);

	--for test
	--constant model_matrix : M44 := (
	--	(to_slv(1.0), to_slv(0.0), to_slv(0.0), to_slv(0.0)),
	--	(to_slv(0.0), to_slv(1.0), to_slv(0.0), to_slv(0.0)),
	--	(to_slv(0.0), to_slv(0.0), to_slv(1.0), to_slv(-3.0)),
	--	(to_slv(0.0), to_slv(0.0), to_slv(0.0), to_slv(1.0))
	--	);

	--for test
	--constant proj_matrix : M44 := (
	--	(to_slv(1.0), to_slv(0.0), to_slv(0.0), to_slv(0.0)),
	--	(to_slv(0.0), to_slv(1.0), to_slv(0.0), to_slv(0.0)),
	--	(to_slv(0.0), to_slv(0.0), to_slv(1.0), to_slv(0.0)),
	--	(to_slv(0.0), to_slv(0.0), to_slv(0.0), to_slv(1.0))
	--	);

	type V3 is array (0 to 2) of vec32;
	type fpu_operation_vec is array (0 to 2) of std_logic_vector(2 downto 0);
	type module_state_type is (reading, processing, writing);
	--type input_state_type is (request, processing);
	type reg_type is record
		module_state                                                                       : module_state_type;
		mul_res_ready, mul_load_ready, reading_vertex_data, processing                     : std_logic;
		fpu_res_ready                                                                      : std_logic_vector(0 to 2);
		data_i                                                                             : vec32;
		coords                                                                             : V3;
		colors                                                                             : V4;
		w_coords                                                                           : V4;
		matrix                                                                             : M44;
		vertex_counter, vertex_data_counter, input_counter, proc_counter, veiwport_counter : integer;
		fpu_opa, fpu_opb                                                                   : V3;
		fpu_operation                                                                      : fpu_operation_vec;
		data : vec32;
	end record;

	constant zero_vec_reg : reg_type := (module_state => reading,
			mul_res_ready       => '0',
			mul_load_ready      => '0',
			fpu_res_ready       => (others => '0'),
			reading_vertex_data => '0',
			processing          => '0',
			data_i              => (others => '0'),
			coords              => (others => (others => '0')),
			colors              => (others => (others => '0')),
			w_coords            => (others => (others => '0')),
			matrix              => (others => (others => (others => '0'))),
			vertex_counter      => 0,
			vertex_data_counter => 0,
			input_counter       => 0,
			proc_counter        => 0,
			veiwport_counter    => 0,
			fpu_opa             => (others => (others => '0')),
			fpu_opb             => (others => (others => '0')),
			fpu_operation       => (others => (others => '0')),
			data => (others => '0')
		);

	signal reg_in, reg : reg_type := zero_vec_reg;

	signal s_mul_result     : V4;
	signal mul_set          : std_logic;
	signal mul_start        : std_logic;
	signal s_mul_res_ready  : std_logic;
	signal s_mul_load_ready : std_logic;

	signal fpu_result    : V3;
	signal fpu_start     : std_logic_vector(0 to 2);
	signal fpu_res_ready : std_logic_vector(0 to 2);

	signal ine_o       : std_logic_vector (3 downto 0);
	signal overflow_o  : std_logic_vector (3 downto 0);
	signal underflow_o : std_logic_vector (3 downto 0);
	signal div_zero_o  : std_logic_vector (3 downto 0);
	signal inf_o       : std_logic_vector (3 downto 0);
	signal zero_o      : std_logic_vector (3 downto 0);
	signal qnan_o      : std_logic_vector (3 downto 0);
	signal snan_o      : std_logic_vector (3 downto 0);

begin

	sync : process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (rst_i = '1') then
				reg <= zero_vec_reg;
			else
				reg <= reg_in;
			end if;
		end if;
	end process;

	async : process (reg, rst_i, valid_i, ready_i, s_mul_res_ready, s_mul_load_ready, fpu_res_ready, data_i)

		variable var : reg_type;

		procedure assign_V3_to_V4 (
				output_vec : out V4;
				input_vec  : in  V3
			) is
		begin
			assignation : for i in 0 to 2 loop
				output_vec(i) := input_vec(i);
			end loop assignation;
		end procedure;

		procedure assign_V4_to_V3(
				output_vec : out V3;
				input_vec  : in  V4
			) is
		begin
			assignation : for i in 0 to 2 loop
				output_vec(i) := input_vec(i);
			end loop assignation;
		end procedure;

	begin

		var                := reg;
		var.mul_res_ready  := s_mul_res_ready;
		var.mul_load_ready := s_mul_load_ready;
		var.fpu_res_ready  := fpu_res_ready;

		mul_start <= '0';
		mul_set   <= '0';
		fpu_start <= (others => '0');

		ready_o  <= '0';
		valid_o <= '0';
		last_o <= '0';
		data_o  <= (others => '0');

		if (rst_i = '1') then
			var := zero_vec_reg;
		else
			case (reg.module_state) is
				when reading =>
					case (reg.input_counter) is
						--request
						when 0 =>
							ready_o <= '1';
							if (valid_i = '1') then
								var.input_counter := 1;
								var.data := data_i;
							end if;

						--processing
						when 1 =>
							--if polygon vertices reading hasn't been started yet
							if (reg.reading_vertex_data = '0') then
								data_o  <= reg.data;
								valid_o <= '1';

								--let's read polygon data
								if (reg.data = GPU_PIPE_CMD_POLY_VERTEX) then
									last_o <= '1';
									--report "End of polygon \n";
								end if;
								--if (reg.data = GPU_PIPE_CMD_FRAME_END) then
								--	report "End of frame \n";
								--end if;

								if (ready_i = '1') then
									var.input_counter := 0;

									if (reg.data = GPU_PIPE_CMD_POLY_VERTEX) then
										var.reading_vertex_data := '1';
									end if;
								end if;

							--reading of polygon data
							else
								var.input_counter := 0;

								if (reg.vertex_data_counter < NCOORDS + NCOLORS - 1) then
									if (reg.vertex_data_counter < NCOORDS) then
										var.coords(reg.vertex_data_counter) := reg.data;
									else
										var.colors(reg.vertex_data_counter - NCOORDS) := reg.data;
									end if;
									var.vertex_data_counter := reg.vertex_data_counter + 1;

								else
									var.colors(reg.vertex_data_counter - NCOORDS) := reg.data;
									var.vertex_data_counter                       := 0;
									var.vertex_counter                            := reg.vertex_counter + 1;
									var.module_state                              := processing;
									if (reg.vertex_counter = NVERTICES - 1) then
										var.vertex_counter      := 0;
										var.reading_vertex_data := '0';
									end if;
								end if;
							end if;

						when others =>
							assert false report "Unidentified module_state: input_counter" severity failure;
					end case;

				when processing =>
					case (reg.proc_counter) is

						--model transform
						when 0 =>
							if (reg.processing = '0') then
								var.processing := '1';
								assign_V3_to_V4(var.w_coords, reg.coords);
								var.w_coords(3) := to_slv(1.0);
								var.matrix      := model_matrix;
								mul_start       <= '1';
								mul_set         <= '1';
							elsif (s_mul_res_ready = '1' and reg.mul_res_ready = '0') then
								var.processing   := '0';
								var.w_coords     := s_mul_result;
								var.proc_counter := 1;
							end if;

						--projection transform
						when 1 =>
							if (reg.processing = '0') then
								var.processing := '1';
								var.matrix     := proj_matrix;
								mul_start      <= '1';
								mul_set        <= '1';
							elsif (s_mul_res_ready = '1' and reg.mul_res_ready = '0') then
								var.processing   := '0';
								var.w_coords     := s_mul_result;
								var.proc_counter := 2;
							end if;

						--normalizing 
						when 2 =>
							if (reg.processing = '0') then
								var.processing := '1';
								assign_V4_to_V3(var.fpu_opa, reg.w_coords);
								var.fpu_opb       := (others => reg.w_coords(3));
								var.fpu_operation := (others => "011");
								fpu_start         <= max_vec(fpu_start'length);
							elsif (fpu_res_ready = max_vec(fpu_res_ready'length) and reg.fpu_res_ready = zero_vec(reg.fpu_res_ready'length)) then
								var.processing := '0';
								assign_V3_to_V4(var.w_coords, fpu_result);
								var.proc_counter := 3;
							end if;

						--veiwport transform
						when 3 =>
							case (reg.veiwport_counter) is
								-- +1
								when 0 =>
									if (reg.processing = '0') then
										var.processing := '1';
										assign_V4_to_V3(var.fpu_opa, reg.w_coords);
										var.fpu_opb       := (others => to_slv(tf(1.0)));
										var.fpu_operation := (others => "000");
										fpu_start         <= max_vec(fpu_start'length);
									elsif (fpu_res_ready = max_vec(fpu_res_ready'length) and reg.fpu_res_ready = zero_vec(reg.fpu_res_ready'length)) then
										var.processing := '0';
										assign_V3_to_V4(var.w_coords, fpu_result);
										var.veiwport_counter := 1;
									end if;
								-- /2
								when 1 => 
									if (reg.processing = '0') then
										var.processing := '1';
										assign_V4_to_V3(var.fpu_opa, reg.w_coords);
										var.fpu_opb       := (others => to_slv(2.0));
										var.fpu_operation := (others => "011");
										fpu_start         <= max_vec(fpu_start'length);
									elsif (fpu_res_ready = max_vec(fpu_res_ready'length) and reg.fpu_res_ready = zero_vec(reg.fpu_res_ready'length)) then
										var.processing := '0';
										assign_V3_to_V4(var.w_coords, fpu_result);
										var.veiwport_counter := 2;
									end if;
								-- *(screen_size - 1)
								when 2 => 
									if (reg.processing = '0') then
										var.processing    := '1';
										var.fpu_opa(0)    := reg.w_coords(0);
										var.fpu_opa(1)    := reg.w_coords(1);
										var.fpu_opb(0)    := to_slv(Real(SCREEN_WIDTH - 1));
										var.fpu_opb(1)    := to_slv(Real(SCREEN_HEIGHT - 1));
										var.fpu_operation := (others => "010");
										fpu_start         <= "110";
									elsif (fpu_res_ready = "110" and reg.fpu_res_ready = zero_vec(reg.fpu_res_ready'length)) then
										var.processing       := '0';
										var.w_coords(0)      := fpu_result(0);
										var.w_coords(1)      := fpu_result(1);
										var.veiwport_counter := 0;
										var.proc_counter     := 0;
										var.module_state     := writing;
									end if;
								when others =>
									assert false report "Unidentified module_state: veiwport_counter" severity failure;
							end case;

						when others =>
							assert false report "Unidentified module_state: proc_counter" severity failure;
					end case;

				when writing =>
					if (reg.vertex_data_counter < NCOORDS + 1) then
						data_o <= reg.w_coords(reg.vertex_data_counter);
						--report (real'image(to_real(reg.w_coords(reg.vertex_data_counter))) & " ");
						--if (reg.vertex_data_counter = NCOORDS) then
						--	report "\n";
						--end if;

					elsif (reg.vertex_data_counter < NCOORDS + 1 + NCOLORS) then
						data_o <= reg.colors(reg.vertex_data_counter - NCOORDS - 1);
					end if;

					if (reg.vertex_data_counter = NCOORDS + NCOLORS) then
						last_o <= '1';
					end if;

					valid_o <= '1';
					if (ready_i = '1') then
						var.vertex_data_counter := reg.vertex_data_counter + 1;

						--it's time to process next portion of data
						if (reg.vertex_data_counter = NCOORDS + NCOLORS) then
							var.module_state        := reading;
							var.vertex_data_counter := 0;
						end if;
					end if;

				when others =>
					assert false report "Unidentified module_state: module_state" severity failure;
			end case;
		end if;

		reg_in <= var;
	end process;

	M4_mul_V4_inst : M4_mul_V4
		port map (
			rst_i          => rst_i,
			clk_i          => clk_i,
			matrix_i       => reg_in.matrix,
			vector_i       => reg_in.w_coords,
			vector_o       => s_mul_result,
			set_i          => mul_set,
			start_i        => mul_start,
			result_ready_o => s_mul_res_ready,
			load_ready_o   => s_mul_load_ready,

			ine_o       => ine_o(3),
			overflow_o  => overflow_o(3),
			underflow_o => underflow_o(3),
			div_zero_o  => div_zero_o(3),
			inf_o       => inf_o(3),
			zero_o      => zero_o(3),
			qnan_o      => qnan_o(3),
			snan_o      => snan_o(3)
		);

	fpu_gen : for i in 0 to 2 generate
	begin
		fpu_inst : fpu
			port map (
				clk_i    => clk_i,
				opa_i    => reg_in.fpu_opa(i),
				opb_i    => reg_in.fpu_opb(i),
				fpu_op_i => reg_in.fpu_operation(i),
				rmode_i  => "00",
				output_o => fpu_result(i),
				start_i  => fpu_start(i),
				ready_o  => fpu_res_ready(i),

				ine_o       => ine_o(i),
				overflow_o  => overflow_o(i),
				underflow_o => underflow_o(i),
				div_zero_o  => div_zero_o(i),
				inf_o       => inf_o(i),
				zero_o      => zero_o(i),
				qnan_o      => qnan_o(i),
				snan_o      => snan_o(i)
			);
	end generate;

end architecture rtl;
