-------------------------------------------------------------------------------
--! @file
--! @brief PWM device
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief PWM device entity
--!
--! @image html pwm_device_entity.png "PWM Device Entity"
--!
--! This entity manages four PWM devices. The write register contains the 
--! four 8-bit PWM duty cycles. The read register contains the current four
--! 8-bit PWM duty cycles.
ENTITY pwm_device IS
    PORT (
        mod_clk_in     : IN    std_logic;                     --! Module Clock
        mod_rst_in     : IN    std_logic;                     --! Module Reset (async)
        dat_wr_done_in : IN    std_logic;                     --! Device Write Done flag
        dat_wr_reg_in  : IN    std_logic_vector(31 DOWNTO 0); --! Device Write Register value
        dat_rd_strt_in : IN    std_logic;                     --! Device Read Start flag
        dat_rd_reg_out : OUT   std_logic_vector(31 DOWNTO 0); --! Device Read Register value
        pwm_adv_in     : IN    std_logic;                     --! PWM Advance flag
        pwm_out        : OUT   std_logic_vector(3 DOWNTO 0)   --! PWM outputs
    );
END ENTITY pwm_device;

--! Architecture rtl of pwm_device entity
ARCHITECTURE rtl OF pwm_device IS

    --! Array type of four duty-cycles
    TYPE pwm_duty_set IS ARRAY (3 DOWNTO 0) OF integer RANGE 0 TO 255;
    
    --! Duty cycles array
    SIGNAL pwm_duty : pwm_duty_set;
    
BEGIN

    --! Generate four PWMs
    g_pwm : FOR i IN 0 TO 3 GENERATE

        --! Generate PWM instance
        i_pwm : ENTITY work.pwm(rtl)
            GENERIC MAP (
                count_max => 254
            )
            PORT MAP (
                mod_clk_in  => mod_clk_in,
                mod_rst_in  => mod_rst_in,
                pwm_adv_in  => pwm_adv_in,
                pwm_duty_in => pwm_duty(i),
                pwm_out     => pwm_out(i)
            );

    END GENERATE g_pwm;

    --! @brief Process to handle writes and resets
    pr_write : PROCESS (mod_clk_in, mod_rst_in) IS
    BEGIN
        
        IF (mod_rst_in = '1') THEN
            -- Reset duty cycles
            pwm_duty(3) <= 0;
            pwm_duty(2) <= 0;
            pwm_duty(1) <= 0;
            pwm_duty(0) <= 0;
        ELSIF (rising_edge(mod_clk_in) AND dat_wr_done_in = '1') THEN
            -- Set duty cycles from write register
            pwm_duty(3) <= to_integer(unsigned(dat_wr_reg_in(31 DOWNTO 24)));
            pwm_duty(2) <= to_integer(unsigned(dat_wr_reg_in(23 DOWNTO 16)));
            pwm_duty(1) <= to_integer(unsigned(dat_wr_reg_in(15 DOWNTO 8)));
            pwm_duty(0) <= to_integer(unsigned(dat_wr_reg_in(7 DOWNTO 0)));
        END IF;
        
    END PROCESS pr_write;

    --! @brief Process to handle reads
    pr_read : PROCESS (mod_clk_in) IS
    BEGIN
    
        IF (rising_edge(mod_clk_in) AND dat_rd_strt_in = '1') THEN
            -- Populate read register with duty cycles
            dat_rd_reg_out <= std_logic_vector(to_unsigned(pwm_duty(3), 8)) &
                              std_logic_vector(to_unsigned(pwm_duty(2), 8)) &
                              std_logic_vector(to_unsigned(pwm_duty(1), 8)) &
                              std_logic_vector(to_unsigned(pwm_duty(0), 8));
        END IF;
        
    END PROCESS pr_read;
    
END ARCHITECTURE rtl;
