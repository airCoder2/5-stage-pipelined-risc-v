-------------------------------------------------------------------------
-- Salah Nasriddinov 
-------------------------------------------------------------------------
-- mux2t1.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a 2 to 1 mux using
--              dataflow design.
--
-- NOTES:
-- 01/29/26 Design created.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1_dataflow is
	Port( I0_IN	: in std_logic;
		  I1_IN : in std_logic;
   		  S_IN  : in std_logic;
		  F_OUT : out std_logic);
end mux2t1_dataflow;

architecture dataflow of mux2t1_dataflow is
begin
	-- using conditional statement
	F_OUT <= I0_IN when (S_IN = '0') else
			 I1_IN when (S_IN = '1') else
			 '0';

end dataflow;
