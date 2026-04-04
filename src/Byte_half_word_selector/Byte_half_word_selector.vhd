-- Date        : March 20, 2026
-- File        : Byte_half_word_selectror.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a way to make lh, lhu, lb, lb work

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Byte_half_word_selector is
    port (
          i_mem_out_word  : in std_logic_vector(31 downto 0); -- the full word
          i_mem_b_hw_addr : in std_logic_vector(1 downto 0);  -- the two sliced lsbs of full address
          i_func3         : in std_logic_vector(2 downto 0);
          o_selected_data : out std_logic_vector(31 downto 0)
      );
end entity Byte_half_word_selector;


architecture structural of Byte_half_word_selector is

    component data_extender_8_to_32 is
        port(
             i_data  : in std_logic_vector(7 downto 0);
             i_zero_sign : in std_logic;
             o_extended_data : out std_logic_vector(31 downto 0)
            );
    end component data_extender_8_to_32;

    component data_extender_16_to_32 is
        port(
             i_data  : in std_logic_vector(15 downto 0);
             i_zero_sign : in std_logic;
             o_extended_data : out std_logic_vector(31 downto 0)
            );
    end component data_extender_16_to_32;

    component mux2t1_N_dataflow is
        generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
        port(i_S          : in std_logic;
           i_D0         : in std_logic_vector(N-1 downto 0);
           i_D1         : in std_logic_vector(N-1 downto 0);
           o_O          : out std_logic_vector(N-1 downto 0));
    end component mux2t1_N_dataflow;

    signal s_selected_byte : std_logic_vector(7 downto 0);
    signal s_selected_half : std_logic_vector(15 downto 0);

    signal s_extended_byte : std_logic_vector(31 downto 0);
    signal s_extended_half : std_logic_vector(31 downto 0);

    signal s_chosen_extended_byte_or_half : std_logic_vector(31 downto 0);

begin

    with i_mem_b_hw_addr select
        s_selected_byte <= i_mem_out_word(7 downto 0)   when 2b"00",
                           i_mem_out_word(15 downto 8)  when 2b"01",
                           i_mem_out_word(23 downto 16) when 2b"10",
                           i_mem_out_word(31 downto 24) when 2b"11",
                           8x"00" when others;

    mux1: mux2t1_N_dataflow 
        generic map(N => 16)
        port map(
                 i_S => i_mem_b_hw_addr(1),
                 i_D0 => i_mem_out_word(15 downto 0),
                 i_D1 => i_mem_out_word(31 downto 16),
                 o_O  => s_selected_half);

    extender_8t32: data_extender_8_to_32
        port map(
                 i_data => s_selected_byte,
                 i_zero_sign => not i_func3(2), -- because 0 is signed
                 o_extended_data => s_extended_byte
            );

    extender_16t32: data_extender_16_to_32
        port map(
                 i_data => s_selected_half,
                 i_zero_sign => not i_func3(2), -- because 0 is signed
                 o_extended_data => s_extended_half
            );

    mux2: mux2t1_N_dataflow 
        generic map(N => 32)
        port map(
                 i_S =>  i_func3(0),
                 i_D0 => s_extended_byte,
                 i_D1 => s_extended_half,
                 o_O  => s_chosen_extended_byte_or_half);

    mux3: mux2t1_N_dataflow 
        generic map(N => 32)
        port map(
                 i_S =>  i_func3(1),
                 i_D0 => s_chosen_extended_byte_or_half,
                 i_D1 => i_mem_out_word,
                 o_O  => o_selected_data);
end architecture structural;


















