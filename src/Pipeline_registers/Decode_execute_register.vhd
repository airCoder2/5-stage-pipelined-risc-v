-- Date        : April 3, 2026
-- File        : Decode_Execute_register.vhd   
-- Designer    : Salah Nasriddinov
-- Description : This file implements a decode/execute stage register 

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all; -- use the types

entity Decode_Execute_register is
    port(i_decode_execute_register : in  Decode_execute_data_t;
         o_decode_execute_register : out Decode_execute_data_t;
         i_stall                   : in std_logic;
         i_reset                   : in std_logic;
         i_clk                     : in std_logic); -- clock
end entity Decode_Execute_register;

architecture structural of Decode_Execute_register is

    component N_bit_register is
        generic(N : integer; Reset_value : std_logic_vector; Bypass_register : boolean);
        port(i_CLK  : in std_logic;						   -- Clock input
           i_RST    : in std_logic;						   -- Reset input
           i_WE     : in std_logic;   					   -- All register connected
           i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
           o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
    end component N_bit_register;   

    -- decode/execute stage register
    -- 180 bits total:
    signal s_Decode_execute_data_in  : std_logic_vector(179 downto 0);   
    signal s_Decode_execute_data_out : std_logic_vector(179 downto 0);   
begin

    -- Control : REG_WE                 (0)
    -- Control : branch                 (1)
    -- Control : jal_or_jalr            (2)
    -- Control : mem_WE                 (3)
    -- Control : ALU/Mem                (4)
    -- ALU_Control : nAdd_sub           (5)
    -- ALU_Control : logical/arith      (6)
    -- ALU_Control : right/left         (7)
    -- ALU_Control : ALU_mux_select     (10 downto 8)
    -- DATA        : branch_adder_A     (42 downto 11)
    -- DATA        : ALU_A              (74 downto 43)
    -- DATA        : ALU_B              (106 downto 75)
    -- Select      : reg_write_sel      (111 downto 107)
    -- DATA        : reg_data_2         (143 downto 112)
    -- DATA        : Extended_imm       (175 downto 144)
    -- DATA        : func3              (178 downto 176)
    -- Control : halt                   (179)

    s_Decode_execute_data_in(0)              <=  i_decode_execute_register.reg_WE;
    s_Decode_execute_data_in(1)              <=  i_decode_execute_register.branch;
    s_Decode_execute_data_in(2)              <=  i_decode_execute_register.jal_or_jalr;
    s_Decode_execute_data_in(3)              <=  i_decode_execute_register.mem_WE;
    s_Decode_execute_data_in(4)              <=  i_decode_execute_register.ALU_mem;
    s_Decode_execute_data_in(5)              <=  i_decode_execute_register.ALU_nAdd_sub;
    s_Decode_execute_data_in(6)              <=  i_decode_execute_register.ALU_logcl_arith;  
    s_Decode_execute_data_in(7)              <=  i_decode_execute_register.ALU_right_left;   
    s_Decode_execute_data_in(10 downto 8)    <=  i_decode_execute_register.ALU_mux_select;
    s_Decode_execute_data_in(42 downto 11)   <=  i_decode_execute_register.branch_adder_A;
    s_Decode_execute_data_in(74 downto 43)   <=  i_decode_execute_register.ALU_A;
    s_Decode_execute_data_in(106 downto 75)  <=  i_decode_execute_register.ALU_B;
    s_Decode_execute_data_in(111 downto 107) <=  i_decode_execute_register.reg_write_sel;
    s_Decode_execute_data_in(143 downto 112) <=  i_decode_execute_register.reg_data_2;
    s_Decode_execute_data_in(175 downto 144) <=  i_decode_execute_register.Extended_imm;
    s_Decode_execute_data_in(178 downto 176) <=  i_decode_execute_register.func3;
    s_Decode_execute_data_in(179)            <=  i_decode_execute_register.halt;

    Decode_execute_register_inst: N_bit_register
        generic map(N => 180, Reset_value => (179 downto 0 => '0'), Bypass_register => false)
        port map(
                 i_CLK => i_clk,
                 i_RST => i_reset,                  -- reset the pipeline to 0
                 i_WE  => not i_stall,              -- always write unless stalled
                 i_D   => s_Decode_execute_data_in, -- all the inputs  are contained in this signal
                 o_Q   => s_Decode_execute_data_out -- all the outputs are contained in this signal
             );

    -- fill the output wires with the appropriate slices of the N_bit_register output
    o_decode_execute_register.reg_WE         <= s_Decode_execute_data_out(0);             
    o_decode_execute_register.branch         <= s_Decode_execute_data_out(1);              
    o_decode_execute_register.jal_or_jalr    <= s_Decode_execute_data_out(2);                
    o_decode_execute_register.mem_WE         <= s_Decode_execute_data_out(3);                    
    o_decode_execute_register.ALU_mem        <= s_Decode_execute_data_out(4);             
    o_decode_execute_register.ALU_nAdd_sub   <= s_Decode_execute_data_out(5);                      
    o_decode_execute_register.ALU_logcl_arith <= s_Decode_execute_data_out(6);                         
    o_decode_execute_register.ALU_right_left <= s_Decode_execute_data_out(7);                          
    o_decode_execute_register.ALU_mux_select <= s_Decode_execute_data_out(10 downto 8);             
    o_decode_execute_register.branch_adder_A <= s_Decode_execute_data_out(42 downto 11);            
    o_decode_execute_register.ALU_A          <= s_Decode_execute_data_out(74 downto 43);            
    o_decode_execute_register.ALU_B          <= s_Decode_execute_data_out(106 downto 75);           
    o_decode_execute_register.reg_write_sel  <= s_Decode_execute_data_out(111 downto 107);          
    o_decode_execute_register.reg_data_2     <= s_Decode_execute_data_out(143 downto 112);            
    o_decode_execute_register.Extended_imm   <= s_Decode_execute_data_out(175 downto 144);           
    o_decode_execute_register.func3          <= s_Decode_execute_data_out(178 downto 176);                
    o_decode_execute_register.halt           <= s_Decode_execute_data_out(179);                       
   

end architecture structural;
