-- Date        : Feb 9, 2026
-- File        : Decoder_3_to_8.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 3 to 8 one hot encoded decoder 
-- Note:       : This might not be the most efficient way, but it works.

library IEEE;
use IEEE.std_logic_1164.all;

entity Decoder_3_to_8 is
	port(i_code : in std_logic_vector(2 downto 0); -- we have 3 bits for code
		 o_decoded   : out std_logic_vector(7 downto 0)); -- we have 8 bit output
end entity Decoder_3_to_8;

architecture behavioral of Decoder_3_to_8 is
begin

    o_decoded <=
        8b"00000001" when (i_code = 3x"0") else
        8b"00000010" when (i_code = 3x"1") else
        8b"00000100" when (i_code = 3x"2") else
        8b"00001000" when (i_code = 3x"3") else
        8b"00010000" when (i_code = 3x"4") else
        8b"00100000" when (i_code = 3x"5") else
        8b"01000000" when (i_code = 3x"6") else
        8b"10000000" when (i_code = 3x"7") else
        8b"00000000";                           


end architecture behavioral;




