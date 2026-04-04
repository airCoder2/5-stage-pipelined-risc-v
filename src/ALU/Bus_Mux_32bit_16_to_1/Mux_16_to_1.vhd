-- Date        : March 7, 2026
-- File        : Mux_16_to_1.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 16 to 1 mux 

library IEEE;
use IEEE.std_logic_1164.all;
USE ieee.numeric_std.ALL;

entity Mux_16_to_1 is
	port(DATA_IN   : in std_logic_vector(15 downto 0);
		 SELECT_IN : in std_logic_vector(3 downto 0);
	 	 MUX_OUT   : out std_logic);

end entity Mux_16_to_1;

architecture dataflow of Mux_16_to_1 is
begin
	with SELECT_IN select
		MUX_OUT <= DATA_IN(0)  when 4x"00",
				   DATA_IN(1)  when 4x"01",
				   DATA_IN(2)  when 4x"02",
				   DATA_IN(3)  when 4x"03",
				   DATA_IN(4)  when 4x"04",
				   DATA_IN(5)  when 4x"05",
				   DATA_IN(6)  when 4x"06",
				   DATA_IN(7)  when 4x"07",
				   DATA_IN(8)  when 4x"08",
				   DATA_IN(9)  when 4x"09",
				   DATA_IN(10) when 4x"0A",
				   DATA_IN(11) when 4x"0B",
				   DATA_IN(12) when 4x"0C",
				   DATA_IN(13) when 4x"0D",
				   DATA_IN(14) when 4x"0E",
				   DATA_IN(15) when 4x"0F",
				   '0'         when others;
end architecture dataflow;


