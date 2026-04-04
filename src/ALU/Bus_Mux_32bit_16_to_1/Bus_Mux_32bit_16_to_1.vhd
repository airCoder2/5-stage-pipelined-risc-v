-- Date        : March 7, 2026
-- File        : Bus_Mux_32bit_16_to_1.vhd    
-- Designer    : Salah Nasriddinov
-- Description : This file implements 32 bit wide  16 to 1 mux 

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity Bus_32_bit_Mux_16_to_1 is

	port(BUS_IN     : in alu_outs_t; 
		 SELECT_IN  : in std_logic_vector(3 downto 0);
	     MUX_OUT    : out std_logic_vector(31 downto 0));

end entity Bus_32_bit_Mux_16_to_1;

architecture structural of Bus_32_bit_Mux_16_to_1 is

	component Mux_16_to_1 is
        port(DATA_IN   : in std_logic_vector(15 downto 0);
             SELECT_IN : in std_logic_vector(3 downto 0);
             MUX_OUT   : out std_logic);
	end component Mux_16_to_1;

begin
  -- Instantiate N mux instances, 
	G_NBit_bus_MUX_I: for i in 0 to 31 generate
		MUXI: Mux_16_to_1 port map(
		DATA_IN => (
			0  => BUS_IN(0)(i),
			1  => BUS_IN(1)(i),
			2  => BUS_IN(2)(i),
			3  => BUS_IN(3)(i),
			4  => BUS_IN(4)(i),
			5  => BUS_IN(5)(i),
			6  => BUS_IN(6)(i),
			7  => BUS_IN(7)(i),
			8  => BUS_IN(8)(i),
			9  => BUS_IN(9)(i),
			10 => BUS_IN(10)(i),
			11 => BUS_IN(11)(i),
			12 => BUS_IN(12)(i),
			13 => BUS_IN(13)(i),
			14 => BUS_IN(14)(i),
			15 => BUS_IN(15)(i)
        ),

		SELECT_IN    => SELECT_IN,
		MUX_OUT      => MUX_OUT(i));      -- All instances share the same select input.
	end generate G_NBit_bus_MUX_I;
  
end architecture structural;

