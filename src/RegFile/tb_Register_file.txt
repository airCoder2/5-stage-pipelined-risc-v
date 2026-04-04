-- Date        : Feb 12, 2026
-- File        : tb_Register_file.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for a register file 


-- How testbench implemented:
-- put random values in registers from 0 to 31 sequentially,
-- then read all the random values from 0 to 31 sequentially
-- raise a flag if they do not match


library IEEE;
use IEEE.std_logic_1164.all;

entity tb_Register_file is
	generic(
			ITERATIONS : integer; -- passed in the do file
			CLK_PERIOD : time --half period
		   	);
end tb_Register_file;

architecture behavior of tb_Register_file is

	component Register_file is
		port(CLOCK_IN : in std_logic;                                      -- Clock input for registers
			 DATA_TO_WRITE_IN : in std_logic_vector(31 downto 0); 	       -- Data to load
			 WRITE_EN_IN  : in std_logic;                                  -- to control the decoder
			 REG_RST_IN   : in std_logic;                                  -- to clear all the register
			 WRITE_SEL_IN : in std_logic_vector(4 downto 0); -- select register to load
			 READ_SEL1_IN : in std_logic_vector(4 downto 0); -- select register 1 to read
			 READ_SEL2_IN : in std_logic_vector(4 downto 0); -- select register 2 to read
			 DATA_TO_READ1_OUT: out std_logic_vector(31 downto 0); 	   -- selected register 1 out
			 DATA_TO_READ2_OUT: out std_logic_vector(31 downto 0)        -- selected register 2 out
			);
	end component Register_file;


	component stimulus_driver_Register_file is
		generic(ITERATIONS : integer;
				CLK_Period : time);

		port(RANDOM_DATA  : out std_logic_vector(31 downto 0);
			 CONTROL_LOAD : out std_logic;
			 RESET		  : out std_logic;
			 WRITE_SEL    : out std_logic_vector(4 downto 0);
			 READ_SEL1    : out std_logic_vector(4 downto 0);
			 READ_SEL2    : out std_logic_vector(4 downto 0));
	end component stimulus_driver_Register_file;

  -- Temporary signals to connect to the Register_file component.
	signal s_CLK, s_RST, s_WE  : std_logic;
	signal READ1, READ2 : std_logic_vector(31 downto 0);
	signal s_D : std_logic_vector(31 downto 0);
	signal WRITE_SEL : std_logic_vector(4 downto 0);
	signal READ_SEL1 : std_logic_vector(4 downto 0);
	signal READ_SEL2 : std_logic_vector(4 downto 0);


begin
	stimulus_d: stimulus_driver_Register_file
		generic map(ITERATIONS => ITERATIONS, CLK_Period => CLK_PERIOD)	
		port map(
			RANDOM_DATA  => s_D, 
	    	CONTROL_LOAD => s_WE, 
	  		RESET        => s_RST,
			WRITE_SEL    => WRITE_SEL,
			READ_SEL1 => READ_SEL1,
			READ_SEL2 => READ_SEL2);

	DUT: Register_file 
		port map(
				 CLOCK_IN => s_CLK,                                      -- Clock input for registers
			 	 DATA_TO_WRITE_IN => s_D, 	       -- Data to load
			 	 WRITE_EN_IN  => s_WE,                                  -- to control the decoder
			 	 REG_RST_IN   => s_RST,                                  -- to clear all the register
			 	 WRITE_SEL_IN => WRITE_SEL, -- select register to load
			 	 READ_SEL1_IN => READ_SEL1, -- select register 1 to read
			 	 READ_SEL2_IN => READ_SEL2, -- select register 2 to read
			 	 DATA_TO_READ1_OUT => READ1,	   -- selected register 1 out
			 	 DATA_TO_READ2_OUT => READ2      -- selected register 2 out
			);

  -- This process sets the clock value (low for gCLK_HPER, then high
  -- for gCLK_HPER). Absent a "wait" command, processes restart 
  -- at the beginning once they have reached the final statement.
  P_CLK: process
  begin
    s_CLK <= '1';
	wait for CLK_PERIOD/2; -- half of it is 1
    s_CLK <= '0';
	wait for CLK_PERIOD/2; -- half of it is 0
  end process;
  
end behavior;

