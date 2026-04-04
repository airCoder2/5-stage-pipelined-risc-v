-------------------------------------------------------------------------
-- Salah Nasriddinov 
-------------------------------------------------------------------------
-- tb_mux2t1.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a testbench for a 2 to 1 mux 
--
-- NOTES:
-- 01/30/26 Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_ones_complimentor is
	generic(N : integer := 32);
end entity tb_ones_complimentor;


architecture structural_testbench of tb_ones_complimentor is
	component ones_complimentor is
		Port( DATA_IN  : in  std_logic_vector(N-1 downto 0);
		      DATA_OUT : out std_logic_vector(N-1 downto 0));
	end component;

	component stimulus_driver is
		Port( DRIVER_RANDOM_DATA  : out std_logic_vector(N-1 downto 0));
	end component stimulus_driver;

	signal tb_DATA_IN  : std_logic_vector(N-1 downto 0);
	signal tb_DATA_OUT : std_logic_vector(N-1 downto 0);

begin
	DRIVER_D: stimulus_driver port map(
			DRIVER_RANDOM_DATA => tb_DATA_IN);

	DUT: ones_complimentor port map(
			DATA_IN => tb_DATA_IN,
			DATA_OUT => tb_DATA_OUT);

end architecture structural_testbench;
