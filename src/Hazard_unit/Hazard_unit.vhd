-- Date        : April 10, 2026
-- File        : Hazard_unit.vhd   
-- Designer    : Salah Nasriddinov
-- Description : This file implements a Hazard Controller 

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all; -- use the types

entity Hazard_unit is
    port(
         i_ex_ALU_mem : std_logic;
         i_id_mem_WE  : std_logic;
         i_ex_pc_source : std_logic;
         o_flush_id     : std_logic;
         o_stall_id     : std_logic;
         )

end entity Hazard_unit;
