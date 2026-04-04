-- Date        : Feb 8, 2026
-- File        : stimulus_driver_N_bit_register.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a stimulus driver for tb_N_bit_register

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL; -- Required for the UNIFORM procedure

entity stimulus_driver_Decoder_5_to_32 is
	generic(ITERATIONS : integer; WAIT_TIME : time);

	Port(RANDOM_DATA    : out std_logic_vector(5-1 downto 0);
		 DECODER_ENABLE : out std_logic);
end entity stimulus_driver_Decoder_5_to_32;

architecture behavioral of stimulus_driver_Decoder_5_to_32 is
begin 
    stimuli_process: process
        -- variables for the random number generator
        variable seed1, seed2 : positive := 1;
        variable rand_real    : real;
        variable rand_N1      : unsigned(5-1 downto 0);
    begin
		for i in 1 to ITERATIONS loop -- the outer loop
			if i = 1 then
				DECODER_ENABLE <= '0';
			else
				DECODER_ENABLE <= '1';
			end if;

			-- build a 5-bit random value bit-by-bit
			for b in 0 to 4 loop -- we only have 5 bit code 
				uniform(seed1, seed2, rand_real);
				if rand_real < 0.5 then
				  rand_N1(b) := '0';
				else
				  rand_N1(b) := '1';
				end if;
			end loop;

			-- push the random number
			RANDOM_DATA <= std_logic_vector(rand_N1);
			wait for WAIT_TIME;

		end loop; -- outer loop end
    end process stimuli_process;

end architecture behavioral;


