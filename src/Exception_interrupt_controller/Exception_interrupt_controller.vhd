-- Date        : May 3, 2026
-- File        : Exception_interrupt_controller.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements an exception and interrupt controller unit

library ieee;
use ieee.std_logic_1164.all;

entity Exception_interrupt_controller is
    port(
         i_ecall        : in std_logic; -- if this instruction is an ecall
         i_illegal_instruction : in std_logic;
         i_mip          : in std_logic_vector(31 downto 0); -- mip to see if any hardware interrupts pending
         i_mie          : in std_logic_vector(31 downto 0); -- mie to see if any hadware interrupts enabled
         i_mstatus      : in std_logic_vector(31 downto 0); -- mstatus to see if global interrupt bit is enabled
         o_trap_cause   : out std_logic_vector(31 downto 0); -- cause why this trap happened
         o_trap_occured : out std_logic -- signal to indicate that trap (interrupt/exception) happened. Used for flushing as well
        );
end entity;

architecture dataflow of Exception_interrupt_controller is

begin

    ---- MSB of trap cause tells if it is an exception or an interrupt
    -- o_trap_cause <=
    --                32x"0000000B" when (i_ecall = '1') else -- trap due to ecall
    --                32x"8000000B" when (i_mstatus(3) = '1' and i_mie(11) = '1' and i_mip(11) = '1') else -- trap due to hardware
    --                32x"00000000";


    --o_trap_occured <=
    --               '1' when ((i_ecall = '1') or (i_mstatus(3) = '1' and i_mie(11) = '1' and i_mip(11) = '1')) else
    --               '0';


    -- EMULATING RARS, so I so supervisor mode
    -- MSB of trap cause tells if it is an exception or an interrupt
     o_trap_cause <=
                    32x"00000002" when (i_illegal_instruction = '1' and i_mstatus(0) = '1') else -- trap due to illegal instruction
                    32x"0000000B" when (i_ecall = '1' and i_mstatus(0) = '1') else -- trap due to ecall
                    32x"8000000B" when (i_mstatus(0) = '1' and i_mie(11) = '1' and i_mip(11) = '1') else -- trap due to hardware
                    32x"00000000";


    o_trap_occured <=
                   '1' when ((i_ecall = '1' and i_mstatus(0) = '1') or (i_mstatus(0) = '1' and i_mie(11) = '1' and i_mip(11) = '1') or
                             (i_illegal_instruction = '1' and i_mstatus(0) = '1')) else
                   '0';



end architecture;
