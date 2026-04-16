-- Date        : April 15, 2026
-- File        : branch_prediction.vhd     
-- Designer    : Salah Nasriddinov
-- Description: This file implements the branch prediction unit

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Branch_prediction is
    port(
         i_was_branch_wrong : in  std_logic;
         i_jalr             : in  std_logic; -- if jalr, output not taken
         o_notTaken_taken   : out std_logic);

end entity Branch_prediction;

architecture behavioral of Branch_prediction is
begin

    with i_jalr select
        o_notTaken_taken <= '0' when '1',    -- when jalr, don't take
                            '1' when others; -- by default take

end architecture;

