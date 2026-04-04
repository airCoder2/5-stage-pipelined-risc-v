-- Date        : Feb 4, 2026
-- File        : d_flip_flop.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a D-flip-flop with synchronous reset

library IEEE;
use IEEE.std_logic_1164.all;

entity d_flip_flop is
    generic(Reset_value : std_logic);
	port(i_CLK        : in std_logic;     -- Clock input
		 i_RST        : in std_logic;     -- Reset input
		 i_D          : in std_logic;     -- Data value input
		 o_Q          : out std_logic);   -- Data value output
end entity d_flip_flop;

architecture behavioral of d_flip_flop is

	signal s_Q : std_logic; -- intermediate wire connected to

begin
	o_Q <= s_Q; -- assign the output to s_Q, which is controlled below

	process (i_CLK)
		begin
		if (i_RST = '1') then
            s_Q <= Reset_value; -- whatever passed as an argumet, assign that as reset value
		elsif (rising_edge(i_CLK)) then
			s_Q <= i_D; -- every rising edge, make s_Q = i_D
		end if;

	end process;

end architecture behavioral;
