-- Date		   : Feb 22, 2026
-- File		   : tb_dmem.vhd	 
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for reading and writing to RAM


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL; -- Required for type conversions

entity tb_dmem is
    generic
	( DATA_WIDTH : natural := 32;
	  ADDR_WIDTH : natural := 10;
      CLK_PERIOD : time    := 10 ns);

end tb_dmem;

architecture behaviour of tb_dmem is
component mem is
	generic (
        DATA_WIDTH : natural := 32;
	    ADDR_WIDTH : natural := 10);
	port (
        clk		: in std_logic;
        addr	: in std_logic_vector((ADDR_WIDTH-1) downto 0);
        data	: in std_logic_vector((DATA_WIDTH-1) downto 0);
        we		: in std_logic := '1';
        q		: out std_logic_vector((DATA_WIDTH -1) downto 0));

end component;

    signal clk_wire : std_logic;
    signal addr_wire: std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal data_wire: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal we_wire: std_logic;
    signal q_wire: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    type integer_array is array (0 to 9) of integer;


begin
    dmem: mem 
    generic map(
        DATA_WIDTH => 32, ADDR_WIDTH => 10)
    port map(
        clk => clk_wire,
        addr => addr_wire,
        data => data_wire,
        we => we_wire,
        q => q_wire);

    P_CLK: process
    begin
        clk_wire <= '1';
        wait for CLK_PERIOD/2; -- half of it is 1
        clk_wire <= '0';
        wait for CLK_PERIOD/2; -- half of it is 0
    end process;


    P_STIMULI: process
    variable int_mem_values : integer_array;
    begin
        wait for CLK_PERIOD/4; -- for waveform clarity;

        we_wire <= '0';
        for i in 0 to 9 loop
            addr_wire <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
            wait for 500 ps;
            int_mem_values(i) := to_integer(signed(q_wire));

            wait for CLK_PERIOD;
        end loop;

        we_wire <= '1';
        for j in 256 to 1023 loop
            addr_wire <= std_logic_vector(to_unsigned((j), ADDR_WIDTH));
            data_wire <= std_logic_vector(to_signed(int_mem_values((j-6) mod 10), DATA_WIDTH));

            wait for CLK_PERIOD;
        end loop;
        wait;

    end process;
end architecture behaviour;















































