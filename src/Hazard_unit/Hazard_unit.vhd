-- Date        : April 10, 2026
-- File        : Hazard_unit.vhd   
-- Designer    : Salah Nasriddinov
-- Description : This file implements a Hazard Controller 

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all; -- use the types

entity Hazard_unit is
    port(
         i_ALU_mem_ex           : in  std_logic;  -- lw
         i_mem_WE_id            : in  std_logic;  -- sw
         i_pc_source_ex         : in  std_logic; 
         i_rd_ex                : in  std_logic_vector(4 downto 0);
         i_rs1_id               : in  std_logic_vector(4 downto 0);
         i_rs2_id               : in  std_logic_vector(4 downto 0);
         i_ALU_src_id           : in  std_logic;
         i_ALU_A_src_id         : in  std_logic;
         i_notTaken_taken       : in std_logic;
         i_predicted_wrong_ex   : in  std_logic; 
         i_predicted_correct_ex : in std_logic;
         i_jal_ex               : in std_logic;
         i_jalr_ex              : in std_logic;
         o_flush_IF_ID_id       : out std_logic; 
         o_flush_ID_EX_id       : out std_logic; 
         o_stall_id             : out std_logic
         );
end entity Hazard_unit; 

architecture behavioral of Hazard_unit is
    signal one_cycle_penalty          : std_logic;
    signal two_cycle_penalty          : std_logic;
begin

    
    -- if taken was correct prediction, or jal, then only flush one instruction
    one_cycle_penalty <= '1' when (i_jal_ex =  '1' or (i_predicted_correct_ex = '1' and i_notTaken_taken = '1')) else '0';

    -- if prediction was wrong, or jalr, then flush two instructions
    two_cycle_penalty <= '1' when (i_jalr_ex = '1' or i_predicted_wrong_ex = '1') else '0';

    -- flush IF_ID when wrong prediction or jalr
    o_flush_IF_ID_id <= two_cycle_penalty;

    -- flush ID_EX when both (wrong prediction of jalr) OR (correct but taken or jal)
    o_flush_ID_EX_id <= one_cycle_penalty or two_cycle_penalty;



    -- this does not stall lw followed by sw (mem data hazard, if sw's address depends on lw, then it does, because, 
    -- for address caluclations, we need rs1 in the execute stege), because sw sets i_ALU_src_id to 1. We forard it from WB to MEM_data.
    o_stall_id <=
               '1' when ((i_ALU_mem_ex = '1') and  -- if it is lw
                       -- if that lw is writing to  rs1 of the current instruction, or if it is writing to rs2 of the current inst, then stall
                        (     ((i_rd_ex = i_rs1_id) and (i_ALU_A_src_id = '0')) or  ((i_rd_ex = i_rs2_id) and (i_ALU_src_id = '0')))  ) else 
               '0';


end architecture;
                                                                                                                                                                                        
                                                                                                                                                                                        
                                                 
