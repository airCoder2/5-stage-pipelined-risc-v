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
            o_halt : out std_logic --used as wfi
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
    signal s_ALU_A_ex                  : std_logic_vector(31 downto 0);         -- one of rs1 or PC EX stage
    signal s_ALU_B_ex                  : std_logic_vector(31 downto 0);         -- one of rs2 or imm EX stage
    signal s_branch_pc_addr_input_A_ex : std_logic_vector(31 downto 0);         -- one of PR or rs1
    signal s_ALU_select_ex             : std_logic_vector(2 downto 0);          -- ALU mux select EX stage
    signal s_logcl_arith_ex            : std_logic;                             -- this is logical or arithmetic flag EX stage
    signal s_right_left_ex             : std_logic;                             -- this is the right of left shift flag EX stage
    signal s_ALU_nAdd_sub_ex           : std_logic;                             -- ALU add or sub flag, driven by ALU control unit EX stage
    signal s_memory_data_mem           : std_logic_vector(31 downto 0);         -- Selected appropraite word/half_word/byte (MEM stage)
    signal s_should_branch_mem         : std_logic;                             -- the output of the branch decision box (MEM stage)
    signal s_reg_file_data_to_write_wb : std_logic_vector(31 downto 0);         -- data to write back in register file (WB stage)



    -- Pipeline Register input outputs--
    signal s_stall : std_logic; -- if 1, then should be stalled. For software pipelined allways 0
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
    s_Halt      <= s_MEM_WB_output.halt;
    s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.
    s_stall <= '0'; -- for software pipelined

    s_DMemWr   <= s_EX_MEM_output.mem_WE; -- active high data memory write enable signal
    s_DMemAddr <= s_EX_MEM_output.ALU_out; -- data memory address input
    s_DMemData <= s_EX_MEM_output.reg_data_2; -- data memory data input
    s_DMemOut  <= s_memory_data_mem; -- data memory output

    s_RegWr     <= s_MEM_WB_output.reg_WE; -- active high write enable input to the register file
    s_RegWrAddr <= s_MEM_WB_output.reg_write_sel; -- destination register address input
    s_RegWrData <= s_reg_file_data_to_write_wb; -- data memory data input

    s_PC        <= s_IF_ID_input.PC; -- instruction memory address input.
    s_Inst      <= s_IF_ID_input.Inst; -- instruction signal 
    oALUOut     <= s_EX_MEM_input.ALU_out;

    -- multiplex the instruction mem address. if instructon memeory is being written then connect
    -- the address that toolflow controls, otherwise coneect the s_PC, which is current pc
    with iInstLd select
    s_IMemAddr <= s_PC when '0',
      iInstAddr when others;

    -- IF_ID stage register
    IF_ID_reg_inst: Fetch_decode_register 
        port map(i_fetch_decode_register => s_IF_ID_input,
                 o_fetch_decode_register => s_IF_ID_output,
                 i_stall                 => s_stall,
                 i_reset                 => iRST,  
                 i_clk                   => iCLK   
        );

    -- ID_EX stage register
    ID_EX_reg_inst: Decode_Execute_register
        port map(i_decode_execute_register => s_ID_EX_input,
                  o_decode_execute_register => s_ID_EX_output,
                  i_stall                   => s_stall,
                  i_reset                   => iRST,  
                  i_clk                     => iCLK   
        );

    -- EX_MEM stage register
    EX_MEM_reg_inst: Execute_memory_register
        port map(i_execute_memory_register => s_EX_MEM_input,
                 o_execute_memory_register => s_EX_MEM_output,
                 i_stall                   => s_stall,
                 i_reset                   => iRST,  
                 i_clk                     => iCLK   
        );

    -- MEM_WB stage register
    MEM_WB_reg_inst: Memory_wback_register
        port map(i_memory_wback_register => s_MEM_WB_input,
                 o_memory_wback_register => s_MEM_WB_output,
                 i_stall                 => s_stall,
                 i_reset                 => iRST,  
                 i_clk                   => iCLK   
        );


    -- should next pc be pc + 4 or pc+(reg/immediate) selects PC source
    Mux2t1_pc_source_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_should_branch_mem or s_EX_MEM_output.jal or s_EX_MEM_output.jalr,
                     i_D0 => s_pc_plus_4_if,            -- current pc + 4
                     i_D1 => s_EX_MEM_output.branch_PC, -- calculated branch/jump PC
                     o_O  => s_Next_pc_if               -- selected next PC
             ); 

    -- 32 bit register for holding PC
    PC_inst: PC
        generic map(Reset_value => 32x"00400000")
        port map(
                i_pc_in  => s_Next_pc_if,     -- selected pc, either +4 or jump/branch address
                o_pc_out => s_IF_ID_input.PC, -- PC is saved in pipeline register
                i_reset  => iRST,
                i_clk    => iCLK
        );

    -- The adder to do PC+4
    PC_adder_inst: PC_adder
        port map(
                 i_current_pc => s_IF_ID_input.PC, -- add current pc + 4 
                 o_new_pc     => s_pc_plus_4_if    -- output of the addition
    ); 

    -- Instruction memory is filled out by toolflow
    IMem: mem 
        generic map(ADDR_WIDTH => 10,
                    DATA_WIDTH => 32)
        port map(clk  => iCLK,              -- Clock
                 addr => s_IF_ID_input.PC(11 downto 2),  -- PC is the address
                 data => iInstExt,          -- data is loaded by toolflow
                 we   => iInstLd,           -- controlled by toolflow
                 q    => s_IF_ID_input.Inst -- Instruction is saved in pipeline register
        );



    -- Main controller unit
    Main_control_inst: Main_control_unit 
        port map(
                 i_Opcode      => s_IF_ID_output.Inst(6 downto 0),
                 o_ALU_op      => s_ID_EX_input.ALU_op,
                 o_Imm_select  => s_Imm_select_id,
                 o_ALU_A_src   => s_ID_EX_input.ALU_A_src, 
                 o_ALU_src     => s_ID_EX_input.ALU_src,
                 o_mem_WE      => s_ID_EX_input.mem_WE,
                 o_ALU_mem     => s_ID_EX_input.ALU_mem,
                 o_reg_file_WE => s_ID_EX_input.reg_WE,
                 o_lui         => s_ID_EX_input.lui, 
                 o_branch      => s_ID_EX_input.branch, 
                 o_jal         => s_ID_EX_input.jal, 
                 o_jalr        => s_ID_EX_input.jalr,
                 o_halt        => s_ID_EX_input.halt
            );

    -- Register file
    Register_file_inst: Register_file
        port map(
                 CLOCK_IN          => iCLK,
                 DATA_TO_WRITE_IN  => s_reg_file_data_to_write_wb,
                 WRITE_EN_IN       => s_MEM_WB_output.reg_WE,
                 REG_RST_IN        => iRST,
                 WRITE_SEL_IN      => s_MEM_WB_output.reg_write_sel,
                 READ_SEL1_IN      => s_IF_ID_output.Inst(19 downto 15),
                 READ_SEL2_IN      => s_IF_ID_output.Inst(24 downto 20),
                 DATA_TO_READ1_OUT => s_ID_EX_input.reg_data_1,
                 DATA_TO_READ2_OUT => s_ID_EX_input.reg_data_2
             );

    -- Externders, 5 type of different extenders
    Extenders_inst: Extenders_wrapper
            port map(
                     i_instruction  => s_IF_ID_output.Inst(31 downto 7),
                     i_imm_select   => s_Imm_select_id,
                     o_extended_imm => s_ID_EX_input.Extended_imm
                 );

    s_ID_EX_input.PC            <= s_IF_ID_output.PC;
    s_ID_EX_input.reg_write_sel <= s_IF_ID_output.Inst(11 downto 7); -- rd
    s_ID_EX_input.func3         <= s_IF_ID_output.Inst(14 downto 12);
    s_ID_EX_input.func7_5       <= s_IF_ID_output.Inst(30);


    -- pass current pc or reg1 to be added with immediate(jalr adds imm + reg_out)
    Mux2t1_jalr_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ID_EX_output.jalr,
                     i_D0 => s_ID_EX_output.PC,
                     i_D1 => s_ID_EX_output.reg_data_1,
                     o_O  => s_branch_pc_addr_input_A_ex
            );

    -- for calculating final address
    Branch_adder_inst: ripple_carry_N_bit_adder
        generic map(N => 32)
        port map(x    => s_branch_pc_addr_input_A_ex,
                 y    => s_ID_EX_output.Extended_imm,
                 c_in => '0',
                 sum  => s_EX_MEM_input.branch_PC
        );




    -- select either rs1 or extended PC
    Mux2t1_ALU_A_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ID_EX_output.ALU_A_src,
                     i_D0 => s_ID_EX_output.reg_data_1,
                     i_D1 => s_ID_EX_output.PC,
                     o_O  => s_ALU_A_ex
            ); 

    -- select either rs2 or extended imm
    Mux2t1_ALU_B_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ID_EX_output.ALU_src,
                     i_D0 => s_ID_EX_output.reg_data_2,
                     i_D1 => s_ID_EX_output.Extended_imm,
                     o_O  => s_ALU_B_ex
            ); 


    -- ALU
    ALU_inst: ALU
        port map( 
                 i_A            => s_ALU_A_ex,
                 i_B            => s_ALU_B_ex,
                 i_ALU_select   => s_ALU_select_ex,
                 i_ALU_nAdd_sub => s_ALU_nAdd_sub_ex,
                 i_logcl_arith  => s_logcl_arith_ex,
                 i_right_left   => s_right_left_ex,
                 i_jal_or_jalr  => s_ID_EX_output.jal or s_ID_EX_output.jalr,
                 o_eq           => s_EX_MEM_input.Alu_eq, 
                 o_lt           => s_EX_MEM_input.Alu_lt, 
                 o_ltu          => s_EX_MEM_input.Alu_ltu,
                 o_ge           => s_EX_MEM_input.Alu_ge,
                 o_geu          => s_EX_MEM_input.Alu_geu,
                 o_ALU_out      => s_EX_MEM_input.ALU_out
             ); 



    -- ALU control unit
    ALU_control_unit_inst: ALU_control_unit 
        port map(
                 i_alu_op      => s_ID_EX_output.ALU_op,
                 i_func3       => s_ID_EX_output.func3,
                 i_func7_5     => s_ID_EX_output.func7_5,
                 i_lui         => s_ID_EX_output.lui,
                 o_alu_select  => s_ALU_select_ex,
                 o_nAdd_sub    => s_ALU_nAdd_sub_ex,
                 o_logcl_arith => s_logcl_arith_ex,
                 o_right_left  => s_right_left_ex
        );

    s_EX_MEM_input.reg_WE        <= s_ID_EX_output.reg_WE;
    s_EX_MEM_input.branch        <= s_ID_EX_output.branch;
    s_EX_MEM_input.jal           <= s_ID_EX_output.jal;
    s_EX_MEM_input.jalr          <= s_ID_EX_output.jalr;
    s_EX_MEM_input.mem_WE        <= s_ID_EX_output.mem_WE;
    s_EX_MEM_input.reg_data_2    <= s_ID_EX_output.reg_data_2;
    s_EX_MEM_input.ALU_mem       <= s_ID_EX_output.ALU_mem;
    s_EX_MEM_input.func3         <= s_ID_EX_output.func3;
    s_EX_MEM_input.reg_write_sel <= s_ID_EX_output.reg_write_sel;
    s_EX_MEM_input.halt          <= s_ID_EX_output.halt;


    -- Decision box for deciding if should branch or no
    branch_brain_inst: branch_decision 
        port map(
              i_eq         => s_EX_MEM_output.Alu_eq, 
              i_lt         => s_EX_MEM_output.Alu_lt, 
              i_ltu        => s_EX_MEM_output.Alu_ltu,
              i_ge         => s_EX_MEM_output.Alu_ge,
              i_geu        => s_EX_MEM_output.Alu_geu,
              i_is_branch  => s_EX_MEM_output.branch,
              i_func3      => s_EX_MEM_output.func3,
              o_should_branch => s_should_branch_mem
        );


    DMem: mem
        generic map(ADDR_WIDTH => 10,
                    DATA_WIDTH => 32)
        port map(clk  => iCLK,
                 addr => s_EX_MEM_output.ALU_out(11 downto 2),
                 data => s_EX_MEM_output.reg_data_2,
                 we   => s_EX_MEM_output.mem_WE,
                 q    => s_memory_data_mem
        );



    -- selects the appropriate slice or all of the word depending on lb, lh or lw
    Selector_inst: Byte_half_word_selector
        port map(
              i_mem_out_word  => s_memory_data_mem,
              i_mem_b_hw_addr => s_EX_MEM_output.ALU_out(1 downto 0),
              i_func3         => s_EX_MEM_output.func3,
              o_selected_data => s_MEM_WB_input.dmem_out
          );

    s_MEM_WB_input.ALU_out       <= s_EX_MEM_output.ALU_out;
    s_MEM_WB_input.ALU_mem       <= s_EX_MEM_output.ALU_mem;
    s_MEM_WB_input.reg_WE        <= s_EX_MEM_output.reg_WE;
    s_MEM_WB_input.reg_write_sel <= s_EX_MEM_output.reg_write_sel;
    s_MEM_WB_input.halt          <= s_EX_MEM_output.halt;


    -- Either write ALU_out or Mem_out to register file
    Mux2t1_ALU_or_Mem_data_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_MEM_WB_output.ALU_mem,
                     i_D0 => s_MEM_WB_output.ALU_out,
                     i_D1 => s_MEM_WB_output.dmem_out,
                     o_O  => s_reg_file_data_to_write_wb
            ); 

end structure;
