-- Date        : Feb 20, 2026
-- File        : AddSub_immediate.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file adds another mux to my adder_subtractractor to
-- 				 select between an immediate 32 bit value or a source

library IEEE;
use IEEE.std_logic_1164.all;

entity Adder_Subtractor_immediate is
	generic (N : integer := 32);
	port( A  	   : in std_logic_vector(N-1 downto 0);
		  B        : in std_logic_vector(N-1 downto 0);
		  imm      : in std_logic_vector(N-1 downto 0);
		  ALU_src  : in std_logic;
	      nAdd_Sub : in std_logic;
		  sum      : out std_logic_vector(N-1 downto 0)); -- outputs is +1 of inputs
end entity Adder_Subtractor_immediate;

architecture structural of Adder_Subtractor_immediate is

	-- adding the adder_subtractor
	component Adder_Subtractor is
		generic (N : integer);
		port( A  	   : in std_logic_vector(N-1 downto 0);
			  B        : in std_logic_vector(N-1 downto 0);
			  nAdd_Sub : in std_logic;
			  sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
			  c_out    : out std_logic;
			  overflow : out std_logic);
	end component Adder_Subtractor;

	component mux2t1_N_dataflow is
		generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
		port(i_S          : in std_logic;
			 i_D0         : in std_logic_vector(N-1 downto 0);
			 i_D1         : in std_logic_vector(N-1 downto 0);
			 o_O          : out std_logic_vector(N-1 downto 0));
	end component mux2t1_N_dataflow;

	signal immediate_B_Mux_out : std_logic_vector(N-1 downto 0);
    signal trash : std_logic;
    signal bin : std_logic;

begin

    Add_Subtractor: Adder_Subtractor
            generic map(N => N)
            port map(
                     A => A,
                     B => immediate_B_Mux_out,
                     nAdd_Sub => nAdd_Sub,
                     sum => sum,
                     c_out => trash,
                     overflow => bin);
                     -- don't need c_out and overflow

	mux2t1_N: mux2t1_N_dataflow
			generic map(N => 32)
			port map(
					 i_S => ALU_src,
					 i_D0 => B,
				 	 i_D1 => imm,
					 o_O  => immediate_B_Mux_out);
        

            



end architecture structural;

