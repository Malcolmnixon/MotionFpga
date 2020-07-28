-------------------------------------------------------------------------------
--! @file
--! @brief Sigma-Delta modulator test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Sigma-Delta modulator test bench
ENTITY sdm_tb IS
END ENTITY sdm_tb;

--! Architecture tb of sdm_tb entity
ARCHITECTURE tb OF sdm_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10ns;
    
    -- Signals to unit under test
    SIGNAL clk       : std_logic;            --! Clock input to unit under test
    SIGNAL rst       : std_logic;            --! Reset input to unit under test
    SIGNAL sdm_level : unsigned(1 DOWNTO 0); --! Level input to unit under test
    SIGNAL sdm_out   : std_logic;            --! Modulator output from unit under test

BEGIN

    --! Instantiate sigma-delta modulator as unit under test
    i_uut : ENTITY work.sdm(rtl)
        GENERIC MAP (
            bit_width => 2
        )
        PORT MAP (
            mod_clk_in   => clk,
            mod_rst_in   => rst,
            sdm_level_in => sdm_level,
            sdm_out      => sdm_out
        );

    --! @brief Clock generator process
    --!
    --! This generates the clk signal and the adv signal
    pr_clock : PROCESS IS
    BEGIN
    
        clk <= '0';
        WAIT FOR c_clk_period / 2;

        clk <= '1';
        WAIT FOR c_clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process to drive PWM unit under test
    pr_stimulus : PROCESS IS
    BEGIN
        
        -- Reset for 8 clock periods
        rst       <= '1';
        sdm_level <= B"11";
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while in reset" SEVERITY warning;
        
        -- Reset cycle and start at 0/4
        rst       <= '1';
        WAIT FOR c_clk_period;
        sdm_level <= B"00";
        rst       <= '0';

        -- Verify 0/4 cycle
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 0@0/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 0@0/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 0@0/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 0@0/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 0@0/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 0@0/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 0@0/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 0@0/4" SEVERITY warning;
        
        -- Reset cycle and start at 1/4
        rst       <= '1';
        WAIT FOR c_clk_period;
        sdm_level <= B"01";
        rst       <= '0';
        
        -- Verify on for 1/4
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 1@1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 2@1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 3@1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 4@1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 1@1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 2@1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 3@1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 4@1/4" SEVERITY warning;
        
        -- Reset cycle and start at 2/4
        rst       <= '1';
        WAIT FOR c_clk_period;
        sdm_level <= B"10";
        rst       <= '0';
        
        -- Verify on for 2/4
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 2@2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 4@2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 2@2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 4@2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 2@2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 4@2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 2@2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 4@2/4" SEVERITY warning;
        
        -- Reset cycle and start at 3/4
        rst       <= '1';
        WAIT FOR c_clk_period;
        sdm_level <= B"11";
        rst       <= '0';
        
        -- Verify on for 3/4
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 3@3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 2@3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out low while 1@3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 0@3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '0') REPORT "Expected sdm_out low while 3@3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 2@3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out low while 1@3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (sdm_out = '1') REPORT "Expected sdm_out high while 0@3/4" SEVERITY warning;
		
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;

