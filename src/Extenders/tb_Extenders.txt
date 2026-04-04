-- Date        : Feb 23, 2026
-- File        : Extenders.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for a 12 to 32 signed/unsigned extender

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_Extenders is
end entity tb_Extenders;


architecture behavioral of tb_Extenders is

    component Extenders_wrapper is
        port(
             i_instruction  : in std_logic_vector(31 downto 7);
             i_imm_select   : in std_logic_vector(2 downto 0);
             o_extended_imm : out std_logic_vector(31 downto 0)
            );
    end component;

    signal s_instruction  : std_logic_vector(31 downto 7);
    signal s_imm_select  : std_logic_vector(2 downto 0);
    signal s_out         : std_logic_vector(31 downto 0);

begin
    DUT: Extenders_wrapper
        port map(
                 i_instruction  => s_instruction,
                 i_imm_select  => s_imm_select,
                 o_extended_imm => s_out);

    process
    begin

        s_instruction <= 25b"1111000000000000000000000";
        s_imm_select <= 3b"000";
        wait for 10 ns;
        
        s_instruction <= 25b"0111000000000000000000000";
        s_imm_select <= 3b"000";
        wait for 10 ns;

        s_instruction <= 25b"1000000000000000000000000";
        s_imm_select <= 3b"000";
        wait for 10 ns;
        

        wait;
    end process;
end architecture;

