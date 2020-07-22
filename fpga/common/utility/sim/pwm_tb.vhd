-------------------------------------------------------------------------------
--! @file
--! @brief PWM test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief PWM test bench
ENTITY pwm_tb IS
END ENTITY pwm_tb;

--! Architecture tb of pwm_tb entity
ARCHITECTURE tb OF pwm_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10ns;
    
    -- Signals to unit under test
    SIGNAL clk  : std_logic;            --! Clock input to pwm unit under test
    SIGNAL rst  : std_logic;            --! Reset input to pwm unit under test
    SIGNAL adv  : std_logic;            --! PWM advance input to pwm unit under test
    SIGNAL duty : integer RANGE 0 TO 3; --! Duty-cycle input to pwm unit under test
    SIGNAL pwm  : std_logic;            --! PWM output from pwm unit under test

BEGIN

    --! Instantiate PWM as unit under test
    i_uut : ENTITY work.pwm(rtl)
        GENERIC MAP (
            count_max => 2
        )
        PORT MAP (
            clk_in  => clk,
            rst_in  => rst,
            adv_in  => adv,
            duty_in => duty,
            pwm_out => pwm
        );

    --! @brief Clock generator process
    --!
    --! This generates the clk signal and the adv signal
    pr_clock : PROCESS IS
    BEGIN
    
        clk <= '0';
        adv <= '0';
        WAIT FOR c_clk_period / 2;

        clk <= '1';
        adv <= '1';
        WAIT FOR c_clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process to drive PWM unit under test
    pr_stimulus : PROCESS IS
    BEGIN
        
        -- Reset for 8 clock periods
        rst  <= '1';
        duty <= 3;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while in reset" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while in reset" SEVERITY warning;
        
        -- Take out of reset and skip a full count cycle to react
        rst <= '0';
        WAIT FOR c_clk_period * 3;
        
        -- Verify on for 3/3
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 0@3/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 1@3/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 2@3/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 0@3/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 1@3/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 2@3/3" SEVERITY warning;
        
        -- Drop duty to 2 and skip a full count cycle to react
        duty <= 2;
        WAIT FOR c_clk_period * 3;
        
        -- Verify on for 2/3
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 0@2/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 1@2/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 2@2/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 0@2/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 1@2/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 2@2/3" SEVERITY warning;
        
        -- Drop duty to 1 and skip a full count cycle to react
        duty <= 1;
        WAIT FOR c_clk_period * 3;
        
        -- Verify on for 1/3
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 0@1/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 1@1/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 2@1/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '1') REPORT "Expected pwm high while 0@1/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 1@1/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 2@1/3" SEVERITY warning;
        
        -- Drop duty to 1 and skip a full count cycle to react
        duty <= 0;
        WAIT FOR c_clk_period * 3;
        
        -- Verify on for 0/3
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 0@0/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 1@0/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 2@0/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 0@0/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 1@0/3" SEVERITY warning;
        WAIT FOR c_clk_period;
        ASSERT (pwm = '0') REPORT "Expected pwm low while 2@0/3" SEVERITY warning;
		
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;

