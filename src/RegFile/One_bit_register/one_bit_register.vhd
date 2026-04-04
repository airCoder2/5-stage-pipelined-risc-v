-- Date        : Feb 4, 2026
-- File        : one_bit_register.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file contains an implementation of a one bit register file

library IEEE;
use IEEE.std_logic_1164.all;

-- Description of the one-bit regster
entity one_bit_register is
    generic(Reset_value : std_logic);
	port(i_CLK      : in std_logic;     -- Clock input
	   i_RST        : in std_logic;     -- Reset input
	   i_WE         : in std_logic;     -- Write enable input
	   i_D          : in std_logic;     -- Data value input
	   o_Q          : out std_logic);   -- Data value output
end entity one_bit_register;

-- Architecture, uses d_flip_flop and a mux
architecture structural of one_bit_register is

    component d_flip_flop is
        generic(Reset_value : std_logic);
        port(i_CLK        : in std_logic;     -- Clock input
             i_RST        : in std_logic;     -- Reset input
             i_D          : in std_logic;     -- Data value input
             o_Q          : out std_logic);   -- Data value output
    end component d_flip_flop;

	component mux2t1_structural is
		port(I0_IN : in std_logic;
			 I1_IN : in std_logic;
			 S_IN  : in std_logic;
			 F_OUT : out std_logic);
	end component mux2t1_structural;

	signal mux_out : std_logic;
    signal s_Q : std_logic;
begin

    s_Q <= o_Q;

	mux: mux2t1_structural port map(
			I0_IN => s_Q,
			I1_IN => i_D,
			S_IN  => i_WE,
			F_OUT => mux_out);
	
	dff: d_flip_flop 
        generic map(Reset_value => Reset_value)
        port map(
			i_CLK => i_CLK,  
			i_RST => i_RST,
			i_D   => mux_out, -- assign the input of the dff to the output of the mux
			o_Q   => o_Q);

end architecture structural;

