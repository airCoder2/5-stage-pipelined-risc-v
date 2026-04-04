-- Date        : April 3, 2026
-- File        : Fetch_decode_register.vhd   
-- Designer    : Salah Nasriddinov
-- Description : This file implements a fetch_decode stage register 

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all; -- use the types

entity Fetch_decode_register is
    port(i_fetch_decode_register : in Fetch_decode_data_t;
         o_fetch_decode_register : out Fetch_decode_data_t;
         i_stall                 : in std_logic;
         i_reset                 : in std_logic;
         i_clk                   : in std_logic); -- clock
end entity Fetch_decode_register;

architecture structural of Fetch_decode_register is

    component N_bit_register is
        generic(N : integer; Reset_value : std_logic_vector);
        port(i_CLK  : in std_logic;						   -- Clock input
           i_RST    : in std_logic;						   -- Reset input
           i_WE     : in std_logic;   					   -- All register connected
           i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
           o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
    end component N_bit_register;   

    -- fetch/decode signals
    -- 64 bits total:
    signal s_Fetch_decode_data_in  : std_logic_vector(63 downto 0); -- wire conencted to the input of the N_bit_register
    signal s_Fetch_decode_data_out : std_logic_vector(63 downto 0); -- wire conencted to the output of the N_bit_register

begin

    -- PC      : current PC (32 bits) (31 downto 0)
    -- Inst    : instruction (32 bits) (63 downto 32)
    s_Fetch_decode_data_in(31 downto 0)  <= i_fetch_decode_register.PC;
    s_Fetch_decode_data_in(63 downto 32) <= i_fetch_decode_register.Inst;




    Fetch_decode_register_inst: N_bit_register
        generic map(N => 64, Reset_value => (63 downto 0 => '0'))
        port map(
                 i_CLK => i_clk,
                 i_RST => i_reset,                 -- reset the pipeline to 0
                 i_WE  => not i_stall,             -- always write unless stalled
                 i_D   => s_Fetch_decode_data_in,  -- all the inputs  are contained in this signal
                 o_Q   => s_Fetch_decode_data_out  -- all the outputs are contained in this signal
             );

    -- fill the output wires with the appropriate slices of the N_bit_register output
    o_fetch_decode_register.PC   <= s_Fetch_decode_data_out(31 downto 0);
    o_fetch_decode_register.Inst <= s_Fetch_decode_data_out(63 downto 32);

end architecture structural;


