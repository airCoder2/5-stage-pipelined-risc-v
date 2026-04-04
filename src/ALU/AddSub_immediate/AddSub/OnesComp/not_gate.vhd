-- Author: Salah Nasriddinov
-- Descriptio: Two input or gate

library IEEE;
use IEEE.std_logic_1164.all;

entity not_gate is
	port( A : in std_logic;
		  F : out std_logic);
end not_gate;

architecture dataflow of not_gate is
begin
	F <= not A;
end dataflow;
