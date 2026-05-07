-- =============================================================================
-- ALU Testbench
-- Tests all 8 ALU operations:
--   i_ALU_select = 000 : ADD / SUB
--   i_ALU_select = 001 : SLT  (signed less than)
--   i_ALU_select = 010 : SLTU (unsigned less than)
--   i_ALU_select = 011 : AND
--   i_ALU_select = 100 : OR
--   i_ALU_select = 101 : XOR
--   i_ALU_select = 110 : Shift
--   i_ALU_select = 111 : LUI  (pass-through B)
-- =============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_types.all;

entity ALU_tb is
end entity ALU_tb;

architecture behavior of ALU_tb is

    -- -------------------------------------------------------------------------
    -- Component Declaration
    -- -------------------------------------------------------------------------
    component ALU is
        port( i_A            : in  std_logic_vector(31 downto 0);
              i_B            : in  std_logic_vector(31 downto 0);
              i_ALU_select   : in  std_logic_vector(2 downto 0);
              i_ALU_nAdd_sub : in  std_logic;
              i_logcl_arith  : in  std_logic;
              i_right_left   : in  std_logic;
              i_jal_or_jalr  : in  std_logic;
              o_eq           : out std_logic;
              o_lt           : out std_logic;
              o_ltu          : out std_logic;
              o_ge           : out std_logic;
              o_geu          : out std_logic;
              o_ALU_out      : out std_logic_vector(31 downto 0));
    end component ALU;

    -- -------------------------------------------------------------------------
    -- Signals
    -- -------------------------------------------------------------------------
    signal s_A            : std_logic_vector(31 downto 0) := (others => '0');
    signal s_B            : std_logic_vector(31 downto 0) := (others => '0');
    signal s_ALU_select   : std_logic_vector(2 downto 0)  := "000";
    signal s_nAdd_sub     : std_logic := '0';
    signal s_logcl_arith  : std_logic := '0';
    signal s_right_left   : std_logic := '0';
    signal s_jal_or_jalr  : std_logic := '0';
    signal s_eq           : std_logic;
    signal s_lt           : std_logic;
    signal s_ltu          : std_logic;
    signal s_ge           : std_logic;
    signal s_geu          : std_logic;
    signal s_ALU_out      : std_logic_vector(31 downto 0);

    -- Propagation delay between test cases
    constant c_DELAY : time := 20 ns;

begin

    -- -------------------------------------------------------------------------
    -- DUT Instantiation
    -- -------------------------------------------------------------------------
    DUT: ALU
        port map(
            i_A            => s_A,
            i_B            => s_B,
            i_ALU_select   => s_ALU_select,
            i_ALU_nAdd_sub => s_nAdd_sub,
            i_logcl_arith  => s_logcl_arith,
            i_right_left   => s_right_left,
            i_jal_or_jalr  => s_jal_or_jalr,
            o_eq           => s_eq,
            o_lt           => s_lt,
            o_ltu          => s_ltu,
            o_ge           => s_ge,
            o_geu          => s_geu,
            o_ALU_out      => s_ALU_out
        );

    -- -------------------------------------------------------------------------
    -- Stimulus Process
    -- -------------------------------------------------------------------------
    stim_proc: process
    begin

        -- =====================================================================
        -- GROUP 1: ADD (select=000, nAdd_sub=0)
        -- Expected: o_ALU_out = A + B
        -- =====================================================================
        s_ALU_select  <= "000";
        s_nAdd_sub    <= '0';
        s_jal_or_jalr <= '0';

        -- Test 1a: simple positive add  5 + 3 = 8
        s_A <= x"00000005"; s_B <= x"00000003"; wait for c_DELAY;
        assert s_ALU_out = x"00000008"
            report "ADD FAIL: 5+3 expected 0x00000008 got " & to_hstring(s_ALU_out) severity error;

        -- Test 1b: add with zero  42 + 0 = 42
        s_A <= x"0000002A"; s_B <= x"00000000"; wait for c_DELAY;
        assert s_ALU_out = x"0000002A"
            report "ADD FAIL: 42+0 expected 0x0000002A" severity error;

        -- Test 1c: add producing carry/wrap  0xFFFFFFFF + 1 = 0x00000000
        s_A <= x"FFFFFFFF"; s_B <= x"00000001"; wait for c_DELAY;
        assert s_ALU_out = x"00000000"
            report "ADD FAIL: wraparound expected 0x00000000" severity error;

        -- Test 1d: add two negative (twos-complement) numbers  (-1)+(-1) = -2
        s_A <= x"FFFFFFFF"; s_B <= x"FFFFFFFF"; wait for c_DELAY;
        assert s_ALU_out = x"FFFFFFFE"
            report "ADD FAIL: (-1)+(-1) expected 0xFFFFFFFE" severity error;

        -- =====================================================================
        -- GROUP 2: SUB (select=000, nAdd_sub=1)
        -- Expected: o_ALU_out = A - B
        -- =====================================================================
        s_ALU_select <= "000";
        s_nAdd_sub   <= '1';

        -- Test 2a: 10 - 3 = 7
        s_A <= x"0000000A"; s_B <= x"00000003"; wait for c_DELAY;
        assert s_ALU_out = x"00000007"
            report "SUB FAIL: 10-3 expected 0x00000007" severity error;

        -- Test 2b: equal operands -> 0, eq flag = 1
        s_A <= x"0000BEEF"; s_B <= x"0000BEEF"; wait for c_DELAY;
        assert s_ALU_out = x"00000000" and s_eq = '1'
            report "SUB FAIL: A-A expected 0x0 with eq=1" severity error;

        -- Test 2c: 0 - 1 = 0xFFFFFFFF (borrow / negative result)
        s_A <= x"00000000"; s_B <= x"00000001"; wait for c_DELAY;
        assert s_ALU_out = x"FFFFFFFF"
            report "SUB FAIL: 0-1 expected 0xFFFFFFFF" severity error;

        -- =====================================================================
        -- GROUP 3: JAL/JALR mode — adder uses 0x4 as B operand
        -- Expected: o_ALU_out = A + 4
        -- =====================================================================
        s_ALU_select  <= "000";
        s_nAdd_sub    <= '0';
        s_jal_or_jalr <= '1';

        -- Test 3a: PC=0x00000100 + 4 = 0x00000104
        s_A <= x"00000100"; s_B <= x"DEADBEEF"; wait for c_DELAY;  -- s_B is irrelevant
        assert s_ALU_out = x"00000104"
            report "JAL FAIL: PC+4 expected 0x00000104" severity error;

        s_jal_or_jalr <= '0';  -- Return to normal

        -- =====================================================================
        -- GROUP 4: SLT — signed less than (select=001)
        -- Expected: o_ALU_out = 1 when A < B (signed), else 0
        --           o_lt flag mirrors result
        -- =====================================================================
        s_ALU_select <= "001";
        s_nAdd_sub   <= '1';  -- Subtraction drives comparisons

        -- Test 4a: 3 < 5  -> 1
        s_A <= x"00000003"; s_B <= x"00000005"; wait for c_DELAY;
        assert s_ALU_out = x"00000001" and s_lt = '1'
            report "SLT FAIL: 3<5 expected 1" severity error;

        -- Test 4b: 5 < 3  -> 0
        s_A <= x"00000005"; s_B <= x"00000003"; wait for c_DELAY;
        assert s_ALU_out = x"00000000" and s_lt = '0'
            report "SLT FAIL: 5<3 expected 0" severity error;

        -- Test 4c: -1 (0xFFFFFFFF) < 1  -> 1 (signed)
        s_A <= x"FFFFFFFF"; s_B <= x"00000001"; wait for c_DELAY;
        assert s_ALU_out = x"00000001" and s_lt = '1'
            report "SLT FAIL: -1 < 1 signed expected 1" severity error;

        -- Test 4d: 1 < -1 -> 0 (signed)
        s_A <= x"00000001"; s_B <= x"FFFFFFFF"; wait for c_DELAY;
        assert s_ALU_out = x"00000000" and s_lt = '0'
            report "SLT FAIL: 1 < -1 signed expected 0" severity error;

        -- =====================================================================
        -- GROUP 5: SLTU — unsigned less than (select=010)
        -- Expected: o_ALU_out = 1 when A < B (unsigned), else 0
        -- =====================================================================
        s_ALU_select <= "010";
        s_nAdd_sub   <= '1';

        -- Test 5a: 3 < 5 unsigned -> 1
        s_A <= x"00000003"; s_B <= x"00000005"; wait for c_DELAY;
        assert s_ALU_out = x"00000001" and s_ltu = '1'
            report "SLTU FAIL: 3<5 expected 1" severity error;

        -- Test 5b: 0xFFFFFFFF > 1 unsigned -> 0
        s_A <= x"FFFFFFFF"; s_B <= x"00000001"; wait for c_DELAY;
        assert s_ALU_out = x"00000000" and s_ltu = '0'
            report "SLTU FAIL: 0xFFFFFFFF < 1 unsigned expected 0" severity error;

        -- Test 5c: 1 < 0xFFFFFFFF unsigned -> 1
        s_A <= x"00000001"; s_B <= x"FFFFFFFF"; wait for c_DELAY;
        assert s_ALU_out = x"00000001" and s_ltu = '1'
            report "SLTU FAIL: 1 < 0xFFFFFFFF unsigned expected 1" severity error;

        -- =====================================================================
        -- GROUP 6: AND (select=011)
        -- Expected: o_ALU_out = A AND B (bitwise)
        -- =====================================================================
        s_ALU_select <= "011";
        s_nAdd_sub   <= '0';

        -- Test 6a: 0xFF00FF00 AND 0x0F0F0F0F = 0x0F000F00
        s_A <= x"FF00FF00"; s_B <= x"0F0F0F0F"; wait for c_DELAY;
        assert s_ALU_out = x"0F000F00"
            report "AND FAIL: expected 0x0F000F00" severity error;

        -- Test 6b: all ones AND all zeros = 0
        s_A <= x"FFFFFFFF"; s_B <= x"00000000"; wait for c_DELAY;
        assert s_ALU_out = x"00000000"
            report "AND FAIL: 0xFFFFFFFF & 0x0 expected 0" severity error;

        -- Test 6c: mask lower nibble  0xDEADBEEF AND 0x0000000F = 0x0000000F
        s_A <= x"DEADBEEF"; s_B <= x"0000000F"; wait for c_DELAY;
        assert s_ALU_out = x"0000000F"
            report "AND FAIL: nibble mask expected 0x0000000F" severity error;

        -- =====================================================================
        -- GROUP 7: OR (select=100)
        -- Expected: o_ALU_out = A OR B (bitwise)
        -- =====================================================================
        s_ALU_select <= "100";

        -- Test 7a: 0xF0F0F0F0 OR 0x0F0F0F0F = 0xFFFFFFFF
        s_A <= x"F0F0F0F0"; s_B <= x"0F0F0F0F"; wait for c_DELAY;
        assert s_ALU_out = x"FFFFFFFF"
            report "OR FAIL: expected 0xFFFFFFFF" severity error;

        -- Test 7b: OR with 0 = identity
        s_A <= x"ABCD1234"; s_B <= x"00000000"; wait for c_DELAY;
        assert s_ALU_out = x"ABCD1234"
            report "OR FAIL: identity expected 0xABCD1234" severity error;

        -- Test 7c: set bits  0x00000000 OR 0xDEAD0000 = 0xDEAD0000
        s_A <= x"00000000"; s_B <= x"DEAD0000"; wait for c_DELAY;
        assert s_ALU_out = x"DEAD0000"
            report "OR FAIL: set upper half expected 0xDEAD0000" severity error;

        -- =====================================================================
        -- GROUP 8: XOR (select=101)
        -- Expected: o_ALU_out = A XOR B (bitwise)
        -- =====================================================================
        s_ALU_select <= "101";

        -- Test 8a: 0xAAAAAAAA XOR 0x55555555 = 0xFFFFFFFF
        s_A <= x"AAAAAAAA"; s_B <= x"55555555"; wait for c_DELAY;
        assert s_ALU_out = x"FFFFFFFF"
            report "XOR FAIL: expected 0xFFFFFFFF" severity error;

        -- Test 8b: A XOR A = 0  (also verifies eq flag)
        s_A <= x"12345678"; s_B <= x"12345678"; wait for c_DELAY;
        assert s_ALU_out = x"00000000"
            report "XOR FAIL: A XOR A expected 0" severity error;

        -- Test 8c: XOR with all ones = bitwise NOT
        s_A <= x"DEADBEEF"; s_B <= x"FFFFFFFF"; wait for c_DELAY;
        assert s_ALU_out = x"21524110"
            report "XOR FAIL: NOT(0xDEADBEEF) expected 0x21524110" severity error;

        -- =====================================================================
        -- GROUP 9: SHIFT (select=110)
        -- i_logcl_arith : 0=logical, 1=arithmetic
        -- i_right_left  : 0=left,    1=right
        -- =====================================================================
        s_ALU_select <= "110";
        s_nAdd_sub   <= '0';

        -- Test 9a: logical left shift  0x00000001 << 4 = 0x00000010
        s_A           <= x"00000001";
        s_B           <= x"00000004";  -- shift amount in B[4:0]
        s_logcl_arith <= '0';
        s_right_left  <= '0'; wait for c_DELAY;
        assert s_ALU_out = x"00000010"
            report "SLL FAIL: 1<<4 expected 0x00000010" severity error;

        -- Test 9b: logical left shift  0x00000001 << 16 = 0x00010000
        s_A           <= x"00000001";
        s_B           <= x"00000010";  -- shift amount = 16
        s_logcl_arith <= '0';
        s_right_left  <= '0'; wait for c_DELAY;
        assert s_ALU_out = x"00010000"
            report "SLL FAIL: 1<<16 expected 0x00010000" severity error;

        -- Test 9c: logical right shift  0x80000000 >> 4 = 0x08000000
        s_A           <= x"80000000";
        s_B           <= x"00000004";  -- shift amount = 4
        s_logcl_arith <= '0';
        s_right_left  <= '1'; wait for c_DELAY;
        assert s_ALU_out = x"08000000"
            report "SRL FAIL: 0x80000000>>4 expected 0x08000000" severity error;

        -- Test 9d: arithmetic right shift  0x80000000 >> 4 = 0xF8000000 (sign extended)
        s_A           <= x"80000000";
        s_B           <= x"00000004";  -- shift amount = 4
        s_logcl_arith <= '1';
        s_right_left  <= '1'; wait for c_DELAY;
        assert s_ALU_out = x"F8000000"
            report "SRA FAIL: 0x80000000>>4 expected 0xF8000000" severity error;

        -- Test 9e: arithmetic right shift positive number (same as logical)
        s_A           <= x"70000000";
        s_B           <= x"00000004";
        s_logcl_arith <= '1';
        s_right_left  <= '1'; wait for c_DELAY;
        assert s_ALU_out = x"07000000"
            report "SRA FAIL: 0x70000000>>4 expected 0x07000000" severity error;

        -- =====================================================================
        -- GROUP 10: LUI pass-through (select=111)
        -- Expected: o_ALU_out = i_B (immediate passed straight through)
        -- =====================================================================
        s_ALU_select <= "111";
        s_A          <= x"DEADBEEF";  -- should be ignored
        s_B          <= x"CAFEBABE"; wait for c_DELAY;
        assert s_ALU_out = x"CAFEBABE"
            report "LUI FAIL: expected B pass-through 0xCAFEBABE" severity error;

        s_B <= x"12345000"; wait for c_DELAY;
        assert s_ALU_out = x"12345000"
            report "LUI FAIL: expected 0x12345000" severity error;

        -- =====================================================================
        -- GROUP 11: Branch flag checks
        -- Use subtraction mode with select=000 and verify all five flags
        -- =====================================================================
        s_ALU_select <= "000";
        s_nAdd_sub   <= '1';

        -- Test 11a: A == B  -> eq=1, lt=0, ltu=0, ge=1, geu=1
        s_A <= x"00000007"; s_B <= x"00000007"; wait for c_DELAY;
        assert s_eq='1' and s_lt='0' and s_ltu='0' and s_ge='1' and s_geu='1'
            report "FLAG FAIL: A==B expected eq=1 lt=0 ltu=0 ge=1 geu=1" severity error;

        -- Test 11b: A < B signed   3 < 10
        s_A <= x"00000003"; s_B <= x"0000000A"; wait for c_DELAY;
        assert s_eq='0' and s_lt='1' and s_ge='0'
            report "FLAG FAIL: 3<10 expected lt=1 ge=0" severity error;

        -- Test 11c: A > B signed   10 > 3
        s_A <= x"0000000A"; s_B <= x"00000003"; wait for c_DELAY;
        assert s_eq='0' and s_lt='0' and s_ge='1'
            report "FLAG FAIL: 10>3 expected lt=0 ge=1" severity error;

        -- Test 11d: unsigned comparison  1 < 0xFFFFFFFF unsigned
        s_A <= x"00000001"; s_B <= x"FFFFFFFF"; wait for c_DELAY;
        assert s_ltu='1' and s_geu='0'
            report "FLAG FAIL: 1 < 0xFFFFFFFF unsigned expected ltu=1 geu=0" severity error;

        -- Test 11e: unsigned comparison  0xFFFFFFFF > 1 unsigned
        s_A <= x"FFFFFFFF"; s_B <= x"00000001"; wait for c_DELAY;
        assert s_ltu='0' and s_geu='1'
            report "FLAG FAIL: 0xFFFFFFFF > 1 unsigned expected ltu=0 geu=1" severity error;

        -- =====================================================================
        -- All tests complete
        -- =====================================================================
        report "===== ALL ALU TESTS COMPLETE =====" severity note;
        wait;

    end process stim_proc;

end architecture behavior;
