-- Author: Salah Nasriddinov
-- Description: Full adder


library IEEE;
use IEEE.std_logic_1164.all;

entity full_adder is
	port( x  	: in std_logic;
		  y     : in std_logic;
	      c_in  : in std_logic;
		  sum   : out std_logic;
		  c_out : out std_logic);
end entity full_adder;

architecture structural of full_adder is
	component three_input_xor is
		port( A : in std_logic;
			  B : in std_logic;
			  C : in std_logic;
			  F : out std_logic);
	end component;

	component three_input_or is
		port( A : in std_logic;
			  B : in std_logic;
			  C : in std_logic;
			  F : out std_logic);
	end component;

	component two_input_and is
		port( A : in std_logic;
			  B : in std_logic;
			  F : out std_logic);
	end component;

	signal first_and_out  : std_logic;
	signal second_and_out : std_logic;
	signal third_and_out  : std_logic;
begin 

	XOR1: three_input_xor port map(
			A => x,
			B => y,
			C => c_in,
			F => sum);

	AND1: two_input_and port map(
			A => x,
			B => y,
			F => first_and_out);

	AND2: two_input_and port map(
			A => x,
			B => c_in,
			F => second_and_out);

	AND3: two_input_and port map(
			A => y,
			B => c_in,
			F => third_and_out);

	OR1: three_input_or port map(
			A => first_and_out,
			B => second_and_out,
			C => third_and_out,
			F => c_out);

end architecture structural;

