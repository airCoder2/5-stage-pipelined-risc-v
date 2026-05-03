-------------------------------------------------------------------------
-- Salah Nasriddinov
-------------------------------------------------------------------------
-- mux2t1_N_dataflow.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of an N-bit wide 2:1
-- mux using structural VHDL, generics, and generate statements.
--
--
-- NOTES:
-- 1/6/20 by H3::Created.
-- 1/30/2026  Salah Nasriddinov worked on it
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1_N_dataflow is
  generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_S          : in std_logic;
       i_D0         : in std_logic_vector(N-1 downto 0);
       i_D1         : in std_logic_vector(N-1 downto 0);
       o_O          : out std_logic_vector(N-1 downto 0));

end entity mux2t1_N_dataflow;

architecture structural of mux2t1_N_dataflow is

  component mux2t1_dataflow is
    port(I0_IN          : in std_logic;
         I1_IN          : in std_logic;
         S_IN           : in std_logic;
         F_OUT          : out std_logic);
  end component;

begin

  -- Instantiate N mux instances.
  G_NBit_MUX: for i in 0 to N-1 generate
    MUXI: mux2t1_dataflow port map(
              S_IN      => i_S,      -- All instances share the same select input.
              I0_IN     => i_D0(i),  -- ith instance's data 0 input hooked up to ith data 0 input.
              I1_IN     => i_D1(i),  -- ith instance's data 1 input hooked up to ith data 1 input.
              F_OUT     => o_O(i));  -- ith instance's data output hooked up to ith data output.
  end generate G_NBit_MUX;
  
end architecture structural;
