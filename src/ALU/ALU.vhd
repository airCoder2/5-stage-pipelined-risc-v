-- Date        : March 7, 2026
-- File        : ALU.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file is the top level ALU 
-- Components  : Adder_subtractor, AND, OR, XOR

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity ALU is
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
end entity ALU;

architecture structural of ALU is

    function or_bus(vec : std_logic_vector) return std_logic is
        variable result : std_logic := '0';
        begin
            for i in vec'range loop
                result := result or vec(i);
            end loop;
        return result;
    end function;

    component carry_lookahead_adder is
	generic (N : integer := 32);
        port( A  	   : in std_logic_vector(N-1 downto 0);
              B        : in std_logic_vector(N-1 downto 0);
              nAdd_Sub : in std_logic;
              sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
              c_out    : out std_logic;
              overflow : out std_logic);
    end component carry_lookahead_adder;

    component mux2t1_N_dataflow is
        generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
        port(i_S          : in std_logic;
           i_D0         : in std_logic_vector(N-1 downto 0);
           i_D1         : in std_logic_vector(N-1 downto 0);
           o_O          : out std_logic_vector(N-1 downto 0));
    end component mux2t1_N_dataflow;

    component AND_unit is
        port (
              i_A   : in std_logic_vector(31 downto 0);
              i_B   : in std_logic_vector(31 downto 0);
              o_out : out std_logic_vector(31 downto 0));
    end component AND_unit;

    component OR_unit is
        port (
              i_A   : in std_logic_vector(31 downto 0);
              i_B   : in std_logic_vector(31 downto 0);
              o_out : out std_logic_vector(31 downto 0));
    end component OR_unit;

    component XOR_unit is
        port (
              i_A   : in std_logic_vector(31 downto 0);
              i_B   : in std_logic_vector(31 downto 0);
              o_out : out std_logic_vector(31 downto 0));
    end component XOR_unit;

    component Shifter is
        port(
             i_data : in std_logic_vector(31 downto 0);
             i_shift_amount : in std_logic_vector(4 downto 0);
             i_logcl_arith  : in std_logic;                       -- is the shfit logical or arithmetic
             i_right_left   : in std_logic;                       -- is the shift to the right or left
             o_shifted_data : out std_logic_vector(31 downto 0)
            );
    end component Shifter;



    signal s_Adder_out : std_logic_vector(31 downto 0);
    signal s_ALU_AND_out : std_logic_vector(31 downto 0);
    signal s_ALU_OR_out  : std_logic_vector(31 downto 0);
    signal s_ALU_XOR_out : std_logic_vector(31 downto 0);
    signal s_ALU_Shifter_out : std_logic_vector(31 downto 0);
    signal s_ALU_component_out : std_logic_vector(31 downto 0);

    signal s_Adder_overflow : std_logic;

    signal s_signed_is_A_lt_B : std_logic;
    signal s_unsigned_is_A_lt_B : std_logic;
    signal s_eq : std_logic;

    signal s_muxed_B_out : std_logic_vector(31 downto 0);

begin

    -- adder subtract unit
    Adder_subtractor_inst: carry_lookahead_adder
        generic map(N => 32)
        port map(A 	      => i_A, 
                 B        => s_muxed_B_out,  -- either B or 0x4 for jal, jalr 
                 nAdd_Sub => i_ALU_nAdd_sub, -- driven by ALU_control unit
                 sum      => s_Adder_out,
                 overflow => s_Adder_overflow);

    Shifter_inst: Shifter
        port map(i_data  => i_A,
                 i_shift_amount => i_B(4 downto 0),
                 i_logcl_arith  => i_logcl_arith,                       -- is the shfit logical or arithmetic
                 i_right_left  => i_right_left,
                 o_shifted_data => s_ALU_Shifter_out
            );


    -- select either rs1 or extended PC
    Mux2t1_B_or_PC:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => i_jal_or_jalr,
                     i_D0 => i_B,
                     i_D1 => 32x"00000004",
                     o_O  => s_muxed_B_out); 

    AND_unit_inst: AND_unit
        port map(
                 i_A => i_A,
                 i_B => i_B,
                 o_out => s_ALU_AND_out);

    OR_unit_inst: OR_unit
        port map(
                 i_A => i_A,
                 i_B => i_B,
                 o_out => s_ALU_OR_out);

    XOR_unit_inst: XOR_unit
        port map(
                 i_A => i_A,
                 i_B => i_B,
                 o_out => s_ALU_XOR_out);


    -- both have explanation on the diagram on why this works. I even have a truth table and a K-map
    s_signed_is_A_lt_B <= s_Adder_overflow xor s_Adder_out(31); -- diagram has the explanation
    s_unsigned_is_A_lt_b <= s_signed_is_A_lt_B xor i_A(31) xor i_B(31); -- could also use c_out, but
                                                                        -- it didn't make sense, so did my own way 
    s_eq <= not or_bus(s_Adder_out);

    o_lt  <= s_signed_is_A_lt_B;
    o_ltu <= s_unsigned_is_A_lt_B;
    o_eq  <= s_eq;
    o_geu <= (not s_unsigned_is_A_lt_B) or s_eq;
    o_ge  <= (not s_signed_is_A_lt_B)   or s_eq;


        with i_ALU_select select
            o_ALU_out <= s_Adder_out when 3b"000", -- add other cases for different components
                         (31x"00000000" & s_signed_is_A_lt_B)   when 3b"001", -- set reg to 1 when SLT
                         (31x"00000000" & s_unsigned_is_A_lt_B) when 3b"010", -- set reg to 1 when SLTU
                         s_ALU_AND_out when 3b"011",
                         s_ALU_OR_out  when 3b"100",
                         s_ALU_XOR_out when 3b"101",
                         s_ALU_Shifter_out when 3b"110",
                         i_B when others; -- when lui, output the extended immediate


end architecture structural;


