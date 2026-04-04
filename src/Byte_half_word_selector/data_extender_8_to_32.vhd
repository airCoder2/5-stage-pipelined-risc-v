-- Date        : march 20, 2026
-- File        : data_extender_8_to_32.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements an 8 to 32 signed/unsigned extender

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity data_extender_8_to_32 is
	port(
         i_data  : in std_logic_vector(7 downto 0);
         i_zero_sign : in std_logic;
         o_extended_data : out std_logic_vector(31 downto 0)
        );
end entity data_extender_8_to_32;

architecture behavioral of data_extender_8_to_32 is

begin

    o_extended_data <= (24x"FFFFFF" & i_data) when (i_data(7) = '1' and i_zero_sign = '1') else
                        24x"000000" & i_data;


end architecture behavioral;

