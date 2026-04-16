-- Date        : April 15, 2026
-- File        : branch_prediction.vhd     
-- Designer    : Salah Nasriddinov
-- Description: This file implements the branch prediction unit

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Branch_prediction is
    port(
             i_clock                : in  std_logic;
             i_reset                : in  std_logic;
             i_predicted_wrong_ex   : in  std_logic; 
             i_predicted_correct_ex : in  std_logic;
             i_jalr                 : in  std_logic; -- if jalr, output not taken
             o_notTaken_taken       : out std_logic);
end entity Branch_prediction;

architecture behavioral of Branch_prediction is

    type state_type is (STRONG_NOT_TAKE, WEAK_NOT_TAKE, WEAK_TAKE, STRONG_TAKE);
    signal s_current_state, s_next_state : state_type;

    signal s_notTaken_taken : std_logic;

begin
    with i_jalr select
        o_notTaken_taken <= '0' when '1',    -- when jalr, don't take
                            s_notTaken_taken when others; -- predict
                            --'1' when others; -- predict

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
    process(s_current_state, i_predicted_wrong_ex, i_predicted_correct_ex)
    begin
        -- set defaults to avoid latches
        s_next_state <= s_current_state; 
        s_notTaken_taken <= '0';

        case s_current_state is
            when STRONG_NOT_TAKE =>
                s_notTaken_taken <= '0';
                if i_predicted_wrong_ex = '1' then
                    s_next_state <= WEAK_NOT_TAKE;
                else 
                    s_next_state <= s_current_state;
                end if;

            when WEAK_NOT_TAKE =>
                s_notTaken_taken <= '0';
                if i_predicted_wrong_ex = '1' then
                    s_next_state <= WEAK_TAKE;
                elsif i_predicted_correct_ex = '1' then 
                    s_next_state <= STRONG_NOT_TAKE;
                else
                    s_next_state <= s_current_state;
                end if;

            when WEAK_TAKE =>
                s_notTaken_taken <= '1';
                if i_predicted_wrong_ex = '1' then
                    s_next_state <= WEAK_NOT_TAKE;
                elsif i_predicted_correct_ex = '1' then 
                    s_next_state <= STRONG_TAKE;
                else
                    s_next_state <= s_current_state;
                end if;

            when STRONG_TAKE =>
                s_notTaken_taken <= '1';
                if i_predicted_wrong_ex = '1' then
                    s_next_state <= WEAK_TAKE;
                else 
                    s_next_state <= s_current_state;
                end if;

            when others => -- handle invalid states
                s_notTaken_taken <= '0';
                s_next_state <= WEAK_NOT_TAKE;
        end case;
    end process;

end architecture;

