-- Date        : march 20, 2026
-- File        : SB_type_extender.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a signed extender for branch instructions

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity SB_type_extender is
	port(
         i_imm_1  : in std_logic_vector(31 downto 25); --first portion 
         i_imm_2  : in std_logic_vector(11 downto 7);  -- second portion
         o_extended_imm : out std_logic_vector(31 downto 0)
        );
end entity SB_type_extender;

architecture behavioral of SB_type_extender is

begin
    -- if msb is 0, then extend with 0s
    -- if msb is 1, then extend with 1s
    with i_imm_1(31) select
        o_extended_imm <= (19x"00000" & i_imm_1(31) & i_imm_2(7) & i_imm_1(30 downto 25) & i_imm_2(11 downto 8) & '0') when '0',
                          (19b"1111111111111111111" & i_imm_1(31) & i_imm_2(7) & i_imm_1(30 downto 25) & i_imm_2(11 downto 8) & '0')  when '1',
                          32x"00000000" when others;
end architecture behavioral;

