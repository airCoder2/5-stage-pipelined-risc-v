-- Date        : March 5, 2026
-- File        : tb_PC.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for a PC register

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_PC is
end entity tb_PC;

architecture structural of tb_PC is
    component PC is
        port(i_pc_in  : in  std_logic_vector(31 downto 0);
             o_pc_out : out std_logic_vector(31 downto 0);
             i_reset  : in  std_logic;
             i_clk    : in  std_logic);
    end component PC;

    signal s_iPc_in  : std_logic_vector(31 downto 0);
    signal s_oPc_out : std_logic_vector(31 downto 0);
    signal s_iReset  : std_logic;
    signal s_iClk    : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    DUT: PC
        port map(
                 i_pc_in => s_iPc_in,
                 o_pc_out => s_oPc_out,
                 i_reset => s_iReset,
                 i_clk => s_iClk);

  -- This process sets the clock value (low for gCLK_HPER, then high
  -- for gCLK_HPER). Absent a "wait" command, processes restart 
  -- at the beginning once they have reached the final statement.
	P_CLK: process
	begin
		s_iClk <= '1';
		wait for CLK_PERIOD/2; -- half of it is 1
		s_iClk <= '0';
		wait for CLK_PERIOD/2; -- half of it is 0
	end process;

	RESET_R_FILE: process
	begin
		s_iReset <= '0';
		wait for CLK_PERIOD/4;
		s_iReset <= '1';
		wait for CLK_PERIOD;
		s_iReset <= '0';
		wait;
	end process;

	P_STIMULI: process
	begin
		wait for CLK_PERIOD;   -- for waveform clarity;
		wait for CLK_PERIOD/4; -- for waveform clarity;

        -- test cases
        s_iPc_in <= x"00000004"; 
		wait for CLK_PERIOD;   

        s_iPc_in <= x"3A9F1C42";
        wait for CLK_PERIOD;

        s_iPc_in <= x"00FF12A7";
        wait for CLK_PERIOD;

        s_iPc_in <= x"7C4D9E10";
        wait for CLK_PERIOD;

        s_iPc_in <= x"1456ABCD";
        wait for CLK_PERIOD;

        s_iPc_in <= x"9A21F004";
        wait for CLK_PERIOD;

        s_iPc_in <= x"0C88D3E1";
        wait for CLK_PERIOD;

        s_iPc_in <= x"F10234AA";
        wait for CLK_PERIOD;

        s_iPc_in <= x"22334455";
        wait for CLK_PERIOD;

        s_iPc_in <= x"DEADBEEF";
        wait for CLK_PERIOD;

        s_iPc_in <= x"CAFEBABE";
        wait for CLK_PERIOD;

        s_iPc_in <= x"81AC09F2";
        wait for CLK_PERIOD;

        s_iPc_in <= x"55AA7733";
        wait for CLK_PERIOD;

        s_iPc_in <= x"0F0F0F0F";
        wait for CLK_PERIOD;

        s_iPc_in <= x"F0F0F0F0";
        wait for CLK_PERIOD;

        s_iPc_in <= x"6B7C8D9E";
        wait for CLK_PERIOD;

        s_iPc_in <= x"13579BDF";
        wait for CLK_PERIOD;

        s_iPc_in <= x"2468ACE0";
        wait for CLK_PERIOD;

        s_iPc_in <= x"AB12CD34";
        wait for CLK_PERIOD;

        s_iPc_in <= x"89ABCDEF";
        wait for CLK_PERIOD;

        s_iPc_in <= x"10203040";
        wait for CLK_PERIOD;

		wait;
	end process;
end architecture structural;

