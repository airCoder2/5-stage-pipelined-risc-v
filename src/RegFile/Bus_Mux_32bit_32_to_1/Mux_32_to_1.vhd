-- Date        : Feb 9, 2026
-- File        : Mux_32_to_1.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 32 to 1 mux 

library IEEE;
use IEEE.std_logic_1164.all;
USE ieee.numeric_std.ALL;

entity Mux_32_to_1 is
	port(DATA_IN   : in std_logic_vector(31 downto 0);
		 SELECT_IN : in std_logic_vector(4 downto 0);
	 	 MUX_OUT   : out std_logic);

end entity Mux_32_to_1;

architecture dataflow of Mux_32_to_1 is
begin
	with SELECT_IN select
		MUX_OUT <= DATA_IN(0)  when 5x"00",
				   DATA_IN(1)  when 5x"01",
				   DATA_IN(2)  when 5x"02",
				   DATA_IN(3)  when 5x"03",
				   DATA_IN(4)  when 5x"04",
				   DATA_IN(5)  when 5x"05",
				   DATA_IN(6)  when 5x"06",
				   DATA_IN(7)  when 5x"07",
				   DATA_IN(8)  when 5x"08",
				   DATA_IN(9)  when 5x"09",
				   DATA_IN(10) when 5x"0A",
				   DATA_IN(11) when 5x"0B",
				   DATA_IN(12) when 5x"0C",
				   DATA_IN(13) when 5x"0D",
				   DATA_IN(14) when 5x"0E",
				   DATA_IN(15) when 5x"0F",
				   DATA_IN(16) when 5x"10",
				   DATA_IN(17) when 5x"11",
				   DATA_IN(18) when 5x"12",
				   DATA_IN(19) when 5x"13",
				   DATA_IN(20) when 5x"14",
				   DATA_IN(21) when 5x"15",
				   DATA_IN(22) when 5x"16",
				   DATA_IN(23) when 5x"17",
				   DATA_IN(24) when 5x"18",
				   DATA_IN(25) when 5x"19",
				   DATA_IN(26) when 5x"1A",
				   DATA_IN(27) when 5x"1B",
				   DATA_IN(28) when 5x"1C",
				   DATA_IN(29) when 5x"1D",
				   DATA_IN(30) when 5x"1E",
				   DATA_IN(31) when 5x"1F",
				   '0'         when others;
end architecture dataflow;


