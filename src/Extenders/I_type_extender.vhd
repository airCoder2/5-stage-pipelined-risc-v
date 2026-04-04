-- Date        : march 20, 2026
-- File        : I_type_extender.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 12 to 32 signed extender

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity I_type_extender is

	port(
         i_imm  : in std_logic_vector(31 downto 20);
         o_extended_imm : out std_logic_vector(31 downto 0)
        );
	
end entity I_type_extender;

architecture behavioral of I_type_extender is

begin
    -- if msb is 0, then extend with 0s
    -- if msb is 1, then extend with 1s
    with i_imm(31) select
        o_extended_imm <= (20x"00000" & i_imm) when '0',
                          (20x"FFFFF" & i_imm) when '1',
                          32x"00000000" when others;
end architecture behavioral;

