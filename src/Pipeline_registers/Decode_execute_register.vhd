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
    -- 162 bits total:
    signal s_Decode_execute_data_in  : std_logic_vector(164 downto 0);   
    signal s_Decode_execute_data_out : std_logic_vector(164 downto 0);   
    signal s_reg_WE : std_logic;
    signal s_mem_WE : std_logic;
    signal s_ALU_mem : std_logic;
    signal s_halt    : std_logic;
    signal s_branch : std_logic;
begin
    -- halt            :(0) 
    -- reg_WE          :(1)
    -- branch          :(2)
    -- jal             :(3)
    -- jalr            :(4)
    -- ALU_mem         :(5) 
    -- ALU_src         :(6) 
    -- ALU_A_src       :(7) 
    -- ALU_nAdd_sub    :(8) 
    -- ALU_logcl_arith :(9) 
    -- ALU_right_left  :(10) 
    -- mem_WE          :(11) 
    -- current_pc      :(43 downto 12)
    -- read1           :(75 downto 44)
    -- read2           :(107 downto 76)
    -- Extended_imm    :(139 downto 108)
    -- rd              :(144 downto 140) -- rd
    -- ALU_mux_select  :(147 downto 145)
    -- func3           :(150 downto 148)
    -- rs1             :(155 downto 151)
    -- rs2             :(160 downto 156)
    -- notTaken_taken  :(165)
    with i_stall select
        s_reg_WE <= i_decode_execute_register.reg_WE when '0', -- if not stall, then usual, otherwise 0
                    '0' when others; 
    with i_stall select
        s_mem_WE <= i_decode_execute_register.mem_WE when '0', -- if not stall, then usual, otherwise 0
                    '0' when others; 

    -- I forgot why I needed to set this, rethink about it
    with i_stall select
        s_ALU_mem <= i_decode_execute_register.ALU_mem when '0', -- if not stall, then usual, otherwise 0
                    '0' when others; 
    with i_stall select
        s_halt <= i_decode_execute_register.halt when '0', -- if not stall, then usual, otherwise 0
                    '0' when others; 

    with i_stall select
        s_branch <= i_decode_execute_register.branch when '0', -- if not stall, then usual, otherwise 0
                    '0' when others; 

    s_Decode_execute_data_in(0)              <=  s_halt;           
    s_Decode_execute_data_in(1)              <=  s_reg_WE;         
    s_Decode_execute_data_in(2)              <=  s_branch;
    s_Decode_execute_data_in(3)              <=  i_decode_execute_register.jal;            
    s_Decode_execute_data_in(4)              <=  i_decode_execute_register.jalr;           
    s_Decode_execute_data_in(5)              <=  s_ALU_mem;        
    s_Decode_execute_data_in(6)              <=  i_decode_execute_register.ALU_src;          
    s_Decode_execute_data_in(7)              <=  i_decode_execute_register.ALU_A_src;         
    s_Decode_execute_data_in(8)              <=  i_decode_execute_register.ALU_nAdd_sub;   
    s_Decode_execute_data_in(9)              <=  i_decode_execute_register.ALU_logcl_arith;
    s_Decode_execute_data_in(10)             <=  i_decode_execute_register.ALU_right_left; 
    s_Decode_execute_data_in(11)             <=  s_mem_WE;         
    s_Decode_execute_data_in(43 downto 12)   <=  i_decode_execute_register.current_pc;     
    s_Decode_execute_data_in(75 downto 44)   <=  i_decode_execute_register.read1;          
    s_Decode_execute_data_in(107 downto 76)  <=  i_decode_execute_register.read2;          
    s_Decode_execute_data_in(139 downto 108) <=  i_decode_execute_register.Extended_imm;   
    s_Decode_execute_data_in(144 downto 140) <=  i_decode_execute_register.rd;             
    s_Decode_execute_data_in(147 downto 145) <=  i_decode_execute_register.ALU_mux_select; 
    s_Decode_execute_data_in(150 downto 148) <=  i_decode_execute_register.func3;          
    s_Decode_execute_data_in(155 downto 151) <=  i_decode_execute_register.rs1;            
    s_Decode_execute_data_in(160 downto 156) <=  i_decode_execute_register.rs2;            
    s_Decode_execute_data_in(161)            <=  i_decode_execute_register.notTaken_taken;            
    s_Decode_execute_data_in(164 downto 162) <=  i_decode_execute_register.predicted_counter_index;

    Decode_execute_register_inst: N_bit_register
        generic map(N => 165, Reset_value => (164 downto 0 => '0'), Bypass_register => false)
        port map(
                 i_CLK => i_clk,
                 i_RST => i_reset,                  -- reset the pipeline to 0
                 i_WE  => '1',              -- always write unless stalled
                 i_D   => s_Decode_execute_data_in, -- all the inputs  are contained in this signal
                 o_Q   => s_Decode_execute_data_out -- all the outputs are contained in this signal
             );

    -- fill the output wires with the appropriate slices of the N_bit_register output
    o_decode_execute_register.halt            <= s_Decode_execute_data_out(0);             
    o_decode_execute_register.reg_WE          <= s_Decode_execute_data_out(1);              
    o_decode_execute_register.branch          <= s_Decode_execute_data_out(2);                
    o_decode_execute_register.jal             <= s_Decode_execute_data_out(3);                    
    o_decode_execute_register.jalr            <= s_Decode_execute_data_out(4);             
    o_decode_execute_register.ALU_mem         <= s_Decode_execute_data_out(5);                      
    o_decode_execute_register.ALU_src         <= s_Decode_execute_data_out(6);                         
    o_decode_execute_register.ALU_A_src       <= s_Decode_execute_data_out(7);                          
    o_decode_execute_register.ALU_nAdd_sub    <= s_Decode_execute_data_out(8);                       
    o_decode_execute_register.ALU_logcl_arith <= s_Decode_execute_data_out(9);                       
    o_decode_execute_register.ALU_right_left  <= s_Decode_execute_data_out(10);                      
    o_decode_execute_register.mem_WE          <= s_Decode_execute_data_out(11);                      
    o_decode_execute_register.current_pc      <= s_Decode_execute_data_out(43 downto 12);            
    o_decode_execute_register.read1           <= s_Decode_execute_data_out(75 downto 44);              
    o_decode_execute_register.read2           <= s_Decode_execute_data_out(107 downto 76);            
    o_decode_execute_register.Extended_imm    <= s_Decode_execute_data_out(139 downto 108);                
    o_decode_execute_register.rd              <= s_Decode_execute_data_out(144 downto 140);   
    o_decode_execute_register.ALU_mux_select  <= s_Decode_execute_data_out(147 downto 145);  
    o_decode_execute_register.func3           <= s_Decode_execute_data_out(150 downto 148);   
    o_decode_execute_register.rs1             <= s_Decode_execute_data_out(155 downto 151);   
    o_decode_execute_register.rs2             <= s_Decode_execute_data_out(160 downto 156);   
    o_decode_execute_register.notTaken_taken  <= s_Decode_execute_data_out(161);   
    o_decode_execute_register.predicted_counter_index  <= s_Decode_execute_data_out(164 downto 162);   


end architecture structural;
