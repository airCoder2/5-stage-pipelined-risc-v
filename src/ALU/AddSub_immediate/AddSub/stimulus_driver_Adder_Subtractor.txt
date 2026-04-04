-- Author: Salah Nasriddinov
-- Description: 16 bit complimentor stimulus driver 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL; -- Required for the UNIFORM procedure

entity stimulus_driver is
	generic( N : integer := 32);
	Port( A_RANDOM_DATA   : out std_logic_vector(N-1 downto 0);
		  B_RANDOM_DATA   : out std_logic_vector(N-1 downto 0);
	      CONTROL_ADD_SUB : out std_logic);
end entity stimulus_driver;

architecture behavior of stimulus_driver is
begin 
    stimuli_process: process
        -- variables for the random number generator
        variable seed1, seed2 : positive := 1;
        variable rand_real    : real;
        variable rand_N1      : unsigned(N-1 downto 0);
        variable rand_N2       : unsigned(N-1 downto 0);
    begin
		for i in 1 to 10 loop
			-- build a 32-bit random value bit-by-bit
			for b in 0 to N-1 loop
				uniform(seed1, seed2, rand_real);
				if rand_real < 0.5 then
				  rand_N1(b) := '0';
				else
				  rand_N1(b) := '1';
				end if;
			end loop;

			-- build a 32-bit random value bit-by-bit
			for j in 0 to N-1 loop
				uniform(seed1, seed2, rand_real);
				if rand_real < 0.5 then
				  rand_N2(j) := '0';
				else
				  rand_N2(j) := '1';
				end if;
			end loop;

			uniform(seed1, seed2, rand_real);
			if rand_real < 0.5 then
			  CONTROL_ADD_SUB <= '0';
			else
			  CONTROL_ADD_SUB <= '1';
			end if;

			-- push the reandom numbers to x and y
			A_RANDOM_DATA <= std_logic_vector(rand_N1);
			B_RANDOM_DATA <= std_logic_vector(rand_N2);
			wait for 10 ns;

		end loop;
    end process stimuli_process;

end architecture behavior;


