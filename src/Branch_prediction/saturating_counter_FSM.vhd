-- Date        : April 16, 2026
-- File        : saturating_counter.vhd     
-- Designer    : Salah Nasriddinov
-- Description: This file implements a saturating_counter 

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Saturating_counter_FSM is
    port(
             i_clock                : in  std_logic;
             i_reset                : in  std_logic;
             i_predicted_wrong_ex   : in  std_logic; 
             i_predicted_correct_ex : in  std_logic;
             i_FSM_update_en        : in  std_logic;
             o_notTaken_taken       : out std_logic);
end entity Saturating_counter_FSM;


architecture behavioral of Saturating_counter_FSM is

    type state_type is (STRONG_NOT_TAKE, WEAK_NOT_TAKE, WEAK_TAKE, STRONG_TAKE);
    signal s_current_state, s_next_state : state_type;


begin

    -- state registers synchronous
    process(i_clock, i_reset)
    begin
        if i_reset = '1' then
            s_current_state <= WEAK_NOT_TAKE;
        elsif rising_edge(i_clock) then
            s_current_state <= s_next_state;
        end if;
    end process;

    -- next state and output logic
    process(s_current_state, i_predicted_wrong_ex, i_predicted_correct_ex, i_FSM_update_en)
    begin
        -- set defaults to avoid latches
        s_next_state <= s_current_state; 
        o_notTaken_taken <= '0';

        case s_current_state is
            when STRONG_NOT_TAKE =>
                o_notTaken_taken <= '0';
                if i_predicted_wrong_ex = '1' and i_FSM_update_en = '1' then
                    s_next_state <= WEAK_NOT_TAKE;
                else 
                    s_next_state <= s_current_state;
                end if;

            when WEAK_NOT_TAKE =>
                o_notTaken_taken <= '0';
                if i_predicted_wrong_ex = '1' and i_FSM_update_en = '1' then
                    s_next_state <= WEAK_TAKE;
                elsif i_predicted_correct_ex = '1' and i_FSM_update_en = '1' then 
                    s_next_state <= STRONG_NOT_TAKE;
                else
                    s_next_state <= s_current_state;
                end if;

            when WEAK_TAKE =>
                o_notTaken_taken <= '1';
                if i_predicted_wrong_ex = '1' and i_FSM_update_en = '1' then
                    s_next_state <= WEAK_NOT_TAKE;
                elsif i_predicted_correct_ex = '1' and i_FSM_update_en = '1' then 
                    s_next_state <= STRONG_TAKE;
                else
                    s_next_state <= s_current_state;
                end if;

            when STRONG_TAKE =>
                o_notTaken_taken <= '1';
                if i_predicted_wrong_ex = '1' and i_FSM_update_en = '1' then
                    s_next_state <= WEAK_TAKE;
                else 
                    s_next_state <= s_current_state;
                end if;

            when others => -- handle invalid states
                o_notTaken_taken <= '0';
                s_next_state <= WEAK_NOT_TAKE;
        end case;
    end process;

end architecture;

