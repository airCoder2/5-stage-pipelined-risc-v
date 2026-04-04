-- Date        : March 25, 2026
-- File        : PC.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a PC counter register 
-- Components  : N-bit register

library IEEE;
use IEEE.std_logic_1164.all;


entity PC is
    generic (Reset_value : std_logic_vector(31 downto 0));
    port(i_pc_in  : in  std_logic_vector(31 downto 0); -- new data to be written
         o_pc_out : out std_logic_vector(31 downto 0); -- pc output
         i_reset  : in  std_logic; -- reset to 0
         i_clk    : in  std_logic); -- clock
end entity PC;

architecture structural of PC is

    component N_bit_register is
        generic(N : integer; Reset_value : std_logic_vector);
        port(i_CLK  : in std_logic;						   -- Clock input
           i_RST    : in std_logic;						   -- Reset input
           i_WE     : in std_logic;   					   -- All register connected
           i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
           o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
    end component N_bit_register;   

begin
    Reg: N_bit_register
        generic map(N => 32, Reset_value => Reset_value)
        port map(
                 i_CLK => i_clk,
                 i_RST => i_reset, -- all the resets are connected to top level's reset
                 i_WE  => '1', -- always write
                 i_D   => i_pc_in,
                 o_Q   => o_pc_out);
end architecture structural;





