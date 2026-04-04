-- Author: Salah Nasriddinov
-- Descriptio: Two input xor gate


library IEEE;
use IEEE.std_logic_1164.all;


entity two_input_xor is
	port( A : in std_logic;
		  B : in std_logic;
		  F : out std_logic);
end two_input_xor;

architecture dataflow of two_input_xor is
begin 
	F <= A xor B;
end dataflow;
