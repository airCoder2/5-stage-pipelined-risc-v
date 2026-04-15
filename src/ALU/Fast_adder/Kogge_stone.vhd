-------------------------------------------------------------------------------
-- Kogge-Stone Parallel Prefix Adder
-- VHDL 2008 – behavioral concurrent signal assignments only (no processes)
-- Single file.
--
-- Interface:
--   generic N        : bit width (default 32, must be a power of 2)
--   A, B             : N-bit operands
--   nAdd_Sub         : 0 => add (A+B), 1 => subtract (A-B via two's complement)
--   sum              : N-bit result
--   c_out            : carry out of the MSB
--   overflow         : signed overflow flag
--
-- Architecture – Kogge-Stone parallel prefix tree:
--   Stage 0 (pre-process):
--     g(i)   = A(i) AND B(i)      -- bit-level generate
--     p(i)   = A(i) XOR B(i)      -- bit-level propagate (= sum bit pre-carry)
--
--   Stages 1..log2(N) (prefix tree, stride doubles each stage):
--     For each (G_hi, P_hi) at distance 2^(stage-1) to the left:
--       G_new = G_hi OR  (P_hi AND G_lo)
--       P_new = P_hi AND P_lo
--
--   Post-process:
--     carry(i) = prefix_G(i)                  -- carry INTO bit i+1
--     sum(0)   = p(0) XOR cin
--     sum(i)   = p(i) XOR carry(i-1)   i>0
--
--   Overflow  = carry(N-2) XOR carry(N-1)
--               (carry into sign bit XOR carry out of sign bit)
--
-- Gate delay: O(log2 N)  →  for N=32, exactly 5 prefix stages.
-- Gate count: O(N log2 N)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;          -- for log2 / integer ceiling in constant

entity kogge_stone_adder is
    generic (N : integer := 32);
    port (A        : in  std_logic_vector(N-1 downto 0);
          B        : in  std_logic_vector(N-1 downto 0);
          nAdd_Sub : in  std_logic;
          sum      : out std_logic_vector(N-1 downto 0);
          c_out    : out std_logic;
          overflow : out std_logic);
end entity kogge_stone_adder;

architecture behavioral of kogge_stone_adder is

    -- Number of prefix stages = ceil(log2(N))
    constant STAGES : integer := integer(ceil(log2(real(N))));

    -- B after optional bitwise inversion for subtraction
    signal B_eff : std_logic_vector(N-1 downto 0);

    -- cin broadcast to every bit position for the prefix seed
    signal cin : std_logic;

    ---------------------------------------------------------------------------
    -- Prefix arrays: G(stage, bit), P(stage, bit)
    --   Stage 0 = raw bit-level generate/propagate
    --   Stage k = prefix result after combining over distance 2^k
    --
    -- We model these as 2-D arrays of signals.
    -- Index: G_p(stage)(bit)  using array of vectors.
    ---------------------------------------------------------------------------
    type prefix_array is array (0 to STAGES) of std_logic_vector(N-1 downto 0);

    signal G_p : prefix_array;   -- parallel prefix generate
    signal P_p : prefix_array;   -- parallel prefix propagate

    -- Final carries: carry(i) is the carry OUT of bit i (= carry INTO bit i+1)
    -- carry(-1) conceptually = cin; we handle bit 0 separately.
    signal carry : std_logic_vector(N-1 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Invert B when subtracting; cin = nAdd_Sub (+1 for two's complement)
    ---------------------------------------------------------------------------
    B_eff <= B xor (N-1 downto 0 => nAdd_Sub);
    cin   <= nAdd_Sub;

    ---------------------------------------------------------------------------
    -- Stage 0: bit-level generate and propagate
    --   G_p(0)(i) = A(i) AND B_eff(i)
    --   P_p(0)(i) = A(i) XOR B_eff(i)
    ---------------------------------------------------------------------------
    stage0 : for i in 0 to N-1 generate
        G_p(0)(i) <= A(i) and B_eff(i);
        P_p(0)(i) <= A(i) xor B_eff(i);
    end generate stage0;

    ---------------------------------------------------------------------------
    -- Prefix stages 1 .. STAGES
    --   stride = 2^(stage-1)
    --   For bit i:
    --     if i >= stride:
    --       G_p(stage)(i) = G_p(stage-1)(i) OR  (P_p(stage-1)(i) AND G_p(stage-1)(i-stride))
    --       P_p(stage)(i) = P_p(stage-1)(i) AND  P_p(stage-1)(i-stride)
    --     else (no left neighbour at this stride):
    --       G_p(stage)(i) = G_p(stage-1)(i)    -- pass through
    --       P_p(stage)(i) = P_p(stage-1)(i)
    ---------------------------------------------------------------------------
    prefix_stages : for stage in 1 to STAGES generate
        prefix_bits : for i in 0 to N-1 generate

            -- bits that have a node to their left at this stride
            has_left : if i >= 2**(stage-1) generate
                G_p(stage)(i) <= G_p(stage-1)(i)
                               or (P_p(stage-1)(i) and G_p(stage-1)(i - 2**(stage-1)));
                P_p(stage)(i) <= P_p(stage-1)(i)
                               and P_p(stage-1)(i - 2**(stage-1));
            end generate has_left;

            -- bits with no left neighbour: pass through unchanged
            no_left : if i < 2**(stage-1) generate
                G_p(stage)(i) <= G_p(stage-1)(i);
                P_p(stage)(i) <= P_p(stage-1)(i);
            end generate no_left;

        end generate prefix_bits;
    end generate prefix_stages;

    ---------------------------------------------------------------------------
    -- Post-process: extract carries from the final prefix stage
    --
    --   carry(i) = G_p(STAGES)(i) OR (P_p(STAGES)(i) AND cin)
    --
    -- G_p(STAGES)(i) already encodes "generate from bits 0..i given cin=0",
    -- so OR-ing with the propagate×cin term gives the full carry out of bit i.
    ---------------------------------------------------------------------------
    carry_out : for i in 0 to N-1 generate
        carry(i) <= G_p(STAGES)(i) or (P_p(STAGES)(i) and cin);
    end generate carry_out;

    ---------------------------------------------------------------------------
    -- Sum bits
    --   sum(0) = P_p(0)(0) XOR cin          (propagate of bit 0 = A(0) xor B(0))
    --   sum(i) = P_p(0)(i) XOR carry(i-1)   for i > 0
    ---------------------------------------------------------------------------
    sum(0) <= P_p(0)(0) xor cin;

    sum_bits : for i in 1 to N-1 generate
        sum(i) <= P_p(0)(i) xor carry(i-1);
    end generate sum_bits;

    ---------------------------------------------------------------------------
    -- Carry out and overflow
    ---------------------------------------------------------------------------
    c_out    <= carry(N-1);
    overflow <= carry(N-2) xor carry(N-1);

end architecture behavioral;
