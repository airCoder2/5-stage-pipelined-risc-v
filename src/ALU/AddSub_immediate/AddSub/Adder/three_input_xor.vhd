-- Author: Salah Nasriddinov
-- Descriptio: Three input xor gate


library IEEE;
use IEEE.std_logic_1164.all;

entity three_input_xor is
	port( A : in std_logic;
		  B : in std_logic;
	      C : in std_logic;
		  F : out std_logic);
end three_input_xor;

architecture structural of three_input_xor is
	component two_input_xor is
		port( A : in std_logic;
			  B : in std_logic;
			  F : out std_logic);
	end component;
	signal first_xor_out : std_logic;
begin 
	XOR1: two_input_xor port map(
			A => A,
			B => B,
			F => first_xor_out);
	XOR2: two_input_xor port map(
			A => C,
			B => first_xor_out,
			F => F);
end architecture structural;

