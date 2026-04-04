-- Date        : March 23, 2026
-- File        : Shifter.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a barrel shifter 

library IEEE;
use IEEE.std_logic_1164.all;
USE ieee.numeric_std.ALL;


entity Shifter is
    port(
         i_data : in std_logic_vector(31 downto 0);
         i_shift_amount : in std_logic_vector(4 downto 0);
         i_logcl_arith  : in std_logic;                       -- is the shfit logical or arithmetic
         i_right_left   : in std_logic;                       -- is the shift to the right or left
         o_shifted_data : out std_logic_vector(31 downto 0)
        );
end entity Shifter;


architecture structural of Shifter is
    component Mux_32_to_1 is
        port(DATA_IN   : in std_logic_vector(31 downto 0);
             SELECT_IN : in std_logic_vector(4 downto 0);
             MUX_OUT   : out std_logic);
    end component Mux_32_to_1;

    signal s_extended_data : std_logic_vector(63 downto 0);

    type t_mux_inputs is array(0 to 31) of std_logic_vector(31 downto 0);
    signal s_data_to_mux : t_mux_inputs;

    signal s_shifter_in_mux  : std_logic_vector(31 downto 0);
    signal s_shifter_out_mux : std_logic_vector(31 downto 0);

    signal s_shifted_data    : std_logic_vector(31 downto 0);

    function mirror_bus(constant data : std_logic_vector) return std_logic_vector is

        variable result : std_logic_vector(data'range);
    begin
        -- VHDL-2008 allows reverse iteration naturally
        for i in data'range loop
            result(i) := data(data'left - (i - data'right)); -- Reverse indexing
        end loop;
        return result;
    end function;


begin 

    s_shifter_in_mux  <= i_data when i_right_left = '0' else mirror_bus(i_data);

    s_extended_data <= x"00000000" & s_shifter_in_mux; -- muxed input, if left, input is flipped

    -- Pre-compute MUX inputs for each shift amount i
    GEN_MUX_INPUTS: for i in 0 to 31 generate

        s_data_to_mux(i)(31) <= s_extended_data(31) when (i > 0  and i_logcl_arith = '1') else s_extended_data(31 + i);
        s_data_to_mux(i)(30) <= s_extended_data(31) when (i > 1  and i_logcl_arith = '1') else s_extended_data(30 + i);
        s_data_to_mux(i)(29) <= s_extended_data(31) when (i > 2  and i_logcl_arith = '1') else s_extended_data(29 + i);
        s_data_to_mux(i)(28) <= s_extended_data(31) when (i > 3  and i_logcl_arith = '1') else s_extended_data(28 + i);
        s_data_to_mux(i)(27) <= s_extended_data(31) when (i > 4  and i_logcl_arith = '1') else s_extended_data(27 + i);
        s_data_to_mux(i)(26) <= s_extended_data(31) when (i > 5  and i_logcl_arith = '1') else s_extended_data(26 + i);
        s_data_to_mux(i)(25) <= s_extended_data(31) when (i > 6  and i_logcl_arith = '1') else s_extended_data(25 + i);
        s_data_to_mux(i)(24) <= s_extended_data(31) when (i > 7  and i_logcl_arith = '1') else s_extended_data(24 + i);
        s_data_to_mux(i)(23) <= s_extended_data(31) when (i > 8  and i_logcl_arith = '1') else s_extended_data(23 + i);
        s_data_to_mux(i)(22) <= s_extended_data(31) when (i > 9  and i_logcl_arith = '1') else s_extended_data(22 + i);
        s_data_to_mux(i)(21) <= s_extended_data(31) when (i > 10 and i_logcl_arith = '1') else s_extended_data(21 + i);
        s_data_to_mux(i)(20) <= s_extended_data(31) when (i > 11 and i_logcl_arith = '1') else s_extended_data(20 + i);
        s_data_to_mux(i)(19) <= s_extended_data(31) when (i > 12 and i_logcl_arith = '1') else s_extended_data(19 + i);
        s_data_to_mux(i)(18) <= s_extended_data(31) when (i > 13 and i_logcl_arith = '1') else s_extended_data(18 + i);
        s_data_to_mux(i)(17) <= s_extended_data(31) when (i > 14 and i_logcl_arith = '1') else s_extended_data(17 + i);
        s_data_to_mux(i)(16) <= s_extended_data(31) when (i > 15 and i_logcl_arith = '1') else s_extended_data(16 + i);
        s_data_to_mux(i)(15) <= s_extended_data(31) when (i > 16 and i_logcl_arith = '1') else s_extended_data(15 + i);
        s_data_to_mux(i)(14) <= s_extended_data(31) when (i > 17 and i_logcl_arith = '1') else s_extended_data(14 + i);
        s_data_to_mux(i)(13) <= s_extended_data(31) when (i > 18 and i_logcl_arith = '1') else s_extended_data(13 + i);
        s_data_to_mux(i)(12) <= s_extended_data(31) when (i > 19 and i_logcl_arith = '1') else s_extended_data(12 + i);
        s_data_to_mux(i)(11) <= s_extended_data(31) when (i > 20 and i_logcl_arith = '1') else s_extended_data(11 + i);
        s_data_to_mux(i)(10) <= s_extended_data(31) when (i > 21 and i_logcl_arith = '1') else s_extended_data(10 + i);
        s_data_to_mux(i)(9 ) <= s_extended_data(31) when (i > 22 and i_logcl_arith = '1') else s_extended_data(9  + i);
        s_data_to_mux(i)(8 ) <= s_extended_data(31) when (i > 23 and i_logcl_arith = '1') else s_extended_data(8  + i);
        s_data_to_mux(i)(7 ) <= s_extended_data(31) when (i > 24 and i_logcl_arith = '1') else s_extended_data(7  + i);
        s_data_to_mux(i)(6 ) <= s_extended_data(31) when (i > 25 and i_logcl_arith = '1') else s_extended_data(6  + i);
        s_data_to_mux(i)(5 ) <= s_extended_data(31) when (i > 26 and i_logcl_arith = '1') else s_extended_data(5  + i);
        s_data_to_mux(i)(4 ) <= s_extended_data(31) when (i > 27 and i_logcl_arith = '1') else s_extended_data(4  + i);
        s_data_to_mux(i)(3 ) <= s_extended_data(31) when (i > 28 and i_logcl_arith = '1') else s_extended_data(3  + i);
        s_data_to_mux(i)(2 ) <= s_extended_data(31) when (i > 29 and i_logcl_arith = '1') else s_extended_data(2  + i);
        s_data_to_mux(i)(1 ) <= s_extended_data(31) when (i > 30 and i_logcl_arith = '1') else s_extended_data(1  + i);
        s_data_to_mux(i)(0 ) <= s_extended_data(31) when (i > 31 and i_logcl_arith = '1') else s_extended_data(0  + i);

    end generate GEN_MUX_INPUTS;


    -- Instantiate one MUX per output bit
    Shifter_Mux: for i in 0 to 31 generate
        MUXI: Mux_32_to_1 port map(
            DATA_IN   => s_data_to_mux(i),
            SELECT_IN => i_shift_amount,
            MUX_OUT   => s_shifted_data(i)
        );
    end generate Shifter_Mux;

    o_shifted_data <= s_shifted_data when i_right_left = '0' else mirror_bus(s_shifted_data);

end architecture structural;


