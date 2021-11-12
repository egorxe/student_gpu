library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.float_pkg.all;
    
package float_file_pkg is

subtype BinaryWord32 is std_logic_vector(31 downto 0);
type BinaryFile is file of character;

function ToChar (slv8 : std_logic_vector (7 downto 0)) return character;
procedure WriteFloat(file f : BinaryFile; x : float32);
procedure ReadFloat(file f : BinaryFile; x : out float32);

end float_file_pkg;

package body float_file_pkg is

function ToChar (slv8 : std_logic_vector (7 downto 0)) return character is
    constant XMAP : integer := 0;
    variable TEMP : integer := 0;
begin
    for i in slv8'range loop
        TEMP:=TEMP*2;
        case SLV8(i) is
            when '0' | 'L'  => null;
            when '1' | 'H'  => TEMP :=TEMP+1;
            when others     => TEMP :=TEMP+XMAP;
        end case;
    end loop;
    return character'val(TEMP);
end ToChar;

procedure WriteFloat(file f : BinaryFile; x : float32) is 
    variable v : BinaryWord32;
begin
    v := to_slv(x);
    write(f, ToChar(v(7 downto 0)));
    write(f, ToChar(v(15 downto 8)));
    write(f, ToChar(v(23 downto 16)));
    write(f, ToChar(v(31 downto 24)));
end procedure;

procedure ReadFloat(file f : BinaryFile; x : out float32) is 
    variable c : character;
    variable v : BinaryWord32;
begin
    read(f, c);
    v(7 downto 0) := std_logic_vector(to_unsigned(character'pos(c), 8));
    read(f, c);
    v(15 downto 8) := std_logic_vector(to_unsigned(character'pos(c), 8));
    read(f, c);
    v(23 downto 16) := std_logic_vector(to_unsigned(character'pos(c), 8));
    read(f, c);
    v(31 downto 24) := std_logic_vector(to_unsigned(character'pos(c), 8));
    x := to_float(v);
end procedure;

end float_file_pkg;
