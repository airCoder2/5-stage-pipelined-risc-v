-- Author: Salah Nasriddinov
-- Descriptio: Two input and gate


library IEEE;
use IEEE.std_logic_1164.all;


entity two_input_and is
	port( A : in std_logic;
		  B : in std_logic;
		  F : out std_logic);
end two_input_and;

architecture dataflow of two_input_and is
begin 
	F <= A and B;
end dataflow;





