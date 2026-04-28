-- Date        : April 27, 2026
-- File        : CSR_registers.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements the most important CSR_registers  

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;
use IEEE.math_real.all;
use work.RISCV_types.all;

entity CSR_registers is

	port(i_clock      : in std_logic;                        -- clock input
         i_reset      : in std_logic;                        -- reset input
         i_we         : in std_logic;                        -- CSR file WE
         i_read_addr  : in std_logic_vector(11 downto 0);    -- 12 bit address of CSR we want to read from
         i_write_addr : in std_logic_vector(11 downto 0);    -- 12 bit address of CSR we want to write to
         i_write_data : in std_logic_vector(31 downto 0);    -- 32 bit data we would like to write
         o_csr_data   : out std_logic_vector(31 downto 0)   -- 32 bit data we would like to read
		);
end entity CSR_registers;

architecture dataflow of CSR_registers is

    constant REG_mstatus  : std_logic_vector(11 downto 0) := 12x"300";
    constant REG_mtvec    : std_logic_vector(11 downto 0) := 12x"305";
    constant REG_mscratch : std_logic_vector(11 downto 0) := 12x"340";
    constant REG_mepc     : std_logic_vector(11 downto 0) := 12x"341";
    constant REG_mcause   : std_logic_vector(11 downto 0) := 12x"342";


	component N_bit_register is -- N_bit_register that takes a generic, in this case it is 32 fixed.
        generic(N : integer; Reset_value : std_logic_vector; Bypass_register : boolean);
        port(i_CLK  : in std_logic;						   -- Clock input
           i_RST    : in std_logic;						   -- Reset input
           i_WE     : in std_logic;   					   -- All register connected
           i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
           o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
	end component N_bit_register;   

    signal s_mstatus_we  : std_logic;
    signal s_mtvec_we    : std_logic;
    signal s_mscratch_we : std_logic;
    signal s_mepc_we     : std_logic;
    signal s_mcause_we   : std_logic;


    signal s_mstatus_out  : std_logic_vector(31 downto 0);
    signal s_mtvec_out    : std_logic_vector(31 downto 0);
    signal s_mscratch_out : std_logic_vector(31 downto 0);
    signal s_mepc_out     : std_logic_vector(31 downto 0);
    signal s_mcause_out   : std_logic_vector(31 downto 0);


begin

    -- only compare the last 8 bits, so it matches with RARS
    with i_write_addr(7 downto 0) select
        s_mstatus_we <= 
                       '1' when REG_mstatus(7 downto 0),
                       '0' when others;

    with i_write_addr(7 downto 0) select
        s_mtvec_we <= 
                       '1' when REG_mtvec(7 downto 0),
                       '0' when others;

    with i_write_addr(7 downto 0) select
        s_mscratch_we <= 
                       '1' when REG_mscratch(7 downto 0),
                       '0' when others;

    with i_write_addr(7 downto 0) select
        s_mepc_we <= 
                       '1' when REG_mepc(7 downto 0),
                       '0' when others;

    with i_write_addr(7 downto 0) select
        s_mcause_we <= 
                       '1' when REG_mcause(7 downto 0),
                       '0' when others;
    
----------------------------------------
    with i_read_addr(7 downto 0) select
        o_csr_data <= 
                       s_mstatus_out  when REG_mstatus(7 downto 0),
                       s_mtvec_out    when REG_mtvec(7 downto 0),
                       s_mscratch_out when REG_mscratch(7 downto 0),
                       s_mepc_out     when REG_mepc(7 downto 0),
                       s_mcause_out   when REG_mcause(7 downto 0),
                       32x"00000000"  when others;


	MSTATUS_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => true)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mstatus_we, 
                 i_D   => i_write_data and 32b"10000001111111111111111111101010", 
                 o_Q   => s_mstatus_out
        ); 

	MTVEC_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => true)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mtvec_we, 
                 i_D   => i_write_data, 
                 o_Q   => s_mtvec_out
        ); 

	MSCRATCH_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => true)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mscratch_we, 
                 i_D   => i_write_data, 
                 o_Q   => s_mscratch_out
        ); 

	MEPC_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => true)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mepc_we, 
                 i_D   => i_write_data, 
                 o_Q   => s_mepc_out
        ); 

	MCAUSE_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => true)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mcause_we, 
                 i_D   => i_write_data, 
                 o_Q   => s_mcause_out
        ); 

end architecture;
