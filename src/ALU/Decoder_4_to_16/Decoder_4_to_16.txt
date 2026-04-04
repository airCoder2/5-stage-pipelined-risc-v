-- Date        : March 7, 2026
-- File        : Decoder_4_to_16.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 4 to 16 one hot encoded decoder 
-- Note:       : This might not be the most efficient way, but it works.

library IEEE;
use IEEE.std_logic_1164.all;

entity Decoder_4_to_16 is
	port(EN_IN   : in std_logic; -- input to enable the decoder. Otherwise outputs 0
		 CODE_IN : in std_logic_vector(3 downto 0); -- we have 4 bits for code
		 F_OUT   : out std_logic_vector(15 downto 0)); -- we have 16 bit output
end entity Decoder_4_to_16;

architecture behavioral of Decoder_4_to_16 is
begin
	process (CODE_IN, EN_IN) 
	begin
		if EN_IN = '1' then -- if enable is 1, then output the following according to input
			with CODE_IN select
			F_OUT <=
					 16b"0000000000000001" when 4x"0",
					 16b"0000000000000010" when 4x"1",
					 16b"0000000000000100" when 4x"2",
					 16b"0000000000001000" when 4x"3",
					 16b"0000000000010000" when 4x"4",
					 16b"0000000000100000" when 4x"5",
					 16b"0000000001000000" when 4x"6",
					 16b"0000000010000000" when 4x"7",
					 16b"0000000100000000" when 4x"8",
					 16b"0000001000000000" when 4x"9",
					 16b"0000010000000000" when 4x"A",
					 16b"0000100000000000" when 4x"B",
					 16b"0001000000000000" when 4x"C",
					 16b"0010000000000000" when 4x"D",
					 16b"0100000000000000" when 4x"E",
					 16b"1000000000000000" when 4x"F",
					 16b"0000000000000000" when others;

		else F_OUT <= 16b"0000000000000000"; -- if enable is not 1 then output 0
		end if;
	end process;

end architecture behavioral;

