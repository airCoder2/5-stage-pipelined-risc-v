-- Author: Salah Nasriddinov
-- Description: ripple carry N bit adder

library IEEE;
use IEEE.std_logic_1164.all;

entity ripple_carry_N_bit_adder is
	generic (N : integer);
	port( x  	   : in std_logic_vector(N-1 downto 0);
		  y        : in std_logic_vector(N-1 downto 0);
	      c_in     : in std_logic;
		  sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
		  c_out    : out std_logic;
		  overflow : out std_logic);
end entity ripple_carry_N_bit_adder;

architecture structural of ripple_carry_N_bit_adder is

	-- This funciton returns an appropriate input carry logic
	function c_in_selector(carry_vector : std_logic_vector; c_in : std_logic; i : integer) return std_logic is
	begin
		if i = 0 then
			return c_in;
		else
			return carry_vector(i-1);
		end if;
	end function;

	component full_adder is
		port( x  	: in std_logic;
			  y     : in std_logic;
			  c_in  : in std_logic;
			  sum   : out std_logic;
			  c_out : out std_logic);
	end component;

	component two_input_xor is
		port( A : in std_logic;
			  B : in std_logic;
			  F : out std_logic);
	end component;


	signal carry_signals : std_logic_vector(N-1 downto 0);

begin 
	Ripple_Carry_Adder: for i in 0 to N-1 generate
		FA_i: full_adder port map(
				x	  => x(i),
				y 	  => y(i),
				c_in  => c_in_selector(carry_signals, c_in, i),
				c_out => carry_signals(i),
				sum   => sum(i));
	end generate;
	c_out <= carry_signals(N-1);

	OVERFLOW_DETECT: two_input_xor port map(
			A => carry_signals(N-1),
			B => carry_signals(N-2),
			F => overflow);



end architecture structural;





