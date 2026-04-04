-- Date        : Feb 23, 2026
-- File        : PC_adder.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for a PC adder 

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_PC_adder is
end entity tb_PC_adder;


architecture behavioral of tb_PC_adder is

    component PC_adder is
        port(i_current_pc : in  std_logic_vector(31 downto 0);
             o_new_pc     : out std_logic_vector(31 downto 0));
    end component PC_adder;

    signal s_iCurrent_pc : std_logic_vector(31 downto 0);
    signal s_oNew_pc     : std_logic_vector(31 downto 0);

begin
    DUT: PC_adder
        port map(
                 i_current_pc  => s_iCurrent_pc,
                 o_new_pc      => s_oNew_pc);

    process
    begin

        s_iCurrent_pc <= 32x"00000000";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"00000010";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"00000C00";
        
        s_iCurrent_pc <= 32x"0000FC00";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"00AC000F";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"00F00004";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"0080000F";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"9405001C";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"00089008";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"00000F00";
        wait for 10 ns;
        
        s_iCurrent_pc <= 32x"0000D00D";
        wait for 10 ns;

        wait;
    end process;
end architecture;

