-------------------------------------------------------------------------
-- Salah Nasriddinov 
-------------------------------------------------------------------------
-- mux2t1.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a 2 to 1 mux using
--              structural design.
--
-- NOTES:
-- 01/29/26 Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1_structural is
	Port( I0_IN	: in std_logic;
		  I1_IN : in std_logic;
   		  S_IN  : in std_logic;
		  F_OUT : out std_logic);
end mux2t1_structural;


architecture structural of mux2t1_structural is
	component two_input_and is
		port( A : in std_logic;
			  B : in std_logic;
			  F : out std_logic);
	end component;

	component two_input_or is
		port( A : in std_logic;
			  B : in std_logic;
			  F : out std_logic);
	end component;

	component not_gate is
		port( A : in std_logic;
			  F : out std_logic);
	end component;

	signal s_not, and_0, and_1 : std_logic;

begin
	not1: not_gate port map (A => S_IN,
							 F => s_not);

	a0: two_input_and port map (A => I0_IN,
								B => s_not,
								F => and_0); 

	a1: two_input_and port map (A => I1_IN,
								B => S_IN, 
								F => and_1); 

	or1: two_input_or port map (A => and_0,
								B => and_1,
								F => F_OUT); 
end structural;
