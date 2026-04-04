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
        generic(N : integer; Reset_value : std_logic_vector);
        port(i_CLK  : in std_logic;						   -- Clock input
           i_RST    : in std_logic;						   -- Reset input
           i_WE     : in std_logic;   					   -- All register connected
           i_D      : in std_logic_vector(N-1 downto 0);   -- Data value input
           o_Q      : out std_logic_vector(N-1 downto 0)); -- Data value output
    end component N_bit_register;   

    -- decode/execute stage register
    -- 149 bits total:
    signal s_Decode_execute_data_in  : std_logic_vector(148 downto 0);   
    signal s_Decode_execute_data_out : std_logic_vector(148 downto 0);   

begin

    -- Control : REG_WE                 (0)
    -- Control : branch                 (1)
    -- Control : jal                    (2)
    -- Control : jalr                   (3)
    -- Control : ALU/Mem                (4)
    -- Control : ALU_src                (5)
    -- Control : ALU_A_src              (6)
    -- Control : ALU_op (2 bits)        (8 downto 7)
    -- Control : lui                    (9)
    -- Control : mem_WE                 (10)
    -- PC      : current PC (32 bits)   (42 downto 11)
    -- DATA    : read 1 (32 bits)       (74 downto 43)
    -- DATA    : read 2 (32 bits)       (106 downto 75)
    -- DATA    : extended_imm (32 bits) (138 downto 107)
    -- Inst    : func3(3 bits)          (141 downto 139)
    -- Inst    : func7_5                (142)
    -- ADDR    : reg_write_sel          (147 downto 143)
    -- Control : halt                   (148)
    s_Decode_execute_data_in(0)              <=  i_decode_execute_register.reg_WE;
    s_Decode_execute_data_in(1)              <=  i_decode_execute_register.branch;
    s_Decode_execute_data_in(2)              <=  i_decode_execute_register.jal;
    s_Decode_execute_data_in(3)              <=  i_decode_execute_register.jalr;
    s_Decode_execute_data_in(4)              <=  i_decode_execute_register.ALU_mem;
    s_Decode_execute_data_in(5)              <=  i_decode_execute_register.ALU_src;
    s_Decode_execute_data_in(6)              <=  i_decode_execute_register.ALU_A_src;
    s_Decode_execute_data_in(8   downto 7)   <=  i_decode_execute_register.ALU_op;
    s_Decode_execute_data_in(9)              <=  i_decode_execute_register.lui;
    s_Decode_execute_data_in(10)             <=  i_decode_execute_register.mem_WE;
    s_Decode_execute_data_in(42  downto 11)  <=  i_decode_execute_register.PC;
    s_Decode_execute_data_in(74  downto 43)  <=  i_decode_execute_register.reg_data_1;
    s_Decode_execute_data_in(106 downto 75)  <=  i_decode_execute_register.reg_data_2;
    s_Decode_execute_data_in(138 downto 107) <=  i_decode_execute_register.Extended_imm;
    s_Decode_execute_data_in(141 downto 139) <=  i_decode_execute_register.func3;
    s_Decode_execute_data_in(142)            <=  i_decode_execute_register.func7_5;
    s_Decode_execute_data_in(147 downto 143) <=  i_decode_execute_register.reg_write_sel;
    s_Decode_execute_data_in(148)            <=  i_decode_execute_register.halt;



    Decode_execute_register_inst: N_bit_register
        generic map(N => 149, Reset_value => (148 downto 0 => '0'))
        port map(
                 i_CLK => i_clk,
                 i_RST => i_reset,                  -- reset the pipeline to 0
                 i_WE  => not i_stall,              -- always write unless stalled
                 i_D   => s_Decode_execute_data_in, -- all the inputs  are contained in this signal
                 o_Q   => s_Decode_execute_data_out -- all the outputs are contained in this signal
             );

    -- fill the output wires with the appropriate slices of the N_bit_register output
   o_decode_execute_register.reg_WE        <= s_Decode_execute_data_out(0);              
   o_decode_execute_register.branch        <= s_Decode_execute_data_out(1);            
   o_decode_execute_register.jal           <= s_Decode_execute_data_out(2);             
   o_decode_execute_register.jalr          <= s_Decode_execute_data_out(3);              
   o_decode_execute_register.ALU_mem       <= s_Decode_execute_data_out(4);              
   o_decode_execute_register.ALU_src       <= s_Decode_execute_data_out(5);              
   o_decode_execute_register.ALU_A_src     <= s_Decode_execute_data_out(6);              
   o_decode_execute_register.ALU_op        <= s_Decode_execute_data_out(8 downto 7);   
   o_decode_execute_register.lui           <= s_Decode_execute_data_out(9);              
   o_decode_execute_register.mem_WE        <= s_Decode_execute_data_out(10);            
   o_decode_execute_register.PC            <= s_Decode_execute_data_out(42 downto 11);  
   o_decode_execute_register.reg_data_1    <= s_Decode_execute_data_out(74 downto 43);  
   o_decode_execute_register.reg_data_2    <= s_Decode_execute_data_out(106 downto 75);  
   o_decode_execute_register.Extended_imm  <= s_Decode_execute_data_out(138 downto 107); 
   o_decode_execute_register.func3         <= s_Decode_execute_data_out(141 downto 139); 
   o_decode_execute_register.func7_5       <= s_Decode_execute_data_out(142);            
   o_decode_execute_register.reg_write_sel <= s_Decode_execute_data_out(147 downto 143);            
   o_decode_execute_register.halt          <= s_Decode_execute_data_out(148);            

end architecture structural;
