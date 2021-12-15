------------------------------------------------------------------------
------------------------------------------------------------------------
--
-- VHDL package for global GPU project definitions & helpers
--
------------------------------------------------------------------------
------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;


package gpu_pkg is


    ------------------------------------------------------------------------
    ---------------------------- CONSTANTS ---------------------------------
    ------------------------------------------------------------------------

    -- General useful constants
    constant ZF        : float32                       := to_float(0);
    constant ZERO32    : std_logic_vector(31 downto 0) := (others => '0');
    constant NCOORDS   : integer                       := 3;
    constant NCOLORS   : integer                       := 4;
    constant NVERTICES : integer                       := 3;

    ------------------------------------------------------------------------
    ------------------------------ TYPES -----------------------------------
    ------------------------------------------------------------------------

    subtype vec32 is std_logic_vector(31 downto 0);
    type V4 is array (0 to 3) of vec32;
    type M44 is array (0 to 3) of V4;
    type FV4 is array (0 to 3) of float32;
    type FM44 is array (0 to 3) of FV4;
    
    type rast_vertex is record
        x : float32;
        y : float32;
        z : float32;
        w : float32;
        r : float32;
        g : float32;
        b : float32;
        a : float32;
    end record;
    
    type RV is array (0 to 2) of rast_vertex;
    
    type ef is record
        x   : float32;
        y   : float32;
        a0x : float32;
        a0y : float32;
        a1x : float32;
        a1y : float32;
        a2x : float32;
        a2y : float32;
        w0  : float32;
        w1  : float32;
        w2  : float32;
        mask : integer;
    end record;

    ------------------------------------------------------------------------
    ---------------------------- CONSTANTS2 --------------------------------
    ------------------------------------------------------------------------

    -- Pipeline commands
    constant GPU_PIPE_CMD_POLY_VERTEX : vec32 := X"FFFFFF00";
    constant GPU_PIPE_CMD_FRAME_END   : vec32 := X"FFFFFF01";
    constant GPU_PIPE_CMD_FRAGMENT    : vec32 := X"FFFFFF02";
    constant PIPELINE_MAX_Z           : vec32 := X"00010000";



    ------------------------------------------------------------------------
    ---------------------------- FUNCTIONS ---------------------------------
    ------------------------------------------------------------------------

    function tf(x : real) return float32; -- alias with shorter name for real->float32

    function to_slv(a          : integer; size : natural) return std_logic_vector;      -- integer->std_logic_vector
    function to_s_slv(intValue : integer; vecLength : integer) return std_logic_vector; -- integer->std_logic_vector
    function to_slv(value      : real) return std_logic_vector;                         -- real->std_logic_vector

    function to_vec32(a        : integer) return std_logic_vector; -- integer->std_logic_vector 32 bit
    function to_vec32(a        : float32) return std_logic_vector; -- float32->std_logic_vector 32 bit

    function to_uint(a : std_logic_vector) return integer; -- std_logic_vector->unsigned integer
    function to_uint(a : float32) return integer;          -- float32->unsigned integer
    function to_sint(a : std_logic_vector) return integer; -- std_logic_vector->signed integer

    function to_real(value : std_logic_vector) return real; -- std_logic_vector->real

    function zero_vec(size     : integer) return std_logic_vector; -- create vector of all zeroes
    function max_vec(vecLength : integer) return std_logic_vector; -- create vector of all ones

    --function to_str(a : std_logic_vector) return integer;                   -- std_logic_vector->signed integer

end gpu_pkg;


------------------------------------------------------------------------
--------------------------- PACKAGE BODY -------------------------------
------------------------------------------------------------------------

package body gpu_pkg is

    ----------------------------------to float32------------------------------------------------

    function tf(x : real) return float32 is
    begin
        return to_float(x);
    end;

    ----------------------------------to std_logic_vector------------------------------------------------

    function to_slv(a : integer; size : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(a, size));
    end;

    function to_slv(value : real
        ) return std_logic_vector is
    begin
        return to_slv(tf(value));
    end function;

    function to_s_slv(intValue : integer;
            vecLength : integer
        ) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(intValue, vecLength));
    end function;

    ---------------------------------to vec32------------------------------------------------

    function to_vec32(a : integer) return std_logic_vector is
    begin
        return to_slv(a, 32);
    end;

    function to_vec32(a : float32) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(a, 32));
    end;

    ----------------------------------to integer------------------------------------------------


    function to_uint(a : std_logic_vector) return integer is
    begin
        return to_integer(unsigned(a));
    end;

    function to_uint(a : float32) return integer is
    begin
        return to_uint(to_vec32(a));
    end;

    function to_sint(a : std_logic_vector) return integer is
    begin
        return to_integer(signed(a));
    end;

    ----------------------------------to real------------------------------------------------

    function to_real(value : std_logic_vector
        ) return real is
    begin
        return to_real(to_float(value));
    end function;

    -----------------------------------helpers------------------------------------------

    function zero_vec(size : integer) return std_logic_vector is
    begin
        return to_slv(0, size);
    end;

    function max_vec(vecLength : integer
        ) return std_logic_vector is
    begin
        return to_s_slv(-1, vecLength);
    end function;

end gpu_pkg;
