-------------------------------------------------------------------------------
--! @file
--! @brief PWM module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief PWM entity
--!
--! This entity is a configurable PWM generator. The 'count_max' determines 
--! how high the PWM will count to before rolling over. The 'duty_in' input
--! determines when the PWM will turn off in the cycle.
--!
--! A duty_in of '0' causes the pwm to stay low all the time; where-as a 
--! duty_in of 'count_max + 1' causes the pwm to stay high all the time.
ENTITY pwm IS
    GENERIC (
        count_max : integer := 254 --! PWM count maximum
    );
    PORT (
        clk_in  : IN    std_logic;                        --! Clock
        rst_in  : IN    std_logic;                        --! Reset (async)
        adv_in  : IN    std_logic;                        --! PWM Advance flag
        duty_in : IN    integer RANGE 0 TO count_max + 1; --! PWM duty cycle
        pwm_out : OUT   std_logic                         --! PWM output
    );
END ENTITY pwm;

--! Architecture rtl of pwm entity
ARCHITECTURE rtl OF pwm IS

    --! PWM count
    SIGNAL count : integer RANGE 0 TO count_max;
    
    --! PWM state
    SIGNAL state : std_logic;
    
BEGIN

    --! @brief Process for PWM generation
    pr_pwm : PROCESS (clk_in, rst_in) IS
    BEGIN
    
        IF (rst_in = '1') THEN
            -- Reset state
            count <= 0;
            state <= '0';
        ELSIF (rising_edge(clk_in) AND adv_in = '1') THEN
            -- Drive state
            IF (count < integer(duty_in)) THEN
                state <= '1';
            ELSE
                state <= '0';
            END IF;
            
            -- Increment count
            IF (count = count_max) THEN
                count <= 0;
            ELSE
                count <= count + 1;
            END IF;			
        END IF;
            
    END PROCESS pr_pwm;
    
    pwm_out <= state;
       
END ARCHITECTURE rtl;
