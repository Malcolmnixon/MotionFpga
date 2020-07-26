-------------------------------------------------------------------------------
--! @file
--! @brief Clock divider test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief clk_div_n test bench
ENTITY clk_div_n_tb IS
END ENTITY clk_div_n_tb;

--! Architecture tb of clk_div_n_tb entity
ARCHITECTURE tb OF clk_div_n_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    -- Signals to unit under test
    SIGNAL clk     : std_logic; --! Clock input to unit under test
    SIGNAL rst     : std_logic; --! Reset input to unit under test
    SIGNAL cnt_en  : std_logic; --! Count enable input to unit under test
    SIGNAL cnt_out : std_logic; --! Count output from unit under test
    
BEGIN

    --! Instantiate clk_div_n as unit under test
    i_uut : ENTITY work.clk_div_n(rtl)
        GENERIC MAP (
            divide => 4
        )
        PORT MAP (
            mod_clk_in => clk,
            mod_rst_in => rst,
            cnt_en_in  => cnt_en,
            cnt_out    => cnt_out
        );

    --! @brief Clock generator process
    --!
    --! This generates the clk signal
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
        
        -- Reset for 4 clock periods
        rst    <= '1';
        cnt_en <= '0';
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while in reset" SEVERITY warning;
        
        -- Take out of reset, but keep counting disabled for 4 clock periods
        rst <= '0';
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while disabled" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while disabled" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while disabled" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while disabled" SEVERITY warning;
        
        -- Enable counting and verify output every fourth clock period
        cnt_en <= '1';
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while at time 1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while at time 2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while at time 3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '1') REPORT "Expected output high while at time 4/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while at time 1/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while at time 2/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '0') REPORT "Expected output low while at time 3/4" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (cnt_out = '1') REPORT "Expected output high while at time 4/4" SEVERITY warning;
		
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;
