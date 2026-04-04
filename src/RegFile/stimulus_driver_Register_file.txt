-- Date : Feb 12, 2026
-- File : stimulus_driver_Register_file.vhd
-- Designer : Salah Nasriddinov
-- Description : This file implements a stimulus driver for tb_Register_file

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL; -- Required for the UNIFORM procedure

entity stimulus_driver_Register_file is
    generic(
        ITERATIONS : integer;
        CLK_PERIOD : time
    );
    port(
        RANDOM_DATA  : out std_logic_vector(31 downto 0);
        CONTROL_LOAD : out std_logic;
        RESET        : out std_logic;
        WRITE_SEL    : out std_logic_vector(4 downto 0);
        READ_SEL1    : out std_logic_vector(4 downto 0);
        READ_SEL2    : out std_logic_vector(4 downto 0)
    );
end entity stimulus_driver_Register_file;

architecture behavioral of stimulus_driver_Register_file is
    type my_array_variable is array (0 to 31) of unsigned(31 downto 0);
begin

    RESET_R_FILE: process
    begin
        RESET <= '0';
        wait for CLK_PERIOD/4;
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait;
    end process;

    stimuli_process: process
        -- variables for the random number generator
        variable seed1, seed2 : positive := 1;
        variable rand_real : real;
        variable rand_N1 : unsigned(31 downto 0);
        variable rand_N2 : unsigned(31 downto 0);
        variable numbers_pushed : my_array_variable;
    begin
        wait for CLK_PERIOD;
        wait for CLK_PERIOD/4; -- for waveform clarity;

        for i in 0 to ITERATIONS loop -- the outer loop
            -- build a 32-bit random value bit-by-bit
            for b in 0 to 31 loop
                uniform(seed1, seed2, rand_real);
                if rand_real < 0.5 then
                    rand_N1(b) := '0';
                else
                    rand_N1(b) := '1';
                end if;
            end loop;

            CONTROL_LOAD <= '1';

            -- writing to all of the 32 registers
            -- push the random number to the register
            numbers_pushed(i) := rand_N1;

            report "i: " & integer'image(i) & ", number_pushed 0x: "& to_hstring(numbers_pushed(i));

            RANDOM_DATA <= std_logic_vector(rand_N1);
            WRITE_SEL <= std_logic_vector(to_unsigned(i, WRITE_SEl'length));

            wait for CLK_PERIOD;
        end loop; -- outer loop

        for j in 0 to ITERATIONS loop -- the loop for reading
            CONTROL_LOAD <= '0'; -- reading all the written values

            READ_SEL1 <= std_logic_vector(to_unsigned(j, READ_SEl1'length));
            READ_SEL2 <= std_logic_vector(to_unsigned(j, READ_SEl1'length));

            -- report "i: " & integer'image(i) & ", number_pushed 0x: "& to_hstring(numbers_pushed(i-1));

            wait for CLK_PERIOD;
        end loop; -- outer loop
		wait;
    end process;

end architecture behavioral;

