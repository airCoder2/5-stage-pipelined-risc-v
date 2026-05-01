-- Date        : April 27, 2026
-- File        : CSR_write_data_gen.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements the logic box that decides what to write to csr register  

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity CSR_write_data_gen is
    port(
         i_func3                 : in  std_logic_vector(1 downto 0);  -- Function 3 for determening what type of csr instruction it is
         i_csr_data              : in  std_logic_vector(31 downto 0); -- CSR data to generate a masked output incase it is csrrs or csrrc
         i_csr_addr              : in  std_logic_vector(11 downto 0); -- for masking the non writible bits if csr reg bits has WRPI
         i_extended_rs1_or_read1 : in  std_logic_vector(31 downto 0); -- Extended rs1 or reg1_data as new vaue incase csrrw or csrrwi
         o_csr_new_data          : out std_logic_vector(31 downto 0)  -- New csr value to be written
        );
end entity CSR_write_data_gen;

architecture structural of CSR_write_data_gen is

    constant REG_mstatus_addr  : std_logic_vector(11 downto 0) := 12x"300";
    constant REG_mtvec_addr    : std_logic_vector(11 downto 0) := 12x"305";
    constant REG_mscratch_addr : std_logic_vector(11 downto 0) := 12x"340";
    constant REG_mepc_addr     : std_logic_vector(11 downto 0) := 12x"341";
    constant REG_mcause_addr   : std_logic_vector(11 downto 0) := 12x"342";

    signal s_csr_new_data_before_WRPI_masking : std_logic_vector(31 downto 0);

begin 
    -- note that the correct operand (extended_rs1_or_read1) is selected in the previous pipeline stage
    s_csr_new_data_before_WRPI_masking <= 
                         i_extended_rs1_or_read1 when (i_func3(1) = '0') else -- pass through when CSRRW{*}
                         (i_csr_data or i_extended_rs1_or_read1) when (i_func3(0) = '0') else -- use rs1_or_read1 as mask to set the bits of csr_data when CSRRS{*}
                         i_csr_data and (not i_extended_rs1_or_read1);      -- last option possible. use not rs1_or_read1 to clr the bits of csr_data when CSRRC{*}

    -- 32b"10000001111111111111111111101010" -- for M mode
    -- Mask if should be masked
    with i_csr_addr(7 downto 0) select
        o_csr_new_data <= 
                       (s_csr_new_data_before_WRPI_masking and 32x"00000011")when REG_mstatus_addr(7 downto 0),
                       (s_csr_new_data_before_WRPI_masking)when REG_mtvec_addr(7 downto 0),   
                       (s_csr_new_data_before_WRPI_masking)when REG_mscratch_addr(7 downto 0),
                       (s_csr_new_data_before_WRPI_masking)when REG_mepc_addr(7 downto 0),    
                       (s_csr_new_data_before_WRPI_masking)when REG_mcause_addr(7 downto 0),  
                       32x"00000000"  when others;
end architecture;



