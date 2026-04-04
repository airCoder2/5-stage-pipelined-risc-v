-- Date        : Feb 9, 2026
-- File        : tb_Mux_32_to_1.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This is a testbench for a 32 to 1 mux

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_Mux_32_to_1 is
	generic(
			ITERATIONS : integer; -- passed in the do file
			WAIT_TIME  : time
		   	);
end tb_Mux_32_to_1;

architecture behavior of tb_Mux_32_to_1 is

	component Mux_32_to_1 is
		port(DATA_IN   : in std_logic_vector(31 downto 0);
			 SELECT_IN : in std_logic_vector(4 downto 0);
			 MUX_OUT   : out std_logic);
	end component Mux_32_to_1;

	component stimulus_driver_Mux_32_to_1 is
		generic(
			   ITERATIONS   : integer;
			   WAIT_TIME    : time); -- how many times simulation is going to run
		Port(RANDOM_DATA    : out std_logic_vector(32-1 downto 0);
			 SELECT_MUX     : out std_logic_vector(5-1  downto 0));
	end component stimulus_driver_Mux_32_to_1;

  -- Temporary signals to connect to the DUT.
	signal selec_mux  	   : std_logic_vector(5-1 downto 0);
	signal random_data : std_logic_vector(32-1 downto 0);
	signal mux_out : std_logic;

begin

	stimulus_d: stimulus_driver_Mux_32_to_1
		generic map(ITERATIONS => ITERATIONS, WAIT_TIME => WAIT_TIME)	
		port map(
			RANDOM_DATA  => random_data, 
			SELECT_MUX   => selec_mux);

	DUT: Mux_32_to_1 
		port map(
			   DATA_IN   => random_data, 
			   SELECT_IN => selec_mux,
			   MUX_OUT   => mux_out);
  
end behavior;

