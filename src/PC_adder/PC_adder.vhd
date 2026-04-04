-- Date        : March 5, 2026
-- File        : PC_adder.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a PC adder that adds 4
-- Components  : ripple_carry_N_bit_adder (a subcomponent that I did for my adder)

library IEEE;
use IEEE.std_logic_1164.all;


entity PC_adder is
    port(i_current_pc : in  std_logic_vector(31 downto 0); -- current pc, 
         o_new_pc     : out std_logic_vector(31 downto 0)); -- output (current + 4)
end PC_adder;


architecture structural of PC_adder is

    component ripple_carry_N_bit_adder is
        generic (N : integer);
            port( x  	   : in std_logic_vector(N-1 downto 0);
                  y        : in std_logic_vector(N-1 downto 0);
                  c_in     : in std_logic;
                  sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
                  c_out    : out std_logic;
                  overflow : out std_logic);
    end component ripple_carry_N_bit_adder;
    

begin
    Adder: ripple_carry_N_bit_adder
            generic map(N => 32)
            port map(
                     x        => i_current_pc,
                     y        => 32x"00000004",
                     c_in     => '0',
                     sum      => o_new_pc,
                     c_out    => open,
                     overflow => open
                 );
end structural;

