-- Date        : Feb 16, 2026
-- File        : N_bit_bus_Mux_32_to_1.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements 32 bit wide  32 to 1 mux 

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity Bus_32_bit_Mux_32_to_1 is

	port(BUS_IN     : in reg_outs_t; --defined inside the package I made
		 SELECT_IN  : in std_logic_vector(4 downto 0);
	     MUX_OUT    : out std_logic_vector(31 downto 0));

end entity Bus_32_bit_Mux_32_to_1;

architecture structural of Bus_32_bit_Mux_32_to_1 is

	component Mux_32_to_1 is
		port(DATA_IN   : in std_logic_vector(31 downto 0); -- input to the mux (32 bit)
			 SELECT_IN : in std_logic_vector(4 downto 0);
			 MUX_OUT   : out std_logic);
	end component Mux_32_to_1;

begin
  -- Instantiate N mux instances, 
	G_NBit_bus_MUX_I: for i in 0 to 31 generate
		MUXI: Mux_32_to_1 port map(
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
			15 => BUS_IN(15)(i),
			16 => BUS_IN(16)(i),
			17 => BUS_IN(17)(i),
			18 => BUS_IN(18)(i),
			19 => BUS_IN(19)(i),
			20 => BUS_IN(20)(i),
			21 => BUS_IN(21)(i),
			22 => BUS_IN(22)(i),
			23 => BUS_IN(23)(i),
			24 => BUS_IN(24)(i),
			25 => BUS_IN(25)(i),
			26 => BUS_IN(26)(i),
			27 => BUS_IN(27)(i),
			28 => BUS_IN(28)(i),
			29 => BUS_IN(29)(i),
			30 => BUS_IN(30)(i),
			31 => BUS_IN(31)(i)
		),

			  SELECT_IN    => SELECT_IN,
			  MUX_OUT      => MUX_OUT(i));      -- All instances share the same select input.
	end generate G_NBit_bus_MUX_I;
  
end architecture structural;

