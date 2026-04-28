-- Date        : Feb 16, 2026
-- File        : bus_types_pkg.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a package to be used

-------------------------------------------------------------------------
-- Description: This file contains a skeleton for some types that 381 students
-- may want to use. This file is guarenteed to compile first, so if any types,
-- constants, functions, etc., etc., are wanted, students should declare them
-- here.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package RISCV_types is

	-- 32 inputs x 32-bite wide
	type reg_outs_t is array(31 downto 0) of std_logic_vector(31 downto 0); -- type for signal 

	-- 16 inputs x 32-bite wide
	type alu_outs_t is array(15 downto 0) of std_logic_vector(31 downto 0); -- type for signal 


    type Fetch_decode_data_t is record 
        current_PC   : std_logic_vector(31 downto 0); -- PC value for auipc, branch, jal, jalr
        Inst : std_logic_vector(31 downto 0); -- Instruction to decode
    end record Fetch_decode_data_t;

    type Decode_execute_data_t is record
        halt                    : std_logic;
        reg_WE                  : std_logic; -- reg write enable
        branch                  : std_logic;
        jal                     : std_logic;     
        jalr                    : std_logic;
        current_pc              : std_logic_vector(31 downto 0);
        ALU_mem                 : std_logic;
        ALU_src                 : std_logic;
        ALU_A_src               : std_logic;
        read1                   : std_logic_vector(31 downto 0);
        read2                   : std_logic_vector(31 downto 0);
        Extended_imm            : std_logic_vector(31 downto 0);
        rd                      : std_logic_vector(4 downto 0); -- rd
        ALU_mux_select          : std_logic_vector(2 downto 0);
        ALU_nAdd_sub            : std_logic;
        ALU_logcl_arith         : std_logic;
        ALU_right_left          : std_logic;
        func3                   : std_logic_vector(2 downto 0);
        mem_WE                  : std_logic; --mem write enable 
        rs1                     : std_logic_vector(4 downto 0);
        rs2                     : std_logic_vector(4 downto 0);
        notTaken_taken          : std_logic;
        predicted_counter_index : std_logic_vector(2 downto 0);
        --CSRs
        csr                     : std_logic; -- control flag to indicate a CSR instruction
        csr_data                : std_logic_vector(31 downto 0); -- the data CSR reg had
        csr_write_addr          : std_logic_vector(11 downto 0); -- the address of the CSR reg to be written (same as read)

    end record Decode_execute_data_t;

    type Execute_memory_data_t is record
        halt           : std_logic;
        reg_WE         : std_logic;  -- reg write enabl
        ALU_mem        : std_logic;
        ALU_out        : std_logic_vector(31 downto 0);
        mem_WE         : std_logic;  -- mem write enable
        reg_data_2     : std_logic_vector(31 downto 0);
        rd             : std_logic_vector(4 downto 0); -- rd
        func3          : std_logic_vector(2 downto 0);
        rs2            : std_logic_vector(4 downto 0); -- rs2 (for lw sw use hazard)
        --CSRs
        csr            : std_logic;  -- control flag to indicate a CSR instruction
        csr_data       : std_logic_vector(31 downto 0); -- the data CSR reg had
        csr_write_addr : std_logic_vector(11 downto 0); -- the address of the CSR reg to be written (same as read)
        rs1_or_fread1  : std_logic_vector(31 downto 0); -- Extended rs1 or Forwarded read 1
    end record Execute_memory_data_t;


    type Memory_wback_data_t is record
        reg_WE         : std_logic;  -- reg write enable
        ALU_mem        : std_logic;
        ALU_out        : std_logic_vector(31 downto 0);
        rd             : std_logic_vector(4 downto 0); -- rd
        dmem_out       : std_logic_vector(31 downto 0);
        halt           : std_logic;
        --CSRs
        csr            : std_logic; -- control flag to indicate a CSR instruction
        csr_new_data   : std_logic_vector(31 downto 0); -- value of the data to be written to the CSR reg
        csr_write_addr : std_logic_vector(11 downto 0); -- the address of the CSR reg to be written (same as read)
    end record Memory_wback_data_t;

end package RISCV_types;

