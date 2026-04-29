-- Date        : April 27, 2026
-- File        : CSR_write_data_gen.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements the logic box that decides what to write to csr register  

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity CSR_write_data_gen is
    port(
         i_func3_mem                 : in  std_logic_vector(2 downto 0);  -- Function 3 for determening what type of csr instruction it is
         i_csr_data_mem              : in  std_logic_vector(31 downto 0); -- CSR data to generate a masked output incase it is csrrs or csrrc
         i_extended_rs1_or_read1_mem : in  std_logic_vector(31 downto 0); -- Extended rs1 or reg1_data as new vaue incase csrrw or csrrwi
         o_csr_new_data_mem          : out std_logic_vector(31 downto 0)  -- New csr value to be written
        );
end entity CSR_write_data_gen;

architecture structural of CSR_write_data_gen is

begin 
    -- note that the correct operand (extended_rs1_or_read1) is selected in the previous pipeline stage
    o_csr_new_data_mem <= 
                         i_extended_rs1_or_read1_mem when (i_func3_mem(1) = '0') else -- pass through when CSRRW{*}
                         i_csr_data_mem or i_extended_rs1_or_read1_mem when (i_func3_mem(0) = '0') else -- use rs1_or_read1 as mask to set the bits of csr_data when CSRRS{*}
                         i_csr_data_mem and (not i_extended_rs1_or_read1_mem);      -- last option possible. use not rs1_or_read1 to clr the bits of csr_data when CSRRC{*}

end architecture;



