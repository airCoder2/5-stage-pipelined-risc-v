-- Salah Nasriddinov
-- This is an Adder Subtractor unit 

library IEEE;
use IEEE.std_logic_1164.all;

entity Adder_Subtractor is
	generic (N : integer := 32);
	port( A  	   : in std_logic_vector(N-1 downto 0);
		  B        : in std_logic_vector(N-1 downto 0);
	      nAdd_Sub : in std_logic;
		  sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
		  c_out    : out std_logic;
		  overflow : out std_logic);
end entity Adder_Subtractor;

architecture structural of Adder_Subtractor is
	-- including ripple_carry_N_bit_adder
	component ripple_carry_N_bit_adder is
		generic(N : integer);
		port( x  	: in std_logic_vector(N-1 downto 0);
			  y     : in std_logic_vector(N-1 downto 0);
			  c_in  : in std_logic;
			  sum   : out std_logic_vector(N-1 downto 0); 
			  c_out : out std_logic;
			  overflow : out std_logic);
	end component ripple_carry_N_bit_adder;

	-- including ones_complimentor
	component ones_complimentor is
		generic(N : integer);
		port( DATA_IN  : in  std_logic_vector(N-1 downto 0);
			  DATA_OUT : out std_logic_vector(N-1 downto 0));
	end component ones_complimentor;
	
	-- including mux2t1_N
	component mux2t1_N_dataflow is
		generic(N : integer);
		port(i_S          : in std_logic;
			   i_D0         : in std_logic_vector(N-1 downto 0);
			   i_D1         : in std_logic_vector(N-1 downto 0);
			   o_O          : out std_logic_vector(N-1 downto 0));
	end component mux2t1_N_dataflow;

	signal complimented_B : std_logic_vector(N-1 downto 0);
	signal mux_out_B      : std_logic_vector(N-1 downto 0);

begin 
	COMPLIMENTOR: ones_complimentor
		generic map(N => N)
   		port map(
			DATA_IN  => B,
			DATA_OUT => complimented_B);

	MUX: mux2t1_N_dataflow 
		generic map(N => N)
		port map(
			i_S  => nAdd_Sub,
			i_D0 => B,
			i_D1 => complimented_B,
			o_O  => mux_out_B);

	ADDER: ripple_carry_N_bit_adder 
		generic map(N => N)
		port map(
			x 	     => A,
			y 	     => mux_out_B,
			c_in     => nAdd_Sub,
			sum      => sum,
			c_out    => c_out,
			overflow => overflow);

end architecture structural;

