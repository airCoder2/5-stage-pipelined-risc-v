-- Date        : April 7, 2026
-- File        : Forwarding_unit.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a forwarding unit 

library IEEE;
use IEEE.std_logic_1164.all;


entity Forwarding_unit is
    port(i_rs1             : in std_logic_vector(4 downto 0); -- rs1 of the instruction at EX
         i_rs2             : in std_logic_vector(4 downto 0); -- rs2 of the instruction at EX
         i_ALU_A_src       : in std_logic; -- are we using rs1, or maybe PC?
         i_ALU_src         : in std_logic; -- are we using rs2, or maybe immediate?
         i_MEM_rd          : in std_logic_vector(4 downto 0); -- rd of instruction at MEM
         i_WB_rd           : in std_logic_vector(4 downto 0); -- rd of instruction at WB
         i_MEM_reg_WE      : in std_logic; -- does the instruction at MEM write to reg file?
         i_WB_reg_WE       : in std_logic; -- does the instruction at WB  write to reg file?
         o_ALU_A_frwrd_sel : out std_logic_vector(1 downto 0); -- select one of the paths to ALU_A
         o_ALU_B_frwrd_sel : out std_logic_vector(1 downto 0) -- select one of the paths to ALU_B
     ); 
end entity Forwarding_unit;
