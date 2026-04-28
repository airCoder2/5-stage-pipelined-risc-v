-------------------------------------------------------------------------
-- Salah Nasriddinov 
-------------------------------------------------------------------------
-- tb_mux2t1_N_dataflow.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a testbench for an N-bit 2 to 1 mux 
--
-- NOTES:
-- 01/30/26 Design created and implemented.
-------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.textio.all;             -- For basic I/O
use IEEE.numeric_std.all; -- This provides the to_unsigned function

entity tb_mux2t1_N_dataflow is
  generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
end entity tb_mux2t1_N_dataflow;

architecture testbench of tb_mux2t1_N_dataflow is
	component mux2t1_N_dataflow
	  Port(i_S  : in std_logic;
		   i_D0 : in std_logic_vector(N-1 downto 0);
		   i_D1 : in std_logic_vector(N-1 downto 0);
		   o_O  : out std_logic_vector(N-1 downto 0));
	 end component;

	signal i0_tb, i1_tb: std_logic_vector(N-1 downto 0) := x"0000";
	signal f_tb : std_logic_vector(N-1 downto 0) := x"0000"; 
	signal s_tb: std_logic := '0';

begin
	DUT: mux2t1_N_dataflow port map(
		i_D0 => i0_tb,
		i_D1 => i1_tb,
		i_S  => s_tb,
		o_O  => f_tb
	);

	stimulus_proc: process
	begin
		-- Test case 1: f_tb -> 1
		i0_tb <= x"AAAA";
		i1_tb <= x"BBBB";
		s_tb  <= '0';
		wait for 10 ns;

		-- Test case 2: f_tb -> 0
		i0_tb <= x"CCCC";
		i1_tb <= x"DDDD";
		s_tb  <= '1';
		wait for 10 ns;

		-- Test case 3: f_tb -> 0
		i0_tb <= x"EEEE";
		i1_tb <= x"FFFF";
		s_tb  <= '0';
		wait for 10 ns;

		-- Test case 4: f_tb -> 1
		i0_tb <= x"9999";
		i1_tb <= x"8888";
		s_tb  <= '1';
		wait for 10 ns;

		wait;
	end process;
end architecture testbench;



