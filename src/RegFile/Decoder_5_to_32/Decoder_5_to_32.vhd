-- Date        : Feb 9, 2026
-- File        : Decoder_5_to_32.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 5 to 32 one hot encoded decoder 
-- Note:       : This might not be the most efficient way, but it works.

library IEEE;
use IEEE.std_logic_1164.all;

entity Decoder_5_to_32 is
	port(EN_IN   : in std_logic; -- input to enable the decoder. Otherwise outputs 0
		 CODE_IN : in std_logic_vector(4 downto 0); -- we have 5 bits for code
		 F_OUT   : out std_logic_vector(31 downto 0)); -- we have 32 bit output
end entity Decoder_5_to_32;

architecture behavioral of Decoder_5_to_32 is
begin

    F_OUT <=
        32b"00000000000000000000000000000010" when (CODE_IN = 5x"01" and EN_IN = '1') else
        32b"00000000000000000000000000000100" when (CODE_IN = 5x"02" and EN_IN = '1') else
        32b"00000000000000000000000000001000" when (CODE_IN = 5x"03" and EN_IN = '1') else
        32b"00000000000000000000000000010000" when (CODE_IN = 5x"04" and EN_IN = '1') else
        32b"00000000000000000000000000100000" when (CODE_IN = 5x"05" and EN_IN = '1') else
        32b"00000000000000000000000001000000" when (CODE_IN = 5x"06" and EN_IN = '1') else
        32b"00000000000000000000000010000000" when (CODE_IN = 5x"07" and EN_IN = '1') else
        32b"00000000000000000000000100000000" when (CODE_IN = 5x"08" and EN_IN = '1') else
        32b"00000000000000000000001000000000" when (CODE_IN = 5x"09" and EN_IN = '1') else
        32b"00000000000000000000010000000000" when (CODE_IN = 5x"0A" and EN_IN = '1') else
        32b"00000000000000000000100000000000" when (CODE_IN = 5x"0B" and EN_IN = '1') else
        32b"00000000000000000001000000000000" when (CODE_IN = 5x"0C" and EN_IN = '1') else
        32b"00000000000000000010000000000000" when (CODE_IN = 5x"0D" and EN_IN = '1') else
        32b"00000000000000000100000000000000" when (CODE_IN = 5x"0E" and EN_IN = '1') else
        32b"00000000000000001000000000000000" when (CODE_IN = 5x"0F" and EN_IN = '1') else
        32b"00000000000000010000000000000000" when (CODE_IN = 5x"10" and EN_IN = '1') else
        32b"00000000000000100000000000000000" when (CODE_IN = 5x"11" and EN_IN = '1') else
        32b"00000000000001000000000000000000" when (CODE_IN = 5x"12" and EN_IN = '1') else
        32b"00000000000010000000000000000000" when (CODE_IN = 5x"13" and EN_IN = '1') else
        32b"00000000000100000000000000000000" when (CODE_IN = 5x"14" and EN_IN = '1') else
        32b"00000000001000000000000000000000" when (CODE_IN = 5x"15" and EN_IN = '1') else
        32b"00000000010000000000000000000000" when (CODE_IN = 5x"16" and EN_IN = '1') else
        32b"00000000100000000000000000000000" when (CODE_IN = 5x"17" and EN_IN = '1') else
        32b"00000001000000000000000000000000" when (CODE_IN = 5x"18" and EN_IN = '1') else
        32b"00000010000000000000000000000000" when (CODE_IN = 5x"19" and EN_IN = '1') else
        32b"00000100000000000000000000000000" when (CODE_IN = 5x"1A" and EN_IN = '1') else
        32b"00001000000000000000000000000000" when (CODE_IN = 5x"1B" and EN_IN = '1') else
        32b"00010000000000000000000000000000" when (CODE_IN = 5x"1C" and EN_IN = '1') else
        32b"00100000000000000000000000000000" when (CODE_IN = 5x"1D" and EN_IN = '1') else
        32b"01000000000000000000000000000000" when (CODE_IN = 5x"1E" and EN_IN = '1') else
        32b"10000000000000000000000000000000" when (CODE_IN = 5x"1F" and EN_IN = '1') else
        32b"00000000000000000000000000000000";                           

    --	process (CODE_IN, EN_IN)
    --	begin
    --		if EN_IN = '1' then -- if enable is 1, then output the following according to input
    --			with CODE_IN select
    --			F_OUT <= -- can't write to reg 0. Connected to 0
    --					 32b"00000000000000000000000000000010" when 5x"01",
    --					 32b"00000000000000000000000000000100" when 5x"02",
    --					 32b"00000000000000000000000000001000" when 5x"03",
    --					 32b"00000000000000000000000000010000" when 5x"04",
    --					 32b"00000000000000000000000000100000" when 5x"05",
    --					 32b"00000000000000000000000001000000" when 5x"06",
    --					 32b"00000000000000000000000010000000" when 5x"07",
    --					 32b"00000000000000000000000100000000" when 5x"08",
    --					 32b"00000000000000000000001000000000" when 5x"09",
    --					 32b"00000000000000000000010000000000" when 5x"0A",
    --					 32b"00000000000000000000100000000000" when 5x"0B",
    --					 32b"00000000000000000001000000000000" when 5x"0C",
    --					 32b"00000000000000000010000000000000" when 5x"0D",
    --					 32b"00000000000000000100000000000000" when 5x"0E",
    --					 32b"00000000000000001000000000000000" when 5x"0F",
    --					 32b"00000000000000010000000000000000" when 5x"10",
    --					 32b"00000000000000100000000000000000" when 5x"11",
    --					 32b"00000000000001000000000000000000" when 5x"12",
    --					 32b"00000000000010000000000000000000" when 5x"13",
    --					 32b"00000000000100000000000000000000" when 5x"14",
    --					 32b"00000000001000000000000000000000" when 5x"15",
    --					 32b"00000000010000000000000000000000" when 5x"16",
    --					 32b"00000000100000000000000000000000" when 5x"17",
    --					 32b"00000001000000000000000000000000" when 5x"18",
    --					 32b"00000010000000000000000000000000" when 5x"19",
    --					 32b"00000100000000000000000000000000" when 5x"1A",
    --					 32b"00001000000000000000000000000000" when 5x"1B",
    --					 32b"00010000000000000000000000000000" when 5x"1C",
    --					 32b"00100000000000000000000000000000" when 5x"1D",
    --					 32b"01000000000000000000000000000000" when 5x"1E",
    --					 32b"10000000000000000000000000000000" when 5x"1F",
    --					 32b"00000000000000000000000000000000" when others;
    --
    --		else F_OUT <= 32b"00000000000000000000000000000000"; -- if enable is not 1 then output 0
    --		end if;
    --	end process;

end architecture behavioral;

