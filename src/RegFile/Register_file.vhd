-- Date        : Feb 10, 2026
-- File        : Register_file.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 32 bit register file 
-- Note        : This file does not have any generics, because some of the
--               components used are not configurable

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;
use IEEE.math_real.all;
use work.RISCV_types.all;

entity Register_file is

	port(CLOCK_IN : in std_logic;                                -- Clock input for registers
		 DATA_TO_WRITE_IN : in std_logic_vector(31 downto 0); 	 -- Data to load
		 WRITE_EN_IN  : in std_logic;                            -- to control the decoder
		 REG_RST_IN   : in std_logic;                            -- to clear all the register
		 WRITE_SEL_IN : in std_logic_vector(4 downto 0); 		 -- select register to load
		 READ_SEL1_IN : in std_logic_vector(4 downto 0);         -- select register 1 to read
		 READ_SEL2_IN : in std_logic_vector(4 downto 0);         -- select register 2 to read
		 DATA_TO_READ1_OUT: out std_logic_vector(31 downto 0); 	 -- selected register 1 out
		 DATA_TO_READ2_OUT: out std_logic_vector(31 downto 0)    -- selected register 2 out
		);
	
end entity Register_file;

architecture structural of Register_file is

	component Bus_32_bit_Mux_32_to_1 is
		port(BUS_IN     : in reg_outs_t; 					-- defined inside the package I made
			 SELECT_IN  : in std_logic_vector(4 downto 0);  -- 4 bit input to select a register to read from
			 MUX_OUT    : out std_logic_vector(31 downto 0)); -- 32bit output for the output of the register
	end component Bus_32_bit_Mux_32_to_1;
																			  -- with 32 bit outs

	component N_bit_register is -- N_bit_register that takes a generic, in this case it is 32 fixed.
        generic(N : integer; Reset_value : std_logic_vector);
        port(i_CLK  : in std_logic;						   -- Clock input
           i_RST    : in std_logic;						   -- Reset input
           i_WE     : in std_logic;   					   -- All register connected
           i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
           o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
	end component N_bit_register;   
	

	component Decoder_5_to_32 is
		port(EN_IN   : in std_logic; 					-- An input to enable the decoder
			 CODE_IN : in std_logic_vector(4 downto 0); -- we have 5 bits for code
			 F_OUT   : out std_logic_vector(31 downto 0)); -- we have 32 bit output to select a reg to write to
	end component Decoder_5_to_32;

	signal DECODED_WRITE_REG : std_logic_vector(31 downto 0); --  wire to hold the output of the decoder
	signal REG_OUTS			 : reg_outs_t; 					  -- a wire to hold the outputs of the 32 bit registers

begin
	-- Decoder used for decoding the binary that selects which register to load new data to
	decoder: Decoder_5_to_32 port map( -- A decoder used for selecting which register to write to
			 EN_IN => WRITE_EN_IN, -- A one bit input to enable the decoder
			 CODE_IN => WRITE_SEL_IN, -- The 5 bit adress that selects one of the 32 bit registers to write
			 F_OUT => DECODED_WRITE_REG -- output of the decoder then hooked up to registers enable(mux) 
			);

	
	REG_OUTS(0) <= (others => '0'); -- reg 0 is all 0, writing to it is effectless

	-- 32 bit register, generated 32 times to make the full register
	N_32bit_Registers: for i in 1 to 31 generate
    begin
        IF_SP: if i = 2 generate
            a_32bit_register_SP: N_bit_register 
            generic map(N => 32, Reset_value => 32x"7FFFEFFC") -- specify how many bits a register is
                port map(
                i_CLK => CLOCK_IN,	-- clock
                i_RST => REG_RST_IN, -- reset that resets all the register values
                i_WE  => DECODED_WRITE_REG(i), -- EN to load a new value. Decoders output is used to control
                i_D   => DATA_TO_WRITE_IN, -- The new value itself, all the regs connected to the same data	
                o_Q   => REG_OUTS(i) -- the output of the register is connected to i't 32bit bus
            ); 
        end generate IF_SP;

        IF_OTHER: if i /= 2 generate
            a_32bit_register_I: N_bit_register 
            generic map(N => 32, Reset_value => 32x"00000000") -- specify how many bits a register is
                port map(
                i_CLK => CLOCK_IN,	-- clock
                i_RST => REG_RST_IN, -- reset that resets all the register values
                i_WE  => DECODED_WRITE_REG(i), -- EN to load a new value. Decoders output is used to control
                i_D   => DATA_TO_WRITE_IN, -- The new value itself, all the regs connected to the same data	
                o_Q   => REG_OUTS(i) -- the output of the register is connected to i't 32bit bus
            ); 
        end generate IF_OTHER;
    end generate;

	-- The 32 bit BUS mux to select a register to read1 from
	a_32to1_Mux1_I: Bus_32_bit_Mux_32_to_1 port map(
		BUS_IN => REG_OUTS, -- BUS_IN and REG_OUTS are both of type arrays of buses
		SELECT_IN => READ_SEL1_IN, -- input to select the register to read from
		MUX_OUT => DATA_TO_READ1_OUT -- the output of that register
	);

	-- The 32 bit BUS mux to select a register to read2 from
	a_32to1_Mux2_I: Bus_32_bit_Mux_32_to_1 port map(
		BUS_IN => REG_OUTS, -- BUS_IN and REG_OUTS are both of type arrays of buses
		SELECT_IN => READ_SEL2_IN, -- input to select the register to read from
		MUX_OUT => DATA_TO_READ2_OUT -- the output of that register
	);

end architecture structural;
