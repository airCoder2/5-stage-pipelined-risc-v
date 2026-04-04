-- Salah Nasriddinov 
-- This is a testbench for an N bit ripple carry adder

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_Adder_Subtractor is
	generic(N : integer := 32);
end entity tb_Adder_Subtractor;


architecture structural_testbench of tb_Adder_Subtractor is
	component Adder_Subtractor is
		generic (N : integer);
		port( A  	   : in std_logic_vector(N-1 downto 0);
			  B        : in std_logic_vector(N-1 downto 0);
			  nAdd_Sub : in std_logic;
			  sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
			  c_out    : out std_logic;
			  overflow : out std_logic);
	end component Adder_Subtractor;

	component stimulus_driver is
		generic (N : integer);
		Port( A_RANDOM_DATA   : out std_logic_vector(N-1 downto 0);
			  B_RANDOM_DATA   : out std_logic_vector(N-1 downto 0);
			  CONTROL_ADD_SUB : out std_logic);
	end component;

	signal tb_CONTROL_ADD_SUB : std_logic;
	signal tb_C_OUT           : std_logic;
	signal tb_OVERFLOW_OUT    : std_logic;
	signal tb_A_IN            : std_logic_vector(N-1 downto 0);
	signal tb_B_IN    		  : std_logic_vector(N-1 downto 0);
	signal tb_SUM_OUT         : std_logic_vector(N-1 downto 0);


begin
	DRIVER_D: stimulus_driver 
		generic map(N => N)
		port map(
			A_RANDOM_DATA   => tb_A_IN,
			B_RANDOM_DATA   => tb_B_IN,
			CONTROL_ADD_SUB => tb_CONTROL_ADD_SUB);

	DUT: Adder_Subtractor
		generic map(N => N)
		port map(
			A        => tb_A_IN,
			B        => tb_B_IN,
			nAdd_Sub => tb_CONTROL_ADD_SUB,
			sum      => tb_SUM_OUT,
			c_out    => tb_C_OUT,
			overflow => tb_OVERFLOW_OUT);

end architecture structural_testbench;
