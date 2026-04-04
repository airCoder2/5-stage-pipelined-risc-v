-- Date        : Feb 5, 2026
-- File        : N_bit_register.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements an N-bit synchronous reset

library IEEE;
use IEEE.std_logic_1164.all;

entity N_bit_register is
	generic(N : integer; Reset_value : std_logic_vector);
	port(i_CLK  : in std_logic;						   -- Clock input
	   i_RST    : in std_logic;						   -- Reset input
	   i_WE     : in std_logic;   					   -- All register connected
	   i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
	   o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
end entity N_bit_register;   

architecture structural of N_bit_register is

-- Component one-bit regster
    component one_bit_register is
        generic(Reset_value : std_logic);
        port(i_CLK      : in std_logic;     -- Clock input
           i_RST        : in std_logic;     -- Reset input
           i_WE         : in std_logic;     -- Write enable input
           i_D          : in std_logic;     -- Data value input
           o_Q          : out std_logic);   -- Data value output
    end component one_bit_register;
	
begin
    N_Registers: for i in 0 to N-1 generate
        register_i: one_bit_register
            generic map(Reset_value => Reset_value(i))
            port map(
                i_CLK => i_CLK,
                i_RST => i_RST,
                i_WE  => i_WE,
                i_D   => i_D(i),
                o_Q   => o_Q(i));
    end generate;


end architecture structural;





