-- Date        : April 15, 2026
-- File        : branch_prediction.vhd     
-- Designer    : Salah Nasriddinov
-- Description: This file implements the branch prediction unit

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Branch_prediction is
    port(
             i_clock                      : in  std_logic;
             i_reset                      : in  std_logic;
             i_should_branch_ex           : in std_logic;
             i_predicted_wrong_ex         : in  std_logic; 
             i_predicted_correct_ex       : in  std_logic;
             i_predicted_counter_index_ex : in std_logic_vector(2 downto 0);
             i_jalr                       : in  std_logic; -- if jalr, output not taken
             o_predicted_counter_index    : out std_logic_vector(2 downto 0);
             o_notTaken_taken             : out std_logic);
end entity Branch_prediction;

architecture behavioral of Branch_prediction is

    component Saturating_counter_FSM is
        port(
             i_clock                : in  std_logic;
             i_reset                : in  std_logic;
             i_predicted_wrong_ex   : in  std_logic; 
             i_predicted_correct_ex : in  std_logic;
             i_FSM_update_en        : in  std_logic;
             o_notTaken_taken       : out std_logic);
    end component Saturating_counter_FSM;

    component Branch_history_shift_reg is
        port(
                 i_clock   : in  std_logic;
                 i_reset   : in  std_logic;
                 i_we      : in std_logic;
                 i_new_val : in std_logic;
                 o_reg_out : out std_logic_vector(2 downto 0));
    end component Branch_history_shift_reg;

    component Decoder_3_to_8 is
        port(i_code    : in std_logic_vector(2 downto 0); -- we have 3 bits for code
             o_decoded : out std_logic_vector(7 downto 0)); -- we have 8 bit output
    end component Decoder_3_to_8;


    signal s_FSM_table_output: std_logic_vector(7 downto 0);
    signal s_we_decode: std_logic_vector(7 downto 0);
    signal s_shift_reg_out : std_logic_vector(2 downto 0);
    signal s_notTaken_taken : std_logic;

begin

    o_predicted_counter_index <= s_shift_reg_out;

    o_notTaken_taken <= '0' when i_jalr = '1' else
                        -- '0';
                        -- s_notTaken_taken;
                         s_FSM_table_output(to_integer(unsigned(s_shift_reg_out)));

--    Saturating_counter_FSM_inst: Saturating_counter_FSM
--        port map(
--                 i_clock               => i_clock, 
--                 i_reset               => i_reset, 
--                 i_predicted_wrong_ex  => i_predicted_wrong_ex,  
--                 i_predicted_correct_ex=> i_predicted_correct_ex, 
--                 i_FSM_update_en       => '1',
--                 o_notTaken_taken      => s_notTaken_taken
--        );

    Decoder_3t8_FSM_update_index_en_inst: Decoder_3_to_8
        port map(i_code    => i_predicted_counter_index_ex,
                 o_decoded => s_we_decode
         );

    Saturating_counter_FSM_gen: for i in 0 to 7 generate
        Saturating_counter_FSM_inst_I: Saturating_counter_FSM
            port map(
                     i_clock               => i_clock, 
                     i_reset               => i_reset, 
                     i_predicted_wrong_ex  => i_predicted_wrong_ex,  
                     i_predicted_correct_ex=> i_predicted_correct_ex, 
                     i_FSM_update_en       => s_we_decode(i),
                     o_notTaken_taken      => s_FSM_table_output(i) 
            );
    end generate;

    Branch_history_shiftReg_inst: Branch_history_shift_reg
        port map(
                 i_clock   => i_clock, 
                 i_reset   => i_reset,
                 i_we      => i_predicted_wrong_ex or i_predicted_correct_ex, -- when one of them is 1, it means we have a branch
                 i_new_val => i_should_branch_ex, 
                 o_reg_out => s_shift_reg_out 
        );
end architecture;
