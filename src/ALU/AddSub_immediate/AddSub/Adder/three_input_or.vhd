-- Author: Salah Nasriddinov
-- Descriptio: Three input or gate


library IEEE;
use IEEE.std_logic_1164.all;

entity three_input_or is
	port( A : in std_logic;
		  B : in std_logic;
	      C : in std_logic;
		  F : out std_logic);
end three_input_or;

architecture structural of three_input_or is
	component two_input_or is
		port( A : in std_logic;
			  B : in std_logic;
			  F : out std_logic);
	end component;
	signal first_or_out : std_logic;
begin 
	OR1: two_input_or port map(
			A => A,
			B => B,
			F => first_or_out);
	OR2: two_input_or port map(
			A => C,
			B => first_or_out,
			F => F);
end architecture structural;


