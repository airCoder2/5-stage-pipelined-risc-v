-- Date        : march 20, 2026
-- File        : UJ_type_extender.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a signed extender for jal 

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity UJ_type_extender is
	port(
         i_imm  : in std_logic_vector(31 downto 12);
         o_extended_imm : out std_logic_vector(31 downto 0)
        );
end entity UJ_type_extender;

architecture behavioral of UJ_type_extender is

begin
    -- if msb is 0, then extend with 0s
    -- if msb is 1, then extend with 1s
    with i_imm(31) select
        o_extended_imm <= (11b"00000000000" & i_imm(31) & i_imm(19 downto 12) & i_imm(20) & i_imm(30 downto 21) & '0') when '0',
                          (11b"11111111111" & i_imm(31) & i_imm(19 downto 12) & i_imm(20) & i_imm(30 downto 21) & '0') when '1',
                          32x"0000000" when others;
end architecture behavioral;


