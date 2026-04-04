-- Date        : March 6, 2026
-- File        : tb_Main_control_unit.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for the main control unit 

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_Main_control_unit is
end entity tb_Main_control_unit;

architecture behavioral of tb_Main_control_unit is
     
    constant OP_RTYPE  : std_logic_vector(6 downto 0) := "0110011";
    constant OP_ITYPE  : std_logic_vector(6 downto 0) := "0010011";
    constant OP_LOAD   : std_logic_vector(6 downto 0) := "0000011";
    constant OP_STORE  : std_logic_vector(6 downto 0) := "0100011";
    constant OP_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
    constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
    constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
    constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";

    component Main_control_unit is
        port(
             i_Opcode       : in  std_logic_vector(6 downto 0);
             o_ALU_op       : out std_logic_vector(1 downto 0);
             o_ALU_src      : out std_logic;
             o_mem_WE       : out std_logic;
             o_zero_sign    : out std_logic;
             o_ALU_mem      : out std_logic;
             o_reg_file_WE  : out std_logic
        );
    end component;

    -- Signals
    signal s_iOpcode      : std_logic_vector(6 downto 0);
    signal s_oALU_op      : std_logic_vector(1 downto 0);
    signal s_oALU_src     : std_logic;
    signal s_oMem_WE      : std_logic;
    signal s_oZero_sign   : std_logic;
    signal s_oALU_mem     : std_logic;
    signal s_oReg_file_WE : std_logic;

begin            

    DUT: Main_control_unit 
        port map(
            i_Opcode       => s_iOpcode,
            o_ALU_op       => s_oALU_op,
            o_ALU_src      => s_oALU_src,
            o_mem_WE       => s_oMem_WE,
            o_zero_sign    => s_oZero_sign,
            o_ALU_mem      => s_oALU_mem,
            o_reg_file_WE  => s_oReg_file_WE
        );

    -- Stimulus process
    stimulus : process
    begin

        -- R-Type
        s_iOpcode <= OP_RTYPE;
        wait for 10 ns;

        -- I-Type
        s_iOpcode <= OP_ITYPE;
        wait for 10 ns;

        -- LOAD
        s_iOpcode <= OP_LOAD;
        wait for 10 ns;

        -- STORE
        s_iOpcode <= OP_STORE;
        wait for 10 ns;

        -- BRANCH
        s_iOpcode <= OP_BRANCH;
        wait for 10 ns;

        -- JAL
        s_iOpcode <= OP_JAL;
        wait for 10 ns;

        -- JALR
        s_iOpcode <= OP_JALR;
        wait for 10 ns;

        -- LUI
        s_iOpcode <= OP_LUI;
        wait for 10 ns;

        -- AUIPC
        s_iOpcode <= OP_AUIPC;
        wait for 10 ns;

        wait;

    end process;

end architecture behavioral;
