library IEEE;
use IEEE.std_logic_1164.all;


entity tb_another_test_addSub_imm is
end entity;

architecture tb of tb_another_test_addSub_imm is

    component Adder_Subtractor_immediate is
        generic (N : integer := 32);
        port( A  	   : in std_logic_vector(N-1 downto 0);
              B        : in std_logic_vector(N-1 downto 0);
              imm      : in std_logic_vector(N-1 downto 0);
              ALU_src  : in std_logic;
              nAdd_Sub : in std_logic;
              sum      : out std_logic_vector(N-1 downto 0)); -- outputs is +1 of inputs
    end component Adder_Subtractor_immediate;

    signal s_A   : std_logic_vector(31 downto 0);
    signal s_B   : std_logic_vector(31 downto 0);
    signal s_imm : std_logic_vector(31 downto 0);
    signal s_sum : std_logic_vector(31 downto 0);

    signal s_nAdd_Sub : std_logic;
    signal s_ALU_src      : std_logic;

begin

    Adde_S: Adder_Subtractor_immediate
        generic map(N => 32)
        port map(
                 A       => s_A,
                 B       => s_B,
                 imm     => s_imm,
                 ALU_src => s_ALU_src,
                 sum     => s_sum,
                 nAdd_Sub => s_nAdd_Sub
                );

    test: process
    begin

        wait for 10 ns;
        
        --s_A <= 32x"0000_0000";
        --s_B <= 32x"FFFF_FFFF";

        s_A <= 32x"0000_0005";

        s_B <= 32x"0000_0002";
        s_imm <= 32x"FFFF_FFFF"; 


        s_ALU_src <= '1';
        s_nAdd_Sub <= '0';

        wait;


    end process test;



end architecture;



