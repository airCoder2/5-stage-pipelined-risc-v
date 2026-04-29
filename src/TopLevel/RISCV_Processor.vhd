-- Date        : April 2, 2026
-- File        : RISCV_Processor.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a software pipelined risc-v processor. Doesn't handle any type of hazards.


library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.RISCV_types.all;

-- all the external connections are used by the ToolFlow
entity RISCV_Processor is
    generic(N : integer := 32);
    port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(31 downto 0);
       iInstExt        : in std_logic_vector(31 downto 0);
       oALUOut         : out std_logic_vector(31 downto 0)); -- Hook this up to the output of the ALU

end  RISCV_Processor;


architecture structure of RISCV_Processor is

----------------- COMPONENTS ---------------

    -- mem component is used to infer Memory to store Instructions and Data
    component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector(9 downto 0);
          data         : in std_logic_vector(31 downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector(31 downto 0));
    end component;

    -- PC componnet is used to 
    component PC is
        generic(Reset_value : std_logic_vector(31 downto 0));
        port(i_pc_in  : in  std_logic_vector(31 downto 0); -- new data to be written
             o_pc_out : out std_logic_vector(31 downto 0); -- pc output
             i_stall  : in  std_logic; -- don't advance the counter
             i_reset  : in  std_logic; -- reset to 0
             i_clk    : in  std_logic); -- clock
    end component PC;

    component PC_adder is
        port(i_current_pc : in  std_logic_vector(31 downto 0); -- current pc, 
             o_new_pc     : out std_logic_vector(31 downto 0)); -- output (current + 4)
    end component PC_adder;

    component ripple_carry_N_bit_adder is
        generic (N : integer);
        port( x  	   : in std_logic_vector(N-1 downto 0);
              y        : in std_logic_vector(N-1 downto 0);
              c_in     : in std_logic;
              sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
              c_out    : out std_logic;
              overflow : out std_logic);
    end component ripple_carry_N_bit_adder;

    component Hazard_unit is
        port(
             i_ALU_mem_ex           : in  std_logic;  -- lw
             i_mem_WE_id            : in  std_logic;  -- sw
             i_rd_ex                : in  std_logic_vector(4 downto 0);
             i_rs1_id               : in  std_logic_vector(4 downto 0);
             i_rs2_id               : in  std_logic_vector(4 downto 0);
             i_ALU_src_id           : in  std_logic;
             i_ALU_A_src_id         : in  std_logic;
             i_notTaken_taken       : in std_logic;
             i_predicted_wrong_ex   : in  std_logic; 
             i_predicted_correct_ex : in std_logic;
             i_jal_ex               : in std_logic;
             i_jalr_ex              : in std_logic;
             o_flush_IF_ID_id       : out std_logic; 
             o_flush_ID_EX_id       : out std_logic; 
             o_stall_id             : out std_logic
             );
    end component Hazard_unit; 

    component Register_file is
        port(CLOCK_IN : in std_logic;                                -- Clock input for registers
             DATA_TO_WRITE_IN : in std_logic_vector(31 downto 0); 	 -- Data to load
             WRITE_EN_IN  : in std_logic;                            -- to control the decoder
             REG_RST_IN   : in std_logic;                            -- to clear all the register
             WRITE_SEL_IN : in std_logic_vector(4 downto 0); 		 -- select register to load
             READ_SEL1_IN : in std_logic_vector(4 downto 0);         -- select register 1 to read
             READ_SEL2_IN : in std_logic_vector(4 downto 0);         -- select register 2 to read
             DATA_TO_READ1_OUT: out std_logic_vector(31 downto 0); 	 -- selected register 1 out
             DATA_TO_READ2_OUT: out std_logic_vector(31 downto 0)    -- selected register 2 out
            );
    end component Register_file;

    component ALU is
        port( i_A        	 : in std_logic_vector(31 downto 0);   -- 1st operand rs1/pc
              i_B            : in std_logic_vector(31 downto 0);   -- 2nd operand rs2/imm
              i_ALU_select   : in std_logic_vector(2 downto 0);    -- ALU mux select
              i_ALU_nAdd_sub : in std_logic;                       -- ALU add sub control
              i_logcl_arith  : in std_logic;                       -- is the shfit logical or arithmetic
              i_right_left   : in std_logic;                       -- is the shift to the right or left
              i_jal_or_jalr  : in std_logic;                       -- mux select that adds 0x4 to A
              o_eq           : out std_logic;
              o_lt           : out std_logic;
              o_ltu          : out std_logic;
              o_ge           : out std_logic;
              o_geu          : out std_logic;
              o_ALU_out      : out std_logic_vector(31 downto 0)); -- output
    end component ALU;

    component mux_3t1_bus is
        port(i_x0 : in std_logic_vector(31 downto 0); -- input 1 
             i_x1 : in std_logic_vector(31 downto 0); -- input 2
             i_x2 : in std_logic_vector(31 downto 0); -- input 3
             i_sel: in std_logic_vector(1 downto 0);  -- select line
             o_out : out std_logic_vector(31 downto 0)
         );
    end component mux_3t1_bus;

    component Forwarding_unit is
        port(i_rs1                : in std_logic_vector(4 downto 0); -- rs1 of the instruction at EX
             i_rs2                : in std_logic_vector(4 downto 0); -- rs2 of the instruction at EX
             i_MEM_rd             : in std_logic_vector(4 downto 0); -- rd of instruction at MEM
             i_WB_rd              : in std_logic_vector(4 downto 0); -- rd of instruction at WB
             i_MEM_rs2            : in std_logic_vector(4 downto 0); -- rs2 of the instruction at MEM
             i_WB_ALU_mem         : in std_logic; -- for detecting lw currently in wb, this is 1 only for lw
             i_MEM_reg_WE         : in std_logic; -- does the instruction at MEM write to reg file?
             i_WB_reg_WE          : in std_logic; -- does the instruction at WB  write to reg file?
             o_ALU_A_frwrd_sel    : out std_logic_vector(1 downto 0); -- select one of the paths to ALU_A
             o_ALU_B_frwrd_sel    : out std_logic_vector(1 downto 0);  -- select one of the paths to ALU_B
             o_MEM_frwrd_sel      : out std_logic -- select either the data from reg2, or forward from WB (for lw sw)
             ); 
    end component Forwarding_unit;

    component Extenders_wrapper is
        port(
             i_instruction  : in std_logic_vector(31 downto 7);
             i_imm_select   : in std_logic_vector(2 downto 0);
             o_extended_imm : out std_logic_vector(31 downto 0)
            );
    end component Extenders_wrapper;

    component Main_control_unit is
	port(
            i_Opcode  : in std_logic_vector(6 downto 0); -- the opcode we are decoding
            o_ALU_op  : out std_logic_vector(1 downto 0); -- two bit ALU opcode
            o_Imm_select : out std_logic_vector(2 downto 0); -- which immediate ALU should use  
            o_ALU_A_src : out std_logic; -- control for choosing between pc  or rs1 out
            o_ALU_src : out std_logic; -- control for choosing between imm or rs2 out
            o_mem_WE  : out std_logic; -- control to when data mem can be written
            o_ALU_mem : out std_logic;  -- control for writing to reg from ALU or memory
            o_reg_file_WE  : out std_logic;  -- control for when data to reg file is written 
            o_lui     : out std_logic; -- when 1, routes immediate and not the ALU out to reg
            o_branch  : out std_logic; -- should branch or no
            o_jal     : out std_logic;
            o_jalr    : out std_logic;
            o_sys     : out std_logic 
        );
    end component Main_control_unit;


    component ALU_control_unit is
        port(i_alu_op      : in  std_logic_vector(1 downto 0);
             i_func3       : in  std_logic_vector(2 downto 0);
             i_func7_5     : in  std_logic;
             i_lui         : in  std_logic; -- if lui, then just route i_B to out
             o_alu_select  : out std_logic_vector(2 downto 0); -- choose what output should chose
             o_nAdd_sub    : out std_logic; -- add subtraction flag for ALU
             o_logcl_arith : out std_logic;
             o_right_left  : out std_logic
         );
    end component ALU_control_unit;

    component mux2t1_N_dataflow is
        generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
        port(i_S          : in std_logic;
           i_D0         : in std_logic_vector(N-1 downto 0);
           i_D1         : in std_logic_vector(N-1 downto 0);
           o_O          : out std_logic_vector(N-1 downto 0));
    end component mux2t1_N_dataflow;

    component Byte_half_word_selector is
        port (
              i_mem_out_word  : in std_logic_vector(31 downto 0); -- the full word
              i_mem_b_hw_addr : in std_logic_vector(1 downto 0);  -- the two sliced lsbs of full address
              i_func3         : in std_logic_vector(2 downto 0);
              o_selected_data : out std_logic_vector(31 downto 0)
          );
    end component Byte_half_word_selector;

    component branch_decision is
        port (
              i_eq            : in std_logic;
              i_lt            : in std_logic;
              i_ltu           : in std_logic;
              i_ge            : in std_logic;
              i_geu           : in std_logic;
              i_is_branch     : in std_logic;
              i_func3         : in std_logic_vector(2 downto 0);
              o_should_branch : out std_logic);
    end component branch_decision;

    component Branch_prediction is
        port(
             i_clock                      : in  std_logic;
             i_reset                      : in  std_logic;
             i_should_branch_ex           : in std_logic;
             i_predicted_wrong_ex         : in  std_logic; 
             i_predicted_correct_ex       : in  std_logic;
             i_predicted_counter_index_ex : in std_logic_vector(2 downto 0);
             i_jalr                       : in  std_logic; -- if jalr, output not taken
             o_predicted_counter_index    : out std_logic_vector(2 downto 0);
             o_notTaken_taken             : out std_logic);
    end component Branch_prediction;

    -- CSR registers
    component CSR_registers is
        port(i_clock        : in std_logic;                       -- clock input
             i_reset        : in std_logic;                       -- reset input
             i_we           : in std_logic;                       -- CSR RegFile WE
             i_csr          : in std_logic;                       -- current instruction is csr flag
             i_read_addr    : in std_logic_vector(11 downto 0);   -- 12 bit address of CSR we want to read from
             i_write_addr   : in std_logic_vector(11 downto 0);   -- 12 bit address of CSR we want to write to
             i_write_data   : in std_logic_vector(31 downto 0);   -- 32 bit data we would like to write
             o_csr_data     : out std_logic_vector(31 downto 0);  -- 32 bit data we would like to read
             o_illegal_read : out std_logic                       -- reading from unimplemented CSR 
            );
    end component CSR_registers;
    
    -- Block in mem that decides what data to write to CSR
    component CSR_write_data_gen is
        port(
             i_func3_mem                 : in  std_logic_vector(2 downto 0);  -- Function 3 for determening what type of csr instruction it is
             i_csr_data_mem              : in  std_logic_vector(31 downto 0); -- CSR data to generate a masked output incase it is csrrs or csrrc
             i_extended_rs1_or_read1_mem : in  std_logic_vector(31 downto 0); -- Extended rs1 or reg1_data as new vaue incase csrrw or csrrwi
             o_csr_new_data_mem          : out std_logic_vector(31 downto 0)  -- New csr value to be written
            );
    end component CSR_write_data_gen;



    -- IF_ID stage register
    component Fetch_decode_register is
        port(i_fetch_decode_register : in  Fetch_decode_data_t;
             o_fetch_decode_register : out Fetch_decode_data_t;
             i_stall                 : in std_logic;
             i_reset                 : in std_logic;
             i_clk                   : in std_logic); -- clock
    end component Fetch_decode_register;

    -- ID_EX stage register
    component Decode_Execute_register is
        port(i_decode_execute_register : in  Decode_execute_data_t;
             o_decode_execute_register : out Decode_execute_data_t;
             i_stall                   : in std_logic;
             i_reset                   : in std_logic;
             i_clk                     : in std_logic); -- clock
    end component Decode_Execute_register;

        -- EX_MEM stage register
    component Execute_memory_register is
        port(i_execute_memory_register : in Execute_memory_data_t;
             o_execute_memory_register : out Execute_memory_data_t;
             i_stall                   : in std_logic;
             i_reset                   : in std_logic;
             i_clk                     : in std_logic); -- clock
    end component Execute_memory_register;

        -- MEM_WB stage register
    component Memory_wback_register is
        port(i_memory_wback_register : in Memory_wback_data_t;
             o_memory_wback_register : out Memory_wback_data_t;
             i_stall                 : in std_logic;
             i_reset                 : in std_logic;
             i_clk                   : in std_logic); -- clock
    end component Memory_wback_register;



    ----------------- REQUIRED SIGNALS ---------------

    -- Required data memory signals
    signal s_DMemWr       : std_logic;                     -- active high data memory write enable signal
    signal s_DMemAddr     : std_logic_vector(31 downto 0); -- data memory address input
    signal s_DMemData     : std_logic_vector(31 downto 0); -- data memory data input
    signal s_DMemOut      : std_logic_vector(31 downto 0); -- data memory output

    -- Required register file signals 
    signal s_RegWr        : std_logic;                     -- active high write enable input to the register file
    signal s_RegWrAddr    : std_logic_vector(4 downto 0);  -- destination register address input
    signal s_RegWrData    : std_logic_vector(31 downto 0); -- data memory data input

    -- Required instruction memory signals
    signal s_IMemAddr     : std_logic_vector(31 downto 0); -- Do not assign this signal, assign to s_PC instead
    signal s_PC : std_logic_vector(31 downto 0);           -- instruction memory address input.
    signal s_Inst         : std_logic_vector(31 downto 0); -- instruction signal 

    -- Required halt signal -- for simulation
    signal s_Halt         : std_logic;                     -- wfi. Opcode: 1110011 func3: 000 and func12: 000100000101 

    -- Required overflow signal -- for overflow exception detection
    signal s_Ovfl         : std_logic;                     -- overflow exception would have been initiated

    ----------------- MY OWN SIGNALS ---------------

    signal s_pc_plus_4_if              : std_logic_vector(31 downto 0);         -- the output of the pc+4 IF stage
    signal s_Next_pc_if                : std_logic_vector(31 downto 0);         -- either from pc+4 or branch IF stage
    signal s_Imm_select_id             : std_logic_vector(2 downto 0);          -- select wires for chosing which type of immediate to use ID stage 
    signal s_memory_data_mem           : std_logic_vector(31 downto 0);         -- Selected appropraite word/half_word/byte (MEM stage)
    signal s_reg_file_data_to_write_wb : std_logic_vector(31 downto 0);         -- data to write back in register file (WB stage)
    signal s_MEM_frwrd_sel_mem         : std_logic;                             -- select line for MEM's value. Forward from WB if previous one was lw
    signal s_ALU_A_frwrd_sel_ex        : std_logic_vector(1 downto 0);          -- select line for ALU_A's value before ALU_src mux. Either forward or ID/EX.A
    signal s_ALU_B_frwrd_sel_ex        : std_logic_vector(1 downto 0);          -- select line for ALU_B's value before ALU_src mux. Either forward or ID/EX.B
    signal s_ALU_A_final_data_ex       : std_logic_vector(31 downto 0);         -- ALU_A's final selected value. one of {read1/ (MEM.Alu_out) / (WB.data)}/(pc)  
    signal s_ALU_B_final_data_ex       : std_logic_vector(31 downto 0);         -- ALU_B's final selected value. one of {read2/ (MEM.Alu_out) / (WB.data)}/(imm) 
    signal s_mem_data_to_write_mem     : std_logic_vector(31 downto 0);         -- DMEM's final value. one of (MEM.reg2_data / WB.data)
    signal s_ALU_op_id       : std_logic_vector(1 downto 0);
    signal s_lui_id     : std_logic;
    signal s_sys_id     : std_logic; -- system instruciton. Look at func3 and func7
     
    signal s_should_branch_ex : std_logic;
    signal s_predicted_wrong_ex : std_logic;
    signal s_predicted_correct_ex : std_logic;
    signal s_frwrded_data_or_read1_ex : std_logic_vector(31 downto 0); 
    signal s_branch_adder_A_ex : std_logic_vector(31 downto 0); 
    signal s_branch_adder_B_ex : std_logic_vector(31 downto 0); 
    signal s_frwrded_data_or_read2_ex : std_logic_vector(31 downto 0);  
    signal s_branch_pc_ex : std_logic_vector(31 downto 0);

    signal s_ALU_flag_eq_ex   : std_logic;  
    signal s_ALU_flag_lt_ex   : std_logic;  
    signal s_ALU_flag_ltu_ex  : std_logic;
    signal s_ALU_flag_ge_ex   : std_logic;
    signal s_ALU_flag_geu_ex  : std_logic;

    signal s_flush_IF_ID_id : std_logic;
    signal s_flush_ID_EX_id : std_logic;
    signal s_stall_id : std_logic; 

    signal s_predicted_branch_pc_id : std_logic_vector(31 downto 0); -- predicted pc branch address
    signal s_pc_src_A_if : std_logic_vector(31 downto 0); -- predicted pc or pc+4
    signal s_predicted_correct_taken_ex : std_logic;

    signal s_illegal_instruction_id : std_logic; -- signal for illegal instructions


    -- Pipeline Register input outputs--
    -- fetch/decode reg inputs output
    signal s_IF_ID_input  : Fetch_decode_data_t;
    signal s_IF_ID_output : Fetch_decode_data_t;
    -- decode/execute reg input outputs
    signal s_ID_EX_input  : Decode_execute_data_t;
    signal s_ID_EX_output : Decode_execute_data_t;
    -- execute/memory reg input outputs
    signal s_EX_MEM_input  : Execute_memory_data_t;
    signal s_EX_MEM_output : Execute_memory_data_t;
    -- memory/writeback reg input outputs
    signal s_MEM_WB_input  : Memory_wback_data_t;
    signal s_MEM_WB_output : Memory_wback_data_t;


begin

--------------------- TOOLFLOW SIGNALS ------------------------
    s_Halt      <= s_MEM_WB_output.halt;
    s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.

    s_DMemWr   <= s_EX_MEM_output.mem_WE; -- active high data memory write enable signal
    s_DMemAddr <= s_MEM_WB_input.ALU_out_or_csr; -- data memory address input
    s_DMemData <= s_mem_data_to_write_mem; -- data memory data input
    s_DMemOut  <= s_memory_data_mem; -- data memory output

    s_RegWr     <= s_MEM_WB_output.reg_WE; -- active high write enable input to the register file
    s_RegWrAddr <= s_MEM_WB_output.rd; -- destination register address input
    s_RegWrData <= s_reg_file_data_to_write_wb; -- data memory data input

    s_PC        <= s_IF_ID_input.current_PC; -- instruction memory address input.
    s_Inst      <= s_IF_ID_input.Inst; -- instruction signal 
    oALUOut     <= s_EX_MEM_input.ALU_out;

    -- multiplex the instruction mem address. if instructon memeory is being written then connect
    -- the address that toolflow controls, otherwise coneect the s_PC, which is current pc
    with iInstLd select
    s_IMemAddr <= s_PC when '0',
      iInstAddr when others;

--------------------- PIPELINE REGISTERS ------------------------

    -- IF_ID stage register
    IF_ID_reg_inst: Fetch_decode_register 
        port map(i_fetch_decode_register => s_IF_ID_input,
                 o_fetch_decode_register => s_IF_ID_output,
                 i_stall                 => s_stall_id,
                 i_reset                 => iRST or s_flush_IF_ID_id,  
                 i_clk                   => iCLK   
        );

    -- ID_EX stage register
    ID_EX_reg_inst: Decode_Execute_register
        port map(i_decode_execute_register  => s_ID_EX_input,
                  o_decode_execute_register => s_ID_EX_output,
                  i_stall                   => s_stall_id,
                  i_reset                   => iRST or s_flush_ID_EX_id,  
                  i_clk                     => iCLK   
        );

    -- EX_MEM stage register
    EX_MEM_reg_inst: Execute_memory_register
        port map(i_execute_memory_register => s_EX_MEM_input,
                 o_execute_memory_register => s_EX_MEM_output,
                 i_stall                   => '0', --never stalled
                 i_reset                   => iRST,  
                 i_clk                     => iCLK   
        );

    -- MEM_WB stage register
    MEM_WB_reg_inst: Memory_wback_register
        port map(i_memory_wback_register => s_MEM_WB_input,
                 o_memory_wback_register => s_MEM_WB_output,
                 i_stall                 => '0', -- never stalled
                 i_reset                 => iRST,  
                 i_clk                   => iCLK   
        );

--------------------- FETCH STAGE ------------------------

    -- in case previous instruction was jal or branch, should we predict next address or pc+4
    Mux2t1_predict_or_next_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     -- 1 only when decode instruction is branch and set to taken by default OR jal. SHOULD NOT SLECT THE PREDICTED OF THE INSTRUCTION GETTING FLUSHED
                     i_S  => ((s_ID_EX_input.branch and s_ID_EX_input.notTaken_taken) or s_ID_EX_input.jal) and (not s_predicted_correct_taken_ex),
                     i_D0 => s_pc_plus_4_if,            -- current pc + 4
                     i_D1 => s_predicted_branch_pc_id,
                     o_O  => s_pc_src_A_if
             ); 

    -- should next pc be (predict next address/pc+4) or corrected pc selects PC source
    Mux2t1_pc_source_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     -- flushing IF_ID means that we have a two cycle penalty and we need to correct the pc (prediction was not correc or jalr)
                     i_S  => s_flush_IF_ID_id, 
                     i_D0 => s_pc_src_A_if,  -- prvious pc + jump or branch offset OR pc+4
                     i_D1 => s_branch_pc_ex, -- final calculated branch/jump value,
                     o_O  => s_Next_pc_if               -- selected next PC
             ); 

    -- 32 bit register for holding PC
    PC_inst: PC
        generic map(Reset_value => 32x"00400000")
        port map(
                i_pc_in  => s_Next_pc_if,     -- selected pc, either +4 or jump/branch address
                o_pc_out => s_IF_ID_input.current_PC, -- PC is saved in pipeline register
                i_stall  => s_stall_id, -- don't advance the counter
                i_reset  => iRST,
                i_clk    => iCLK
        );

    -- The adder to do PC+4
    PC_adder_inst: PC_adder
        port map(
                 i_current_pc => s_IF_ID_input.current_PC, -- add current pc + 4 
                 o_new_pc     => s_pc_plus_4_if    -- output of the addition
    ); 

    -- Instruction memory is filled out by toolflow
    IMem: mem 
        generic map(ADDR_WIDTH => 10,
                    DATA_WIDTH => 32)
        port map(clk  => iCLK,              -- Clock
                 addr => s_IF_ID_input.current_PC(11 downto 2),  -- PC is the address
                 data => iInstExt,          -- data is loaded by toolflow
                 we   => iInstLd,           -- controlled by toolflow
                 q    => s_IF_ID_input.Inst -- Instruction is saved in pipeline register
        );

--------------------- ID STAGE ------------------------

    -- Main controller unit
    Main_control_inst: Main_control_unit 
        port map(
                 i_Opcode      => s_IF_ID_output.Inst(6 downto 0),
                 o_ALU_op      => s_ALU_op_id,
                 o_Imm_select  => s_Imm_select_id,
                 o_ALU_A_src   => s_ID_EX_input.ALU_A_src, 
                 o_ALU_src     => s_ID_EX_input.ALU_src,
                 o_mem_WE      => s_ID_EX_input.mem_WE,
                 o_ALU_mem     => s_ID_EX_input.ALU_mem,
                 o_reg_file_WE => s_ID_EX_input.reg_WE,
                 o_lui         => s_lui_id, 
                 o_branch      => s_ID_EX_input.branch, 
                 o_jal         => s_ID_EX_input.jal, 
                 o_jalr        => s_ID_EX_input.jalr,
                 o_sys         => s_sys_id
            );

    Hazard_unit_inst: Hazard_unit
        port map(
                 i_ALU_mem_ex   => s_ID_EX_output.ALU_mem, -- lw
                 i_mem_WE_id    => s_ID_EX_input.mem_WE,
                 i_rd_ex        => s_ID_EX_output.rd,
                 i_rs1_id       => s_ID_EX_input.rs1,
                 i_rs2_id       => s_ID_EX_input.rs2,
                 i_ALU_src_id   => s_ID_EX_input.ALU_src,
                 i_ALU_A_src_id => s_ID_EX_input.ALU_A_src,
                 i_notTaken_taken       => s_ID_EX_output.notTaken_taken,
                 i_predicted_wrong_ex   => s_predicted_wrong_ex, -- if branch and (notTaken_taken != predicted)
                 i_predicted_correct_ex => s_predicted_correct_ex, -- if branch and (not predicted_wrong)
                 i_jal_ex               => s_ID_EX_output.jal,
                 i_jalr_ex              => s_ID_EX_output.jalr,
                 o_flush_IF_ID_id   => s_flush_IF_ID_id, 
                 o_flush_ID_EX_id   => s_flush_ID_EX_id, 
                 o_stall_id     => s_stall_id 
             ); 

    Branch_prediction_inst: Branch_prediction
        port map(
             i_clock                => iCLK,
             i_reset                => iRST,
             i_should_branch_ex     => s_should_branch_ex,
             i_predicted_wrong_ex   => s_predicted_wrong_ex,  
             i_predicted_correct_ex => s_predicted_correct_ex,
             i_predicted_counter_index_ex => s_ID_EX_output.predicted_counter_index, 
             i_jalr              => s_ID_EX_input.jalr, -- if jalr, output not taken
             o_predicted_counter_index   => s_ID_EX_input.predicted_counter_index,
             o_notTaken_taken    => s_ID_EX_input.notTaken_taken
         );

    Branch_predictor_addr_inst: ripple_carry_N_bit_adder
        generic map(N => 32)
        port map(x    => s_ID_EX_input.Extended_imm,
                 y    => s_IF_ID_output.current_PC,
                 c_in => '0',
                 sum  => s_predicted_branch_pc_id -- predicted calculated branch value
        );

    CSR_registers_inst: CSR_registers
        port map(
             i_clock        => iCLK, 
             i_reset        => iRST, 
             i_we           => s_MEM_WB_output.csr, 
             i_csr          => s_ID_EX_input.csr, 
             i_read_addr    => s_IF_ID_output.Inst(31 downto 20),
             i_write_addr   => s_MEM_WB_output.csr_write_addr,
             i_write_data   => s_MEM_WB_output.csr_new_data,
             o_csr_data     => s_ID_EX_input.csr_data,
             o_illegal_read => s_illegal_instruction_id
            );



    -- Register file
    Register_file_inst: Register_file
        port map(
                 CLOCK_IN          => iCLK,
                 DATA_TO_WRITE_IN  => s_reg_file_data_to_write_wb,
                 WRITE_EN_IN       => s_MEM_WB_output.reg_WE,
                 REG_RST_IN        => iRST,
                 WRITE_SEL_IN      => s_MEM_WB_output.rd,
                 READ_SEL1_IN      => s_ID_EX_input.rs1,
                 READ_SEL2_IN      => s_ID_EX_input.rs2,
                 DATA_TO_READ1_OUT => s_ID_EX_input.read1,
                 DATA_TO_READ2_OUT => s_ID_EX_input.read2
             );

    -- Externders, 5 type of different extenders
    Extenders_inst: Extenders_wrapper
            port map(
                     i_instruction  => s_IF_ID_output.Inst(31 downto 7),
                     i_imm_select   => s_Imm_select_id,
                     o_extended_imm => s_ID_EX_input.Extended_imm
                 );

    -- ALU control unit
    ALU_control_unit_inst: ALU_control_unit 
        port map(
                 i_alu_op      => s_ALU_op_id,
                 i_func3       => s_IF_ID_output.Inst(14 downto 12),
                 i_func7_5     => s_IF_ID_output.Inst(30),
                 i_lui         => s_lui_id,
                 o_alu_select  => s_ID_EX_input.ALU_mux_select,
                 o_nAdd_sub    => s_ID_EX_input.ALU_nAdd_sub,
                 o_logcl_arith => s_ID_EX_input.ALU_logcl_arith,
                 o_right_left  => s_ID_EX_input.ALU_right_left
        );

    s_ID_EX_input.rs1 <= s_IF_ID_output.Inst(19 downto 15);
    s_ID_EX_input.rs2 <= s_IF_ID_output.Inst(24 downto 20);
    s_ID_EX_input.rd    <= s_IF_ID_output.Inst(11 downto 7); -- rd
    s_ID_EX_input.func3 <= s_IF_ID_output.Inst(14 downto 12);
    s_ID_EX_input.current_pc <= s_IF_ID_output.current_PC;

    -- if system instruction = 1 AND func3 = 0 AND func7 (Imm) = 0x105 then it is a halt instruction
    s_ID_EX_input.halt <= '1' when (s_sys_id = '1' and s_ID_EX_input.func3 = 3b"000" and s_IF_ID_output.Inst(31 downto 20) = 12x"105") else '0';
    -- if system instruction AND (non zero func3) then it is a csr instruction
    s_ID_EX_input.csr  <= s_sys_id and (or s_ID_EX_input.func3);
    s_ID_EX_input.csr_write_addr <= s_IF_ID_output.Inst(31 downto 20); -- read address is the same as the write address


--------------------- EX STAGE ------------------------

    -- Decision box for deciding if should branch or no
    branch_brain_inst: branch_decision 
        port map(
              i_eq         => s_ALU_flag_eq_ex, 
              i_lt         => s_ALU_flag_lt_ex, 
              i_ltu        => s_ALU_flag_ltu_ex,
              i_ge         => s_ALU_flag_ge_ex,
              i_geu        => s_ALU_flag_geu_ex,
              i_is_branch  => s_ID_EX_output.branch,
              i_func3      => s_ID_EX_output.func3,
              o_should_branch => s_should_branch_ex 
        );

    -- if branch and (notTaken_taken != predicted)
    s_predicted_wrong_ex   <= s_ID_EX_output.branch and (s_ID_EX_output.notTaken_taken xor s_should_branch_ex);

    -- if branch and (not predicted_wrong)         
    -- s_predicted_correct_ex <= s_ID_EX_output.branch and (not (s_ID_EX_output.notTaken_taken xor s_should_branch_ex));
    -- old one which was generating delta cycle
    s_predicted_correct_ex <= s_ID_EX_output.branch and (not s_predicted_wrong_ex);





    
    -- flush only one of them ( USED TO MAKE SURE WE DON'T jump to the predicted address of the instructrion getting flusehd after correct taken prediction. Because
    -- we still have 1 cycle penalty)
    s_predicted_correct_taken_ex <= '1' when ((s_ID_EX_output.jal =  '1') or (s_predicted_correct_ex = '1' and s_ID_EX_output.notTaken_taken = '1')) else '0';


    -- Mux for ALU_A's input (Before ALU_A_src) mux. Controlled by the forwarding unit
    ALU_A_forward_select_mux_inst: mux_3t1_bus
        port map(
                 i_x0   => s_ID_EX_output.read1,    -- read1 
                 i_x1   => s_MEM_WB_input.ALU_out_or_csr,     -- (M.ALU_out)
                 i_x2   => s_reg_file_data_to_write_wb, -- (WB.data)
                 i_sel  => s_ALU_A_frwrd_sel_ex,        -- forwarding unit's control 
                 o_out  => s_frwrded_data_or_read1_ex   -- NEW
         );

    -- select either rs1 or PC
    Mux2t1_ALU_A_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ID_EX_output.ALU_A_src,
                     i_D0 => s_frwrded_data_or_read1_ex,
                     i_D1 => s_ID_EX_output.current_pc,
                     o_O  => s_ALU_A_final_data_ex  -- NEW

            ); 


    -- pass current pc or reg1 to be added with immediate(jalr adds imm + reg_out)
    Mux2t1_jalr_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ID_EX_output.jalr,
                     i_D0 => s_ID_EX_output.current_PC,
                     i_D1 => s_frwrded_data_or_read1_ex,
                     o_O  => s_branch_adder_A_ex  -- NEW
            );

    -- pass current  extended_imm or 0x00000004
    Mux2t1_notTaken_taken_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ID_EX_output.notTaken_taken or s_ID_EX_output.jal,
                     i_D0 => s_ID_EX_output.Extended_imm,
                     i_D1 => 32x"00000004",
                     o_O  => s_branch_adder_B_ex  -- NEW
            );

    -- for calculating final address
    Branch_adder_inst: ripple_carry_N_bit_adder
        generic map(N => 32)
        port map(x    => s_branch_adder_A_ex,
                 y    => s_branch_adder_B_ex,
                 c_in => '0',
                 sum  => s_branch_pc_ex -- final calculated branch value
        );

    Mux2t1_CSR_operand_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ID_EX_output.func3(2),
                     i_D0 => s_frwrded_data_or_read1_ex,
                     i_D1 => 27x"0" & s_ID_EX_output.rs1,
                     o_O  => s_EX_MEM_input.rs1_or_fread1
            ); 



    -- Mux for ALU_B's input. Controlled by the forwarding unit
    ALU_B_forward_select_mux_inst: mux_3t1_bus
        port map(
                 i_x0   => s_ID_EX_output.read2,    --        -- (read2 / imm)
                 i_x1   => s_MEM_WB_input.ALU_out_or_csr,        -- (M.ALU_out)
                 i_x2   => s_reg_file_data_to_write_wb, -- (WB.data)
                 i_sel  => s_ALU_B_frwrd_sel_ex,              -- forwarding unit's control
                 o_out  => s_frwrded_data_or_read2_ex   -- NEW 
         );


    -- select either rs2 or extended imm
    Mux2t1_ALU_B_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ID_EX_output.ALU_src,
                     i_D0 => s_frwrded_data_or_read2_ex,
                     i_D1 => s_ID_EX_output.Extended_imm,
                     o_O  => s_ALU_B_final_data_ex  -- NEW
            ); 



    -- ALU
    ALU_inst: ALU
        port map( 
                 i_A            => s_ALU_A_final_data_ex,
                 i_B            => s_ALU_B_final_data_ex,
                 i_ALU_select   => s_ID_EX_output.ALU_mux_select,
                 i_ALU_nAdd_sub => s_ID_EX_output.ALU_nAdd_sub,
                 i_logcl_arith  => s_ID_EX_output.ALU_logcl_arith,
                 i_right_left   => s_ID_EX_output.ALU_right_left,
                 i_jal_or_jalr  => s_ID_EX_output.jal or s_ID_EX_output.jalr,
                 o_eq           => s_ALU_flag_eq_ex,   
                 o_lt           => s_ALU_flag_lt_ex,   
                 o_ltu          => s_ALU_flag_ltu_ex,
                 o_ge           => s_ALU_flag_ge_ex,
                 o_geu          => s_ALU_flag_geu_ex,
                 o_ALU_out      => s_EX_MEM_input.ALU_out
             ); 

    Forwarding_unit_inst: Forwarding_unit
        port map(
                 i_rs1             => s_ID_EX_output.rs1,        
                 i_rs2             => s_ID_EX_output.rs2,
                 i_MEM_rd          => s_EX_MEM_output.rd,
                 i_WB_rd           => s_MEM_WB_output.rd,
                 i_MEM_rs2         => s_EX_MEM_output.rs2,
                 i_WB_ALU_mem      => s_MEM_WB_output.ALU_mem,
                 i_MEM_reg_WE      => s_EX_MEM_output.reg_WE, 
                 i_WB_reg_WE       => s_MEM_WB_output.reg_WE,
                 o_ALU_A_frwrd_sel => s_ALU_A_frwrd_sel_ex,
                 o_ALU_B_frwrd_sel => s_ALU_B_frwrd_sel_ex,
                 o_MEM_frwrd_sel   => s_MEM_frwrd_sel_mem
         ); 
  

    s_EX_MEM_input.reg_WE         <= s_ID_EX_output.reg_WE;
    s_EX_MEM_input.mem_WE         <= s_ID_EX_output.mem_WE;
    s_EX_MEM_input.ALU_mem        <= s_ID_EX_output.ALU_mem;
    s_EX_MEM_input.func3          <= s_ID_EX_output.func3;
    s_EX_MEM_input.rd             <= s_ID_EX_output.rd;
    s_EX_MEM_input.halt           <= s_ID_EX_output.halt;
    s_EX_MEM_input.rs2            <= s_ID_EX_output.rs2;
    s_EX_MEM_input.reg_data_2     <= s_frwrded_data_or_read2_ex;
    s_EX_MEM_input.csr            <= s_ID_EX_output.csr;
    s_EX_MEM_input.csr_data       <= s_ID_EX_output.csr_data;
    s_EX_MEM_input.csr_write_addr <= s_ID_EX_output.csr_write_addr;

--------------------- MEM STAGE ------------------------

    CSR_write_data_gen_inst: CSR_write_data_gen
        port map(
             i_func3_mem                 => s_EX_MEM_output.func3, 
             i_csr_data_mem              => s_EX_MEM_output.csr_data, 
             i_extended_rs1_or_read1_mem => s_EX_MEM_output.rs1_or_fread1, 
             o_csr_new_data_mem          => s_MEM_WB_input.csr_new_data
            );



    -- Either write reg_data2 to forward from writeback
    Mux2t1_Mem_frwrd_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_MEM_frwrd_sel_mem, 
                     i_D0 => s_EX_MEM_output.reg_data_2,
                     i_D1 => s_reg_file_data_to_write_wb,
                     o_O  => s_mem_data_to_write_mem 
            ); 

    Mux2t1_ALU_or_CSR:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_EX_MEM_output.csr, 
                     i_D0 => s_EX_MEM_output.ALU_out, 
                     i_D1 => s_EX_MEM_output.csr_data, 
                     o_O  => s_MEM_WB_input.ALU_out_or_csr
            ); 


    DMem: mem
        generic map(ADDR_WIDTH => 10,
                    DATA_WIDTH => 32)
        port map(clk  => iCLK,
                 addr => s_MEM_WB_input.ALU_out_or_csr(11 downto 2),
                 data => s_mem_data_to_write_mem,
                 we   => s_EX_MEM_output.mem_WE,
                 q    => s_memory_data_mem
        );



    -- selects the appropriate slice or all of the word depending on lb, lh or lw
    Selector_inst: Byte_half_word_selector
        port map(
              i_mem_out_word  => s_memory_data_mem,
              i_mem_b_hw_addr => s_MEM_WB_input.ALU_out_or_csr(1 downto 0),
              i_func3         => s_EX_MEM_output.func3,
              o_selected_data => s_MEM_WB_input.dmem_out
          );

    s_MEM_WB_input.ALU_mem <= s_EX_MEM_output.ALU_mem;
    s_MEM_WB_input.reg_WE  <= s_EX_MEM_output.reg_WE;
    s_MEM_WB_input.rd      <= s_EX_MEM_output.rd;
    s_MEM_WB_input.halt    <= s_EX_MEM_output.halt;
    s_MEM_WB_input.csr     <= s_EX_MEM_output.csr;
    s_MEM_WB_input.csr_write_addr <= s_EX_MEM_output.csr_write_addr;


--------------------- WB STAGE ------------------------

    -- Either write ALU_out or Mem_out to register file
    Mux2t1_ALU_or_Mem_data_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_MEM_WB_output.ALU_mem,
                     i_D0 => s_MEM_WB_output.ALU_out_or_csr,
                     i_D1 => s_MEM_WB_output.dmem_out,
                     o_O  => s_reg_file_data_to_write_wb
            ); 
end structure;
