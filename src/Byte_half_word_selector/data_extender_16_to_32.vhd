-- Date        : march 20, 2026
-- File        : data_extender_16_to_32.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements an 16 to 32 signed/unsigned extender

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity data_extender_16_to_32 is
	port(
         i_data  : in std_logic_vector(15 downto 0);
         i_zero_sign : in std_logic;
         o_extended_data : out std_logic_vector(31 downto 0)
        );
end entity data_extender_16_to_32;

architecture behavioral of data_extender_16_to_32 is

begin

    o_extended_data <= (16x"FFFF" & i_data) when ((i_data(15) = '1') and (i_zero_sign = '1')) else
                        16x"0000" & i_data;


end architecture behavioral;

