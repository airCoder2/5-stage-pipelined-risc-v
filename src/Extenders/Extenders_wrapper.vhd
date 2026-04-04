-- Date        : March 20, 2026
-- File        : Extenders_wrapper.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a wrapper for my extenders
-- Components  : I-type, S-type, SBtype, U-type, UJ-type

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Extenders_wrapper is

	port(
         i_instruction  : in std_logic_vector(31 downto 7);
         i_imm_select   : in std_logic_vector(2 downto 0);
         o_extended_imm : out std_logic_vector(31 downto 0)
        );

end entity Extenders_wrapper;

architecture structural of Extenders_wrapper is

    component I_type_extender is
        port(
             i_imm  : in std_logic_vector(31 downto 20);
             o_extended_imm : out std_logic_vector(31 downto 0)
            );
    end component I_type_extender;

    component U_type_extender is
        port(
             i_imm  : in std_logic_vector(31 downto 12);
             o_extended_imm : out std_logic_vector(31 downto 0)
            );
    end component U_type_extender;

    component S_type_extender is
        port(
             i_imm_1  : in std_logic_vector(31 downto 25); --first portion 
             i_imm_2  : in std_logic_vector(11 downto 7);  -- second portion
             o_extended_imm : out std_logic_vector(31 downto 0)
            );
    end component S_type_extender;

    component SB_type_extender is
        port(
             i_imm_1  : in std_logic_vector(31 downto 25); --first portion 
             i_imm_2  : in std_logic_vector(11 downto 7);  -- second portion
             o_extended_imm : out std_logic_vector(31 downto 0)
            );
    end component SB_type_extender;

    component UJ_type_extender is
        port(
             i_imm  : in std_logic_vector(31 downto 12);
             o_extended_imm : out std_logic_vector(31 downto 0)
            );
    end component UJ_type_extender;

    signal s_I_type_extended_imm : std_logic_vector(31 downto 0);
    signal s_U_type_extended_imm : std_logic_vector(31 downto 0);
    signal s_S_type_extended_imm : std_logic_vector(31 downto 0);
    signal s_SB_type_extended_imm : std_logic_vector(31 downto 0);
    signal s_UJ_type_extended_imm : std_logic_vector(31 downto 0);

begin
    I_extender_inst: I_type_extender
            port map(
                i_imm          => i_instruction(31 downto 20),
                o_extended_imm => s_I_type_extended_imm
            );

    U_extender_inst: U_type_extender
            port map(
                i_imm          => i_instruction(31 downto 12),
                o_extended_imm => s_U_type_extended_imm
            );

    S_extender_inst: S_type_extender
            port map(
                i_imm_1        => i_instruction(31 downto 25),
                i_imm_2        => i_instruction(11 downto 7),
                o_extended_imm => s_S_type_extended_imm
            );

    SB_extender_inst: SB_type_extender
            port map(
                i_imm_1        => i_instruction(31 downto 25),
                i_imm_2        => i_instruction(11 downto 7),
                o_extended_imm => s_SB_type_extended_imm
            );
    UJ_extender_inst: UJ_type_extender
            port map(
                i_imm          => i_instruction(31 downto 12),
                o_extended_imm => s_UJ_type_extended_imm
            );


    with i_imm_select select
        o_extended_imm <= s_I_type_extended_imm when 3b"000",
                          s_U_type_extended_imm when 3b"011",
                          s_S_type_extended_imm when 3b"001",
                          s_SB_type_extended_imm when 3b"010",
                          s_UJ_type_extended_imm when 3b"100",
                          32x"00000000" when others;
            

    

end architecture structural;
