-- Date        : Feb 8, 2026
-- File        : stimulus_driver_N_bit_register.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a stimulus driver for tb_N_bit_register

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL; -- Required for the UNIFORM procedure

entity stimulus_driver_N_bit_register is
	generic( N          : integer;
			 ITERATIONS : integer;
			 CLK_Period : time);
	port( RANDOM_DATA  : out std_logic_vector(N-1 downto 0);
	      CONTROL_LOAD : out std_logic;
	  	  RESET		   : out std_logic);
end entity stimulus_driver_N_bit_register;

architecture behavioral of stimulus_driver_N_bit_register is
begin 
    stimuli_process: process
        -- variables for the random number generator
        variable seed1, seed2 : positive := 1;
        variable rand_real    : real;
        variable rand_N1      : unsigned(N-1 downto 0);
        variable rand_N2      : unsigned(N-1 downto 0);
    begin
		for i in 1 to ITERATIONS loop -- the outer loop
			if i = 1 then
				RESET <= '1';
			else
				RESET <= '0';
			end if;

			-- build a 32-bit random value bit-by-bit
			for b in 0 to N-1 loop
				uniform(seed1, seed2, rand_real);
				if rand_real < 0.5 then
				  rand_N1(b) := '0';
				else
				  rand_N1(b) := '1';
				end if;
			end loop;

			uniform(seed1, seed2, rand_real);
			if rand_real < 0.5 then
			  CONTROL_LOAD <= '0';
			else
			  CONTROL_LOAD <= '1';
			end if;

			-- push the random number to i_D
			RANDOM_DATA <= std_logic_vector(rand_N1);
			wait for CLK_Period;

		end loop; -- outer loop end
    end process stimuli_process;

end architecture behavioral;


