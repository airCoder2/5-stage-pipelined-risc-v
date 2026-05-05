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
	port(i_clock        : in std_logic;                       -- clock input
         i_reset        : in std_logic;                       -- reset input
         i_we           : in std_logic;                       -- CSR RegFile WE
         i_csr          : in std_logic;                       -- current instruction is csr flag
         i_read_addr    : in std_logic_vector(11 downto 0);   -- 12 bit address of CSR we want to read from
         i_write_addr   : in std_logic_vector(11 downto 0);   -- 12 bit address of CSR we want to write to
         i_write_data   : in std_logic_vector(31 downto 0);   -- 32 bit data we would like to write
         o_csr_data     : out std_logic_vector(31 downto 0);  -- 32 bit data we would like to read
         o_illegal_read : out std_logic;                      -- reading from unimplemented CSR 
         -- Ports neded for trap handling
         i_trap_occured : in std_logic;                      -- signal indicates that trap occured, start the procedure
         i_mret         : in std_logic;
         i_trap_cause   : in std_logic_vector(31 downto 0);  -- the reason why trap occured. MSB indicates Exception/!trap
         i_pc_wb        : in std_logic_vector(31 downto 0);  -- pc to put into mepc if exception
         i_pc_mem       : in std_logic_vector(31 downto 0);  -- pc to put into mepc if interrupt
         o_trap_ret_pc  : out std_logic_vector(31 downto 0); -- mtvec that is loaded as next pc when trap happened
         o_mstatus      : out std_logic_vector(31 downto 0); -- mstatus needed to be read by event controller
         o_mie          : out std_logic_vector(31 downto 0); -- mie needs to be read by event controller
         o_mip          : out std_logic_vector(31 downto 0)  -- mip needs to be read by event controller
		);
end entity CSR_registers;

architecture dataflow of CSR_registers is

    constant REG_mstatus_addr  : std_logic_vector(11 downto 0) := 12x"300";
    constant REG_mtvec_addr    : std_logic_vector(11 downto 0) := 12x"305";
    constant REG_mscratch_addr : std_logic_vector(11 downto 0) := 12x"340";
    constant REG_mepc_addr     : std_logic_vector(11 downto 0) := 12x"341";
    constant REG_mcause_addr   : std_logic_vector(11 downto 0) := 12x"342";
    constant REG_mie_addr      : std_logic_vector(11 downto 0) := 12x"304";
    constant REG_mip_addr      : std_logic_vector(11 downto 0) := 12x"344";
    
    component mux2t1_N_dataflow is
        generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
        port(i_S          : in std_logic;
           i_D0         : in std_logic_vector(N-1 downto 0);
           i_D1         : in std_logic_vector(N-1 downto 0);
           o_O          : out std_logic_vector(N-1 downto 0));
    end component mux2t1_N_dataflow;

    component one_bit_register is
        generic(Reset_value : std_logic; Bypass_register : boolean);
        port(i_CLK      : in std_logic;     -- Clock input
           i_RST        : in std_logic;     -- Reset input
           i_WE         : in std_logic;     -- Write enable input
           i_D          : in std_logic;     -- Data value input
           o_Q          : out std_logic);   -- Data value output
    end component one_bit_register;


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
    signal s_mie_we      : std_logic;

    signal s_mstatus_out       : std_logic_vector(31 downto 0);
    signal s_mstatus_copy_out  : std_logic_vector(31 downto 0);
    signal s_mtvec_out         : std_logic_vector(31 downto 0);
    signal s_mscratch_out      : std_logic_vector(31 downto 0);
    signal s_mepc_out          : std_logic_vector(31 downto 0);
    signal s_mcause_out        : std_logic_vector(31 downto 0);
    signal s_mie_out           : std_logic_vector(31 downto 0);
    signal s_mip_out           : std_logic_vector(31 downto 0);

    signal s_csr_reg_implemented : std_logic;

    signal s_mstatus_in  : std_logic_vector(31 downto 0);
    signal s_mcause_in   : std_logic_vector(31 downto 0);
    signal s_mepc_in     : std_logic_vector(31 downto 0);
    
    signal s_failing_pc  : std_logic_vector(31 downto 0);

    signal s_mstatus_mux_A_in : std_logic_vector(31 downto 0);
    signal s_prev_mie         : std_logic;


begin

    -- only compare the last 8 bits, so it matches with RARS
    s_mstatus_we  <= '1' when (i_write_addr(7 downto 0) = REG_mstatus_addr(7 downto 0)  and i_we = '1') else '0';
    s_mtvec_we    <= '1' when (i_write_addr(7 downto 0) = REG_mtvec_addr(7 downto 0)    and i_we = '1') else '0';
    s_mscratch_we <= '1' when (i_write_addr(7 downto 0) = REG_mscratch_addr(7 downto 0) and i_we = '1') else '0';
    s_mepc_we     <= '1' when (i_write_addr(7 downto 0) = REG_mepc_addr(7 downto 0)     and i_we = '1') else '0';
    s_mcause_we   <= '1' when (i_write_addr(7 downto 0) = REG_mcause_addr(7 downto 0)   and i_we = '1') else '0';
    s_mie_we      <= '1' when (i_write_addr(7 downto 0) = REG_mie_addr(7 downto 0)      and i_we = '1') else '0';
    
----------------------------------------
    -- Route the correct data to output
    with i_read_addr(7 downto 0) select
        o_csr_data <= 
                       s_mstatus_out  when REG_mstatus_addr(7 downto 0),
                       s_mtvec_out    when REG_mtvec_addr(7 downto 0),   
                       s_mscratch_out when REG_mscratch_addr(7 downto 0),
                       s_mepc_out     when REG_mepc_addr(7 downto 0),    
                       s_mcause_out   when REG_mcause_addr(7 downto 0),  
                       s_mie_out      when REG_mie_addr(7 downto 0),
                       s_mip_out      when REG_mip_addr(7 downto 0),
                       32x"00000000"  when others;


    -- raise an illegal flag when an unimplemented csr is accessed
    with i_read_addr(7 downto 0) select
        s_csr_reg_implemented <=
                       '1' when REG_mstatus_addr(7 downto 0),
                       '1' when REG_mtvec_addr(7 downto 0),   
                       '1' when REG_mscratch_addr(7 downto 0),
                       '1' when REG_mepc_addr(7 downto 0),    
                       '1' when REG_mcause_addr(7 downto 0),  
                       '1' when REG_mie_addr(7 downto 0),    
                       '1' when REG_mip_addr(7 downto 0),  
                       '0' when others;


    o_illegal_read <= i_csr and (not s_csr_reg_implemented);

	M_MIE_1BIT_REG_INST: one_bit_register
        generic map(Reset_value => '0', Bypass_register => false)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => i_trap_occured, 
                 -- THIS IF FOR RARS. CHANGE TO M mode after
                 i_D   => s_mstatus_out(0), 
                 o_Q   => s_prev_mie
        ); 


    Mux2t1_mstatus_recovery_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => i_mret,
                     -- i_D1 => s_mstatus_out(31 downto 8) & s_mstatus_out(3) & s_mstatus_out(6 downto 4) & '0' & s_mstatus_out(2 downto 0),
                     -- EMULATING RARS
                     i_D0 => s_mstatus_out(31 downto 5) & s_mstatus_out(0) & s_mstatus_out(3 downto 1) & '0',
                     i_D1 => s_mstatus_out(31 downto 5) & '0' & s_mstatus_out(3 downto 1) & s_prev_mie, 
                     o_O  => s_mstatus_mux_A_in
            ); 


    Mux2t1_mstatus_data_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => i_trap_occured or i_mret,
                     i_D0 => i_write_data,
                     i_D1 => s_mstatus_mux_A_in,
                     o_O  => s_mstatus_in
            ); 


    Mux2t1_mcause_data_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => i_trap_occured,
                     i_D0 => i_write_data,
                     i_D1 => i_trap_cause,
                     o_O  => s_mcause_in
            ); 


    Mux2t1_mepc_data_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => i_trap_occured,
                     i_D0 => i_write_data,
                     i_D1 => s_failing_pc,
                     o_O  => s_mepc_in
            ); 

    Mux2t1_failing_pc_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => i_trap_cause(31),
                     i_D0 => i_pc_wb,
                     i_D1 => i_pc_mem,
                     o_O  => s_failing_pc
            ); 



-- CAN'T USE BYPASS. Otherwise becoming an infite loop.
-- Added forwarding
------------------------------- CSR REGISTERS ------------------------


	MSTATUS_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => false)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mstatus_we or i_trap_occured or i_mret, 
                 i_D   => s_mstatus_in, 
                 o_Q   => s_mstatus_out
        ); 

	MEPC_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => false)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mepc_we or i_trap_occured, 
                 i_D   => s_mepc_in, 
                 o_Q   => s_mepc_out
        ); 

	MCAUSE_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => false)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mcause_we or i_trap_occured, 
                 i_D   => s_mcause_in, 
                 o_Q   => s_mcause_out
        ); 

	MTVEC_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => false)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mtvec_we, 
                 i_D   => i_write_data, 
                 o_Q   => s_mtvec_out
        ); 

	MSCRATCH_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => false)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mscratch_we, 
                 i_D   => i_write_data, 
                 o_Q   => s_mscratch_out
        ); 



	MIE_REG_INST: N_bit_register
        generic map(N => 32, Reset_value => 32x"00000000", Bypass_register => false)
        port map(
                 i_CLK => i_clock, 
                 i_RST => i_reset, 
                 i_WE  => s_mie_we, 
                 i_D   => i_write_data, 
                 o_Q   => s_mie_out
        ); 

        s_mip_out <= 32x"CAFE0000";

        with i_mret select
            o_trap_ret_pc <= s_mepc_out when '1',
                             s_mtvec_out when others;

         o_mstatus   <= s_mstatus_out; 
         o_mie       <= s_mie_out; 
         o_mip       <= s_mip_out; 


end architecture;
