-- Date        : March 21, 2026
-- File        : Branch_decision.vhd     
-- Designer    : Salah Nasriddinov
-- Description: This file implements a branch decision box

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity branch_decision is
    port (
          i_eq            : in std_logic;
          i_lt            : in std_logic;
          i_ltu           : in std_logic;
          i_ge            : in std_logic;
          i_geu           : in std_logic;
          i_is_branch     : in std_logic;
          i_func3         : in std_logic_vector(2 downto 0);
          o_should_branch : out std_logic);
end entity branch_decision;

architecture rtl of branch_decision is

    signal s_branch_taken : std_logic;

begin

    -- Decode func3 to select the correct comparison result
    with i_func3 select
        s_branch_taken <= i_eq  when "000",  -- BEQ
                          (not i_eq)  when "001",  -- BNE  
                          i_lt  when "100",  -- BLT
                          i_ge  when "101",  -- BGE
                          i_ltu when "110",  -- BLTU
                          i_geu when "111",  -- BGEU
                          '0'   when others;

    o_should_branch <= i_is_branch and s_branch_taken;

end architecture rtl;
