-- Demo stage which shows a way to work with in & out FIFOs (data part)

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.float_pkg.all;
    
use work.gpu_pkg.all;
    
entity test_vertices is
    generic (
        SCREEN_WIDTH    : integer;
        SCREEN_HEIGHT   : integer
    );
    port (
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;
        
        data_i      : in  vec32;
        stb_i       : in  std_logic;
        
        data_o      : out vec32;
        stb_o       : out std_logic
    );
end test_vertices;

architecture arch of test_vertices is

constant NCOORDS        : integer := 3;
constant NCOLORS        : integer := 4;
constant NVERTEXES      : integer := 3;
type coord_array is array (0 to NCOORDS-1) of float32;  -- coords of one vertex
type color_array is array (0 to NCOLORS-1) of float32;  -- colors of one vertex
type vertex_coord_array is array (0 to NVERTEXES-1) of coord_array;  -- coords of all vertexes
type vertex_color_array is array (0 to NVERTEXES-1) of color_array;  -- colors of all vertexes

constant CONST_VERTEX_COORDS : vertex_coord_array := (
    (tf(0.2), tf(0.2), tf(0.5)),
    (tf(0.2), tf(0.8), tf(0.5)),
    (tf(0.8), tf(0.8), tf(0.5))
    );

constant CONST_VERTEX_COLORS : vertex_color_array := (
    (tf(1.0), tf(0.0), tf(0.0), tf(1.0)),
    (tf(0.0), tf(1.0), tf(0.0), tf(1.0)),
    (tf(0.0), tf(0.0), tf(1.0), tf(1.0))
    );
    
signal stb    : std_logic;

begin

stb_o <= stb;

-- Send vertices from array every clock
process(clk_i)
    variable vert   : integer;
    variable coord  : integer;
    variable color  : integer;
    variable new_frame  : std_logic;
begin
    if Rising_edge(clk_i) then
        if rst_i = '1' then
            vert    := 0;
            coord   := 0;
            color   := 0;
            stb     <= '0';
            new_frame     := '1';
        else
            if (stb = '0') then
                stb     <= '1';
                
                if (new_frame = '1') then
                    data_o <= GPU_PIPE_CMD_POLY_VERTEX;
                    new_frame := '0';
                else
                    if coord /= NCOORDS then
                        data_o  <= to_slv(CONST_VERTEX_COORDS(vert)(coord));
                        coord := coord + 1;
                    elsif color /= NCOLORS then
                        data_o  <= to_slv(CONST_VERTEX_COLORS(vert)(color));
                        color := color + 1;
                    else
                        coord   := 0;
                        color   := 0;
                        if vert /= NVERTEXES-1 then
                            vert := vert + 1;
                            stb <= '0';
                        else
                            vert := 0;
                            data_o <= GPU_PIPE_CMD_FRAME_END;
                            new_frame := '1';
                        end if;
                    end if;
                end if;
            else
                stb <= '0';
            end if;
        end if;
    end if;
end process;

end arch;
