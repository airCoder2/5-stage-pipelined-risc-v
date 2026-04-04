-- Salah Nasriddinov 
-- This is a testbench for an N bit ripple carry adder

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_ripple_carry_N_bit_adder is
	generic(N : integer := 32);
end entity tb_ripple_carry_N_bit_adder;


architecture structural_testbench of tb_ripple_carry_N_bit_adder is
	component ripple_carry_N_bit_adder is
		port( x  	: in std_logic_vector(N-1 downto 0);
			  y     : in std_logic_vector(N-1 downto 0);
			  c_in  : in std_logic;
			  sum   : out std_logic_vector(N-1 downto 0);
			  c_out : out std_logic);
	end component;

	component stimulus_driver is
		Port( X_RANDOM_DATA  : out std_logic_vector(N-1 downto 0);
			  Y_RANDOM_DATA  : out std_logic_vector(N-1 downto 0);
			  C_IN_0	     : out std_logic);
	end component;

	signal tb_C_IN    : std_logic;
	signal tb_C_OUT   : std_logic;
	signal tb_X_IN    : std_logic_vector(N-1 downto 0);
	signal tb_Y_IN    : std_logic_vector(N-1 downto 0);
	signal tb_SUM_OUT : std_logic_vector(N-1 downto 0);

	signal TOTAL_SUM  : std_logic_vector(N   downto 0);

begin
	DRIVER_D: stimulus_driver port map(
			X_RANDOM_DATA => tb_X_IN,
			Y_RANDOM_DATA => tb_Y_IN,
			C_IN_0        => tb_C_IN);

	DUT: ripple_carry_N_bit_adder port map(
			x     => tb_X_IN,
			y     => tb_Y_IN,
			c_in  => tb_C_IN,
			sum   => tb_SUM_OUT,
			c_out => tb_C_OUT);

	TOTAL_SUM <= tb_C_OUT & tb_SUM_OUT;

end architecture structural_testbench;
