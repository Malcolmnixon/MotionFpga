-------------------------------------------------------------------------------
--! @file
--! @brief PWM device test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief PWM device test bench
ENTITY pwm_device_tb IS
END ENTITY pwm_device_tb;

--! Architecture tb of pwm_device_tb entity
ARCHITECTURE tb OF pwm_device_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    -- Signals to unit under test
    SIGNAL clk         : std_logic;                     --! Clock input to pwm device
    SIGNAL rst         : std_logic;                     --! Reset input to pwm device
    SIGNAL pwm_adv     : std_logic;                     --! PWM advance input to pwm device
    SIGNAL dat_wr_done : std_logic;                     --! Data write done input to pwm device
    SIGNAL dat_wr_reg  : std_logic_vector(31 DOWNTO 0); --! Data write register input to pwm device
    SIGNAL dat_rd_strt : std_logic;                     --! Data read start input to pwm device
    SIGNAL dat_rd_reg  : std_logic_vector(31 DOWNTO 0); --! Data read register output from pwm device
    SIGNAL pwm         : std_logic_vector(3 DOWNTO 0);  --! PWM outputs from pwm device

BEGIN

    --! Instantiate PWM device as unit under test
    i_uut : ENTITY work.pwm_device(rtl)
        PORT MAP (
            mod_clk_in     => clk,
            mod_rst_in     => rst,
            pwm_adv_in     => pwm_adv,
            dat_wr_done_in => dat_wr_done,
            dat_wr_reg_in  => dat_wr_reg,
            dat_rd_strt_in => dat_rd_strt,
            dat_rd_reg_out => dat_rd_reg,
            pwm_out        => pwm
        );

    --! @brief Clock generator process
    --!
    --! This generates the clk signal and the adv signal
    pr_clock : PROCESS IS
    BEGIN
    
        clk     <= '0';
        pwm_adv <= '0';
        WAIT FOR c_clk_period / 2;

        clk     <= '1';
        pwm_adv <= '1';
        WAIT FOR c_clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process to drive PWM unit under test
    pr_stimulus : PROCESS IS
    BEGIN
        
        -- Reset inputs
        dat_wr_reg  <= (OTHERS => '0');
        dat_wr_done <= '0';
        dat_rd_strt <= '0';
        
        -- Reset for 8 clock periods
        rst <= '1';
        WAIT FOR c_clk_period * 8;
        
        -- Take out of reset for 8 clock periods
        rst <= '0';
        WAIT FOR c_clk_period * 8;
        
        -- Read PWM device
        dat_rd_strt <= '1';
        WAIT FOR c_clk_period;
        dat_rd_strt <= '0';
        ASSERT (dat_rd_reg = B"00000000_00000000_00000000_00000000")
            REPORT "Expected pwm_device zero duty cycles after reset"
            SEVERITY warning;
        
        -- Write PWM command
        dat_wr_reg  <= B"11111111_10101010_01010101_00000000";
        dat_wr_done <= '1';
        WAIT FOR c_clk_period;
        dat_wr_done <= '0';
        
        -- Read PWM device
        dat_rd_strt <= '1';
        WAIT FOR c_clk_period;
        dat_rd_strt <= '0';
        ASSERT (dat_rd_reg = B"11111111_10101010_01010101_00000000") 
            REPORT "Expected pwm_device non zero duty cycles after configuration"
            SEVERITY warning;
        
        -- Take out of reset for 800 clock periods
        rst <= '0';
        WAIT FOR c_clk_period * 800;
        
        -- Finish the simulation
        std.env.finish;
        
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;

