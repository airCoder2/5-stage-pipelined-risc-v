-- Date        : March 5, 2026
-- File        : Main_conrol_unit.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements the main control unit 

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Main_control_unit is
	port(
            i_Opcode  : in std_logic_vector(6 downto 0); -- the opcode we are decoding
            o_ALU_op  : out std_logic_vector(1 downto 0); -- two bit ALU opcode
            o_Imm_select : out std_logic_vector(2 downto 0); -- which immediate ALU should use  
            o_ALU_A_src : out std_logic; -- control for choosing between pc  or rs1 out
            o_ALU_src : out std_logic; -- control for choosing between imm or rs2 out
            o_mem_WE  : out std_logic; -- control to when data mem can be written
            o_ALU_mem : out std_logic;  -- control for writing to reg from ALU or memory
            o_reg_file_WE  : out std_logic;  -- control for when data to reg file is written 
            o_lui     : out std_logic; -- when 1, routes immediate and not the ALU out to reg
            o_branch  : out std_logic; -- should branch or no
            o_jal     : out std_logic;
            o_jalr    : out std_logic;
            o_halt : out std_logic --used as wfi
        );
	
end entity Main_control_unit;

architecture behavioral of Main_control_unit is

    constant OP_RTYPE  : std_logic_vector(6 downto 0) := "0110011";
    constant OP_ITYPE  : std_logic_vector(6 downto 0) := "0010011";
    constant OP_LOAD   : std_logic_vector(6 downto 0) := "0000011";
    constant OP_STORE  : std_logic_vector(6 downto 0) := "0100011";
    constant OP_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
    constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
    constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
    constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";
    constant OP_HALT   : std_logic_vector(6 downto 0) := "1110011";

begin
    with i_Opcode select
        o_ALU_op <=
            2b"11" when OP_RTYPE, -- depends on func3 and func7
            2b"10" when OP_ITYPE, -- depends on func3 and func7
            2b"01" when OP_BRANCH, -- branch subtracts all the time
            2b"00" when OP_LOAD,  -- add immediate + addr to generate full address
            2b"00" when OP_STORE, -- add immediate + addr to generate full address
            2b"00" when OP_AUIPC, -- add pc + sign extended immediate
            2b"00" when OP_JAL,
            2b"00" when OP_JALR,
            2b"--" when OP_LUI,   -- LUI doesn't use any of the components
            2b"00" when others; 
            
    with i_Opcode select
        o_reg_file_WE <= 
            '1' when OP_RTYPE, -- R type instructions like add, sub write to regFile
            '1' when OP_ITYPE, -- I type instructions like addi write to regFile
            '0' when OP_BRANCH, -- branch doesn't write to reg file
            '1' when OP_LOAD,  -- Load writes to RegFile, loads value from mem to regFile
            '0' when OP_STORE, -- Store doesn't write to RegFile, only reads it
            '1' when OP_AUIPC, 
            '1' when OP_JAL,
            '1' when OP_JALR,
            '1' when OP_LUI,   -- LUI writes to RegFile imm << 12
            '0' when others;

    with i_Opcode select
        o_mem_WE <= 
            '0' when OP_RTYPE, -- R type instructions like add, sub don't write to ram
            '0' when OP_ITYPE, -- I type instructions like addi don't write to ram
            '0' when OP_LOAD,  -- Load doesn't write to ram, it reads it
            '0' when OP_BRANCH, -- branch doesn't write to memory 
            '0' when OP_AUIPC,
            '0' when OP_JAL,
            '0' when OP_JALR,
            '1' when OP_STORE, -- Store writes to ram 
            '0' when OP_LUI,   -- LUI doesn't write to memory
            '0' when others;

    with i_Opcode select
        o_ALU_mem <=
            '0' when OP_RTYPE, -- R type instructions like add, sub write to reg file from ALU
            '0' when OP_ITYPE, -- I type instructions like addi write to reg file from ALU
            '1' when OP_LOAD,  -- Load writes to reg file from Memory
            '0' when OP_AUIPC,
            '0' when OP_JAL,
            '0' when OP_JALR,
            '0' when OP_LUI,   -- LUI writes to reg file from ALU output
            '-' when OP_BRANCH, -- branch doesn't write to reg file, so doesn't matter
            '-' when OP_STORE, -- Store doesn't write to reg file. Therefore, don't care
            '0' when others;


    with i_Opcode select
        o_ALU_src <=
            '0' when OP_RTYPE, -- R type instructions like add, sub take both opearands from regFile
            '1' when OP_ITYPE, -- I type instructions like addi, take operands from regFile and extended imm
            '1' when OP_LOAD,  -- Load takes operands from regFile and extended imm
            '1' when OP_STORE, -- Store takes operands from regFile and extended imm
            '1' when OP_AUIPC, -- AUIPC adds current pc to sign extended immediate
            '-' when OP_JAL,
            '-' when OP_JALR,
            '1' when OP_LUI,   -- LUI uses immediate and routes it to reg file through ALU
            '0' when OP_BRANCH, -- branch subtracts rs1 - rs2
            '0' when others;

    with i_Opcode select
        o_ALU_A_src <=
            '1' when OP_AUIPC, -- auipc adds current PC to sign extended immediate
            '0' when OP_RTYPE, -- R type instructions like add, sub take both opearands from regFile
            '0' when OP_ITYPE, -- I type instructions like addi, take operands from regFile and extended imm
            '0' when OP_LOAD,  -- Load takes operands from regFile and extended imm
            '1' when OP_JAL,
            '1' when OP_JALR,
            '0' when OP_STORE, -- Store takes operands from regFile and extended imm
            '0' when OP_BRANCH, -- branch subtracts rs1 - rs2
            '-' when OP_LUI,   -- LUI uses immediate and routes it to reg file through ALU
            '0' when others;


    with i_Opcode select
        o_Imm_select <=
            3b"000" when OP_ITYPE, -- I type instructions like addi use sign extended immediates
            3b"000" when OP_LOAD,  -- LOAD is an I type instruction with unique flags. So same extension works 
            3b"001" when OP_STORE, -- STORE is its own type, and thus choses a unique extended immediate
            3b"011" when OP_LUI,   -- LUI has a uniquie opcode, but both AUIPC and LUI use the same imm
            3b"011" when OP_AUIPC,   -- LUI has a uniquie opcode, but both AUIPC and LUI use the same imm
            3b"010" when OP_BRANCH, -- Has a unique immedaite
            3b"100" when OP_JAL,
            3b"000" when others;

    -- consider branching for any branch type instructions
    with i_Opcode select
        o_branch <=
            '1' when OP_BRANCH, 
            '0' when others;

    with i_Opcode select
        o_jal <=
            '1' when OP_JAL, 
            '0' when others;

    with i_Opcode select
        o_jalr <=
            '1' when OP_JALR, 
            '0' when others;

    with i_Opcode select
        o_lui <=
            '1' when OP_LUI, 
            '0' when others;

    with i_Opcode select
        o_halt <=
            '1' when OP_HALT, 
            '0' when others;

end behavioral;

