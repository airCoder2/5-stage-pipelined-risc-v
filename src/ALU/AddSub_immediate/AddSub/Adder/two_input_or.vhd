-- Author: Salah Nasriddinov
-- Descriptio: Two input or gate

library IEEE;
use IEEE.std_logic_1164.all;


entity two_input_or is
	port( A : in std_logic;
		  B : in std_logic;
		  F : out std_logic);
end two_input_or;

architecture dataflow of two_input_or is
begin 
	F <= A or B;
end dataflow;





