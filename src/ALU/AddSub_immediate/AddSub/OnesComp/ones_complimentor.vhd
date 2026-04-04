-- Author: Salah Nasriddinov
-- Descriptio: Two input or gate

library IEEE;
use IEEE.std_logic_1164.all;


entity ones_complimentor is
	generic(N : integer);
	Port( DATA_IN  : in  std_logic_vector(N-1 downto 0);
		  DATA_OUT : out std_logic_vector(N-1 downto 0));
end entity ones_complimentor;


architecture structural of ones_complimentor is
	component not_gate is
		port( A : in std_logic;
			  F : out std_logic);
	end component;
begin
	G_NBit_Comp: for i in 0 to N-1 generate
		NOT_i: not_gate port map( A => DATA_IN(i),
								  F => DATA_OUT(i));
	end generate;
end architecture structural;




