-- Date        : march 20, 2026
-- File        : U_type_extender.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements an extender that fills the bottom with 12 0s

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity U_type_extender is

	port(
         i_imm  : in std_logic_vector(31 downto 12);
         o_extended_imm : out std_logic_vector(31 downto 0)
        );
	
end entity U_type_extender;

architecture behavioral of U_type_extender is

begin
    o_extended_imm <= i_imm & 12x"000";
end architecture behavioral;


