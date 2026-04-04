-- Date        : March 20, 2026
-- File        : XOR_unit.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements the XOR unit

library IEEE;
use IEEE.std_logic_1164.all;

entity XOR_unit is
    port (
          i_A   : in std_logic_vector(31 downto 0);
          i_B   : in std_logic_vector(31 downto 0);
          o_out : out std_logic_vector(31 downto 0));
end entity XOR_unit;

architecture structural of XOR_unit is

    component two_input_xor is
        port( A : in std_logic;
              B : in std_logic;
              F : out std_logic);
    end component two_input_xor;

begin
    XOR_inst : for i in 0 to 31 generate
        XOR_I : two_input_xor
                port map (
                          A => i_A(i),
                          B => i_B(i),
                          F => o_out(i)
                      );
        end generate XOR_inst;

end architecture structural;

