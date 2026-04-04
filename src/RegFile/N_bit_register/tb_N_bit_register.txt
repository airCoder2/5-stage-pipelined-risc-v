-- Date        : Feb 8, 2026
-- File        : tb_N_bit_register.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This is a testbench for my N bit register 

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_N_bit_register is
	generic(N : integer; -- passed in the do file
			ITERATIONS : integer; -- passed in the do file
			gCLK_HPER : time -- passed in the do file
		   	);
end tb_N_bit_register;

architecture behavior of tb_N_bit_register is
 	 -- Calculate the clock period as twice the half-period
	constant cCLK_PER   : time := gCLK_HPER * 2;


	component N_bit_register is
		generic(N : integer);
		port(i_CLK  : in std_logic;						   -- Clock input
		   i_RST    : in std_logic;						   -- Reset input
		   i_WE     : in std_logic;   					   -- Write enable input
		   i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
		   o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
	end component N_bit_register;

	component stimulus_driver_N_bit_register is
	generic( N          : integer;
			 ITERATIONS : integer;
			 CLK_Period : time);
		Port( RANDOM_DATA  : out std_logic_vector(N-1 downto 0);
			  CONTROL_LOAD : out std_logic;
			  RESET		   : out std_logic);
	end component stimulus_driver_N_bit_register;

  -- Temporary signals to connect to the N_bit_register component.
	signal s_CLK, s_RST, s_WE  : std_logic;
	signal s_D, s_Q : std_logic_vector(N-1 downto 0);

begin


	stimulus_d: stimulus_driver_N_bit_register
		generic map(N => N, CLK_Period => cCLK_PER, ITERATIONS => ITERATIONS)	
		port map(
			RANDOM_DATA  => s_D, 
	    	CONTROL_LOAD => s_WE, 
	  		RESET        => s_RST);

	DUT: N_bit_register 
		generic map(N => N)
		port map(
			   i_CLK => s_CLK, 
			   i_RST => s_RST,
			   i_WE  => s_WE,
			   i_D   => s_D,
			   o_Q   => s_Q);

  -- This process sets the clock value (low for gCLK_HPER, then high
  -- for gCLK_HPER). Absent a "wait" command, processes restart 
  -- at the beginning once they have reached the final statement.
  P_CLK: process
  begin
    s_CLK <= '0';
    wait for gCLK_HPER;
    s_CLK <= '1';
    wait for gCLK_HPER;
  end process;
  
end behavior;

