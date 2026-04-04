-- Date        : March 7, 2026
-- File        : tb_Decoder_4_to_16.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This is a testbench for 4 to 16 

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_Decoder_4_to_16 is
	generic(
			ITERATIONS : integer; -- passed in the do file
			WAIT_TIME  : time
		   	);
end tb_Decoder_4_to_16;

architecture behavior of tb_Decoder_4_to_16 is

	component Decoder_4_to_16 is
		port(EN_IN   : in std_logic;
			 CODE_IN : in std_logic_vector(3 downto 0); -- we have 4 bits for code
			 F_OUT   : out std_logic_vector(15 downto 0)); -- we have 16 bit output
	end component Decoder_4_to_16;

	component stimulus_driver_Decoder_4_to_16 is
		generic(
			   ITERATIONS   : integer;
			   WAIT_TIME    : time); -- how many times simulation is going to run
		Port(RANDOM_DATA    : out std_logic_vector(3 downto 0);
			 DECODER_ENABLE : out std_logic);
	end component stimulus_driver_Decoder_4_to_16;

  -- Temporary signals to connect to the DUT.
	signal s_DE  	   : std_logic;
	signal Random_data : std_logic_vector(3 downto 0);
	signal Decoder_out : std_logic_vector(15 downto 0);

begin


	stimulus_d: stimulus_driver_Decoder_4_to_16
		generic map(ITERATIONS => ITERATIONS, WAIT_TIME => WAIT_TIME)	
		port map(
			RANDOM_DATA  => Random_data, 
	    	DECODER_ENABLE => s_DE);

	DUT: Decoder_4_to_16 
		port map(
			   EN_IN => s_DE, 
			   CODE_IN => Random_data,
			   F_OUT  => Decoder_out);
  
end behavior;

