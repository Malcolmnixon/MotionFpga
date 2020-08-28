-------------------------------------------------------------------------------
--! @file
--! @brief Step Generator module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Step Generator entity
--!
--! This step-generator entity produces a number of step-pulses. This is
--! commonly used for devices such as stepper motor driver chips.
--!
--! When the user asserts the enable_in signal the step-generation begins. The
--! user can de-assert enable_in to cancel step-generation.
--!
--! The advance_in flag should be pulsed at the basic step-generation rate. 
--! This rate is divided down by the delay_in count to produce the stepping
--! rate.
ENTITY step_generator IS
    GENERIC (
        count_wid : integer RANGE 1 TO integer'high := 4; --! Width of count
        delay_wid : integer RANGE 1 TO integer'high := 6  --! Width of delay
    );
    PORT (
        mod_clk_in : IN    std_logic;                                --! Module clock
        mod_rst_in : IN    std_logic;                                --! Module reset (async)
        enable_in  : IN    std_logic;                                --! Generator enable flag
        advance_in : IN    std_logic;                                --! Advance flag
        count_in   : IN    std_logic_vector(count_wid - 1 DOWNTO 0); --! Count of steps
        delay_in   : IN    std_logic_vector(delay_wid - 1 DOWNTO 0); --! Delay between steps
        step_out   : OUT   std_logic                                 --! Step output
    );
END ENTITY step_generator;

--! Architecture rtl of step_generator entity
ARCHITECTURE rtl OF step_generator IS

    --! Current step counter
    SIGNAL count : unsigned(count_wid - 1 DOWNTO 0);
    
    --! Current delay counter
    SIGNAL delay : unsigned(count_wid - 1 DOWNTO 0);
    
    --! Step state
    SIGNAL step : std_logic;
    
BEGIN

    --! @brief Process to generate steps
    pr_step : PROCESS (mod_clk_in, mod_rst_in) IS
    BEGIN
    
        IF (mod_rst_in = '1') THEN
            -- Reset
            count <= (OTHERS => '0');
            delay <= (OTHERS => '0');
            step  <= '0';
        ELSIF (rising_edge(mod_clk_in)) THEN
            IF (enable_in = '0') THEN
                -- Reset (disabled)
                count <= (OTHERS => '0');
                delay <= (OTHERS => '0');
                step  <= '0';
            ELSIF (advance_in = '1') THEN
                -- Check for step-generator delay
                IF (delay = 0) THEN
                    -- Delay expired, reset
                    delay <= unsigned(delay_in);
                    
                    -- Check for more steps to generate
                    IF (count /= unsigned(count_in)) THEN
                        -- Check for end of step ('1' going to '0')
                        IF (step = '1') THEN
                            -- Advance step count
                            count <= count + 1;
                        END IF;
                        
                        -- Toggle step-line
                        step <= NOT step;
                    END IF;
                ELSE
                    -- More delay
                    delay <= delay - 1;
                END IF;
            END IF;
        END IF;
        
    END PROCESS pr_step;

    -- Output step signal
    step_out <= step;
    
END ARCHITECTURE rtl;
