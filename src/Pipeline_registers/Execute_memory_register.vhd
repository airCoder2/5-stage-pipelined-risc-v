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
        generic(N : integer; Reset_value : std_logic_vector);
        port(i_CLK  : in std_logic;						   -- Clock input
           i_RST    : in std_logic;						   -- Reset input
           i_WE     : in std_logic;   					   -- All register connected
           i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
           o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
    end component N_bit_register;   

    -- execute/memory stage register
    -- 116 bits total:
    signal s_Execute_memory_data_in  : std_logic_vector(115 downto 0);   
    signal s_Execute_memory_data_out : std_logic_vector(115 downto 0);   

begin

    -- Control : REG_WE                 (0)
    -- Control : branch                 (1)
    -- Control : jal                    (2)
    -- Control : jalr                   (3)
    -- Control : ALU/Mem                (4)
    -- Control : mem_WE                 (5)
    -- ALU_FLG : Alu_eq                 (6)
    -- ALU_FLG : Alu_lt                 (7)
    -- ALU_FLG : Alu_ltu                (8)
    -- ALU_FLG : Alu_get                (9)
    -- ALU_FLG : Alu_geu                (10)
    -- PC      : New branc PC (32 bits) (42 downto 11)
    -- DATA    : ALU_out (32 bits)      (74 downto 43)
    -- DATA    : read 2 (32 bits)       (106 downto 75)
    -- Inst    : func3 (3 bits)         (109 downto 107)
    -- ADDR:   : reg_write_sel(5 bits)  (114 downto 110)
    -- Control : halt                   (115)

    s_Execute_memory_data_in(0)              <= i_execute_memory_register.reg_WE;          
    s_Execute_memory_data_in(1)              <= i_execute_memory_register.branch;        
    s_Execute_memory_data_in(2)              <= i_execute_memory_register.jal;            
    s_Execute_memory_data_in(3)              <= i_execute_memory_register.jalr;           
    s_Execute_memory_data_in(4)              <= i_execute_memory_register.ALU_mem;        
    s_Execute_memory_data_in(5)              <= i_execute_memory_register.mem_WE;         
    s_Execute_memory_data_in(6)              <= i_execute_memory_register.Alu_eq; 
    s_Execute_memory_data_in(7)              <= i_execute_memory_register.Alu_lt;  
    s_Execute_memory_data_in(8)              <= i_execute_memory_register.Alu_ltu;
    s_Execute_memory_data_in(9)              <= i_execute_memory_register.Alu_ge; 
    s_Execute_memory_data_in(10)             <= i_execute_memory_register.Alu_geu; 
    s_Execute_memory_data_in(42 downto 11)   <= i_execute_memory_register.branch_PC;             
    s_Execute_memory_data_in(74 downto 43)   <= i_execute_memory_register.ALU_out;        
    s_Execute_memory_data_in(106 downto 75)  <= i_execute_memory_register.reg_data_2;
    s_Execute_memory_data_in(109 downto 107) <= i_execute_memory_register.func3;
    s_Execute_memory_data_in(114 downto 110) <= i_execute_memory_register.reg_write_sel;
    s_Execute_memory_data_in(115)            <= i_execute_memory_register.halt;


    Execute_memory_register_inst: N_bit_register
        generic map(N => 116, Reset_value => (115 downto 0 => '0'))
        port map(
                 i_CLK => i_clk,
                 i_RST => i_reset,                  -- reset the pipeline to 0
                 i_WE  => not i_stall,              -- always write unless stalled
                 i_D   => s_Execute_memory_data_in, -- all the inputs  are contained in this signal
                 o_Q   => s_Execute_memory_data_out -- all the outputs are contained in this signal
             );
    o_execute_memory_register.reg_WE        <= s_Execute_memory_data_out(0);             
    o_execute_memory_register.branch        <= s_Execute_memory_data_out(1);             
    o_execute_memory_register.jal           <= s_Execute_memory_data_out(2);             
    o_execute_memory_register.jalr          <= s_Execute_memory_data_out(3);             
    o_execute_memory_register.ALU_mem       <= s_Execute_memory_data_out(4);             
    o_execute_memory_register.mem_WE        <= s_Execute_memory_data_out(5);             
    o_execute_memory_register.Alu_eq        <= s_Execute_memory_data_out(6);             
    o_execute_memory_register.Alu_lt        <= s_Execute_memory_data_out(7);             
    o_execute_memory_register.Alu_ltu       <= s_Execute_memory_data_out(8);             
    o_execute_memory_register.Alu_ge        <= s_Execute_memory_data_out(9);             
    o_execute_memory_register.Alu_geu       <= s_Execute_memory_data_out(10);            
    o_execute_memory_register.branch_PC     <= s_Execute_memory_data_out(42 downto 11);  
    o_execute_memory_register.ALU_out       <= s_Execute_memory_data_out(74 downto 43);  
    o_execute_memory_register.reg_data_2    <= s_Execute_memory_data_out(106 downto 75); 
    o_execute_memory_register.func3         <= s_Execute_memory_data_out(109 downto 107); 
    o_execute_memory_register.reg_write_sel <= s_Execute_memory_data_out(114 downto 110);
    o_execute_memory_register.halt          <= s_Execute_memory_data_out(115);

end architecture structural;
