-- Date        : March 20, 2026
-- File        : OR_unit.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements the OR unit

library IEEE;
use IEEE.std_logic_1164.all;

entity OR_unit is
    port (
          i_A   : in std_logic_vector(31 downto 0);
          i_B   : in std_logic_vector(31 downto 0);
          o_out : out std_logic_vector(31 downto 0));
end entity OR_unit;

architecture structural of OR_unit is

    component two_input_or is
        port( A : in std_logic;
              B : in std_logic;
              F : out std_logic);
    end component two_input_or;

begin
    OR_inst : for i in 0 to 31 generate
        OR_I : two_input_or
                port map (
                          A => i_A(i),
                          B => i_B(i),
                          F => o_out(i)
                      );
        end generate OR_inst;

end architecture structural;

