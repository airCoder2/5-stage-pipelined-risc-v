-- Date        : April 3, 2026
-- File        : Execute_memory_register.vhd   
-- Designer    : Salah Nasriddinov
-- Description : This file implements a execute/memory stage register 

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all; -- use the types

entity Execute_memory_register is
    port(i_execute_memory_register : in Execute_memory_data_t;
         o_execute_memory_register : out Execute_memory_data_t;
         i_stall                   : in std_logic;
         i_reset                   : in std_logic;
         i_clk                     : in std_logic); -- clock
end entity Execute_memory_register;

architecture structural of Execute_memory_register is

    component N_bit_register is
        generic(N : integer; Reset_value : std_logic_vector; Bypass_register : boolean);
        port(i_CLK  : in std_logic;						   -- Clock input
           i_RST    : in std_logic;						   -- Reset input
           i_WE     : in std_logic;   					   -- All register connected
           i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
           o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
    end component N_bit_register;   

    -- execute/memory stage register
    -- 81 bits total:
    signal s_Execute_memory_data_in  : std_logic_vector(80 downto 0);   
    signal s_Execute_memory_data_out : std_logic_vector(80 downto 0);   

begin
    -- halt       :(0) 
    -- reg_WE     :(1) 
    -- ALU_mem    :(2) 
    -- mem_WE     :(3) 
    -- ALU_out    :(35 downto 4);
    -- reg_data_2 :(67 downto 36);
    -- rd         :(72 downto 68); -- rd
    -- func3      :(75 downto 73);
    -- rs2        :(80 downto 76);


    s_Execute_memory_data_in(0)              <= i_execute_memory_register.halt;              
    s_Execute_memory_data_in(1)              <= i_execute_memory_register.reg_WE;          
    s_Execute_memory_data_in(2)              <= i_execute_memory_register.ALU_mem;              
    s_Execute_memory_data_in(3)              <= i_execute_memory_register.mem_WE;           
    s_Execute_memory_data_in(35 downto 4)    <= i_execute_memory_register.ALU_out;          
    s_Execute_memory_data_in(67 downto 36)   <= i_execute_memory_register.reg_data_2;
    s_Execute_memory_data_in(72 downto 68)   <= i_execute_memory_register.rd;        
    s_Execute_memory_data_in(75 downto 73)   <= i_execute_memory_register.func3;     
    s_Execute_memory_data_in(80 downto 76)   <= i_execute_memory_register.rs2;     


    Execute_memory_register_inst: N_bit_register
        generic map(N => 81, Reset_value => (80 downto 0 => '0'), Bypass_register => false)
        port map(
                 i_CLK => i_clk,
                 i_RST => i_reset,                  -- reset the pipeline to 0
                 i_WE  => '1',              -- always write unless stalled
                 i_D   => s_Execute_memory_data_in, -- all the inputs  are contained in this signal
                 o_Q   => s_Execute_memory_data_out -- all the outputs are contained in this signal
             );
    o_execute_memory_register.halt         <= s_Execute_memory_data_out(0);                       
    o_execute_memory_register.reg_WE       <= s_Execute_memory_data_out(1);                       
    o_execute_memory_register.ALU_mem      <= s_Execute_memory_data_out(2);                       
    o_execute_memory_register.mem_WE       <= s_Execute_memory_data_out(3);                       
    o_execute_memory_register.ALU_out      <= s_Execute_memory_data_out(35 downto 4);             
    o_execute_memory_register.reg_data_2   <= s_Execute_memory_data_out(67 downto 36);            
    o_execute_memory_register.rd           <= s_Execute_memory_data_out(72 downto 68);            
    o_execute_memory_register.func3        <= s_Execute_memory_data_out(75 downto 73);            
    o_execute_memory_register.rs2          <= s_Execute_memory_data_out(80 downto 76);            

end architecture structural;
