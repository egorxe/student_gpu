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

-- General usefull constants
constant ZF     : float32 := to_float(0);
constant ZERO32 : std_logic_vector(31 downto 0) := (others => '0');


------------------------------------------------------------------------
------------------------------ TYPES -----------------------------------
------------------------------------------------------------------------

subtype vec32 is std_logic_vector(31 downto 0);


------------------------------------------------------------------------
---------------------------- CONSTANTS2 --------------------------------
------------------------------------------------------------------------

-- Pipeline commands
constant GPU_PIPE_CMD_POLY_VERTEX   : vec32 := X"FFFFFF00";
constant GPU_PIPE_CMD_FRAME_END     : vec32 := X"FFFFFF01";


------------------------------------------------------------------------
---------------------------- FUNCTIONS ---------------------------------
------------------------------------------------------------------------

function tf(x : real) return float32;                                   -- alias with shorter name for real->float32
function to_slv(a : integer; size : natural) return std_logic_vector;   -- integer->std_logic_vector
function to_vec32(a : integer) return std_logic_vector;                 -- integer->std_logic_vector 32 bit
function to_vec32(a : float32) return std_logic_vector;                 -- float32->std_logic_vector 32 bit
function zero_vec(size : integer) return std_logic_vector;              -- create vector of all zeroes

function to_uint(a : std_logic_vector) return integer;                  -- std_logic_vector->unsigned integer
function to_uint(a : float32) return integer;                           -- float32->unsigned integer
function to_sint(a : std_logic_vector) return integer;                  -- std_logic_vector->signed integer

--function to_str(a : std_logic_vector) return integer;                   -- std_logic_vector->signed integer

end gpu_pkg;


------------------------------------------------------------------------
--------------------------- PACKAGE BODY -------------------------------
------------------------------------------------------------------------

package body gpu_pkg is

function tf(x : real) return float32 is
begin
    return to_float(x);
end;

function to_slv(a : integer; size : natural) return std_logic_vector is
begin
    return std_logic_vector(to_unsigned(a, size));
end;

function to_vec32(a : integer) return std_logic_vector is
begin
    return to_slv(a, 32);
end;

function to_vec32(a : float32) return std_logic_vector is
begin
    return std_logic_vector(to_unsigned(a, 32));
end;

function zero_vec(size : integer) return std_logic_vector is
begin
    return to_slv(0, size);
end;

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

end gpu_pkg;
