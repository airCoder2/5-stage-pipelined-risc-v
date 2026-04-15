-- Date        : April 10, 2026
-- File        : Hazard_unit.vhd   
-- Designer    : Salah Nasriddinov
-- Description : This file implements a Hazard Controller 

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all; -- use the types

entity Hazard_unit is
    port(
         i_ALU_mem_ex    : in  std_logic;  -- lw
         i_mem_WE_id     : in  std_logic;  -- sw
         i_pc_source_ex  : in  std_logic; 
         i_rd_ex         : in std_logic_vector(4 downto 0);
         i_rs1_id         : in std_logic_vector(4 downto 0);
         i_rs2_id         : in std_logic_vector(4 downto 0);
         i_ALU_src_id     : in std_logic;
         i_ALU_A_src_id   : in std_logic;
         o_flush_id    : out  std_logic; 
         o_stall_id    :  out  std_logic
         );
end entity Hazard_unit; 

architecture behavioral of Hazard_unit is
begin
    o_flush_id <= i_pc_source_ex;

    o_stall_id <=
               '1' when ((i_ALU_mem_ex = '1') and  -- if it is lw
                                                   -- if that lw is writing to  rs1,                    or       if that lw is writing to rs2,  or if this instruction is sw
                        ((  (i_rd_ex = i_rs1_id) and (i_ALU_A_src_id = '0')   ) or  (   (i_rd_ex = i_rs2_id) and (i_ALU_src_id = '0')   ) /*or (i_mem_WE_id = '1')*/)) else 
               '0';

end architecture;
                                                                                                                                                                                        
                                                                                                                                                                                        
                                                 
