-- Date        : April 15, 2026
-- File        : branch_history_shift_reg.vhd     
-- Designer    : Salah Nasriddinov
-- Description: This file implements a history shift register

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Branch_history_shift_reg is
    port(
             i_clock   : in  std_logic;
             i_reset   : in  std_logic;
             i_we      : in std_logic;
             i_new_val : in std_logic;
             o_reg_out : out std_logic_vector(2 downto 0));
end entity Branch_history_shift_reg;

architecture structural of Branch_history_shift_reg is

    component one_bit_register is
        generic(Reset_value : std_logic; Bypass_register : boolean);
            port(i_CLK      : in std_logic;     -- Clock input
               i_RST        : in std_logic;     -- Reset input
               i_WE         : in std_logic;     -- Write enable input
               i_D          : in std_logic;     -- Data value input
               o_Q          : out std_logic);   -- Data value output
    end component one_bit_register;

    signal s_reg_out : std_logic_vector(3 downto 0);


begin
    s_reg_out(0) <= i_new_val;

    Branch_history_shift_reg_gen: for i in 1 to 3 generate

        Branch_history_shift_reg_inst_I: one_bit_register
            generic map(Reset_value => '0', Bypass_register => false)
            port map(i_CLK    => i_clock,  
                     i_RST    => i_reset,
                     i_WE     => i_we,
                     i_D      => s_reg_out(i-1), 
                     o_Q      => s_reg_out(i));
    end generate;

    o_reg_out <= s_reg_out(3 downto 1);

end architecture;
