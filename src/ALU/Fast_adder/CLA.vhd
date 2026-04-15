-------------------------------------------------------------------------------
-- Carry Lookahead Adder (CLA)
-- VHDL 2008 – behavioral concurrent signal assignments only (no processes)
-- Single file.
--
-- Interface:
--   generic N        : bit width (default 32, must be a multiple of 4)
--   A, B             : N-bit operands
--   nAdd_Sub         : 0 => add (A+B), 1 => subtract (A-B via two's complement)
--   sum              : N-bit result
--   c_out            : carry out of the MSB
--   overflow         : signed overflow flag
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 4-bit CLA block
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity cla_4bit is
    port (A3, A2, A1, A0 : in  std_logic;
          B3, B2, B1, B0 : in  std_logic;
          c_in           : in  std_logic;
          S3, S2, S1, S0 : out std_logic;
          c_out          : out std_logic;
          G_grp, P_grp   : out std_logic);
end entity cla_4bit;

architecture behavioral of cla_4bit is

    signal g0, g1, g2, g3 : std_logic;
    signal p0, p1, p2, p3 : std_logic;
    signal c1, c2, c3     : std_logic;

begin

    -- Generate and propagate
    g0 <= A0 and B0;
    g1 <= A1 and B1;
    g2 <= A2 and B2;
    g3 <= A3 and B3;

    p0 <= A0 xor B0;
    p1 <= A1 xor B1;
    p2 <= A2 xor B2;
    p3 <= A3 xor B3;

    -- Lookahead carry equations
    c1 <= g0
        or (p0 and c_in);

    c2 <= g1
        or (p1 and g0)
        or (p1 and p0 and c_in);

    c3 <= g2
        or (p2 and g1)
        or (p2 and p1 and g0)
        or (p2 and p1 and p0 and c_in);

    c_out <= g3
        or (p3 and g2)
        or (p3 and p2 and g1)
        or (p3 and p2 and p1 and g0)
        or (p3 and p2 and p1 and p0 and c_in);

    -- Group generate / propagate (for potential higher-level CLA cascading)
    G_grp <= g3
        or (p3 and g2)
        or (p3 and p2 and g1)
        or (p3 and p2 and p1 and g0);

    P_grp <= p3 and p2 and p1 and p0;

    -- Sum bits
    S0 <= p0 xor c_in;
    S1 <= p1 xor c1;
    S2 <= p2 xor c2;
    S3 <= p3 xor c3;

end architecture behavioral;

-------------------------------------------------------------------------------
-- Top-level: carry_lookahead_adder
--
-- Chains NUM_BLOCKS = N/4 cla_4bit instances.
-- B is XOR-ed with nAdd_Sub for two's complement subtraction.
-- carry(0) = nAdd_Sub  (+1 when subtracting).
-- overflow = carry into MSB block XOR carry out of MSB block.
--
-- Constraint: N must be a multiple of 4.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity carry_lookahead_adder is
    generic (N : integer := 32);
    port (A        : in  std_logic_vector(N-1 downto 0);
          B        : in  std_logic_vector(N-1 downto 0);
          nAdd_Sub : in  std_logic;
          sum      : out std_logic_vector(N-1 downto 0);
          c_out    : out std_logic;
          overflow : out std_logic);
end entity carry_lookahead_adder;

architecture behavioral of carry_lookahead_adder is

    constant NUM_BLOCKS : integer := N / 4;

    component cla_4bit is
        port (A3, A2, A1, A0 : in  std_logic;
              B3, B2, B1, B0 : in  std_logic;
              c_in           : in  std_logic;
              S3, S2, S1, S0 : out std_logic;
              c_out          : out std_logic;
              G_grp, P_grp   : out std_logic);
    end component;

    signal B_eff : std_logic_vector(N-1 downto 0);
    signal carry : std_logic_vector(NUM_BLOCKS downto 0);
    signal G_blk : std_logic_vector(NUM_BLOCKS-1 downto 0);
    signal P_blk : std_logic_vector(NUM_BLOCKS-1 downto 0);

begin

    -- Invert B for subtraction (nAdd_Sub=1 => two's complement)
    B_eff <= B xor (N-1 downto 0 => nAdd_Sub);

    -- Carry-in of first block: 1 when subtracting, 0 when adding
    carry(0) <= nAdd_Sub;

    -- Chain of 4-bit CLA blocks
    gen_blocks : for blk in 0 to NUM_BLOCKS-1 generate
        u_cla : cla_4bit
            port map (
                A0    => A(blk*4),
                A1    => A(blk*4 + 1),
                A2    => A(blk*4 + 2),
                A3    => A(blk*4 + 3),
                B0    => B_eff(blk*4),
                B1    => B_eff(blk*4 + 1),
                B2    => B_eff(blk*4 + 2),
                B3    => B_eff(blk*4 + 3),
                c_in  => carry(blk),
                S0    => sum(blk*4),
                S1    => sum(blk*4 + 1),
                S2    => sum(blk*4 + 2),
                S3    => sum(blk*4 + 3),
                c_out => carry(blk + 1),
                G_grp => G_blk(blk),
                P_grp => P_blk(blk));
    end generate gen_blocks;

    c_out    <= carry(NUM_BLOCKS);
    overflow <= carry(NUM_BLOCKS - 1) xor carry(NUM_BLOCKS);

end architecture behavioral;
