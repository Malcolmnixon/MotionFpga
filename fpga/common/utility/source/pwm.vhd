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
--! @image html pwm_entity.png "PWM Entity"
--!
--! This entity is a configurable PWM generator. The 'count_max' determines 
--! how high the PWM will count to before rolling over. The 'pwm_duty' input
--! determines when the PWM will turn off in the cycle.
--!
--! A pwm_duty of '0' causes the pwm to stay low all the time; where-as a 
--! pwm_duty of 'count_max + 1' causes the pwm to stay high all the time.
ENTITY pwm IS
    GENERIC (
        bit_width : natural RANGE 2 TO 32 := 8 --! PWM width
    );
    PORT (
        mod_clk_in  : IN    std_logic;                                --! Clock
        mod_rst_in  : IN    std_logic;                                --! Reset (async)
        pwm_adv_in  : IN    std_logic;                                --! PWM Advance flag
        pwm_duty_in : IN    std_logic_vector(bit_width - 1 DOWNTO 0); --! PWM duty cycle
        pwm_out     : OUT   std_logic                                 --! PWM output
    );
END ENTITY pwm;

--! Architecture rtl of pwm entity
ARCHITECTURE rtl OF pwm IS

    --! Maximum PWM count
    CONSTANT c_count_max : natural := (2 ** bit_width) - 2;

    --! PWM count
    SIGNAL count : unsigned(pwm_duty_in'range);
    
    --! PWM state
    SIGNAL state : std_logic;
    
BEGIN

    --! @brief Process for PWM generation
    pr_pwm : PROCESS (mod_clk_in, mod_rst_in) IS
    BEGIN
    
        IF (mod_rst_in = '1') THEN
            -- Reset state
            count <= (OTHERS => '0');
            state <= '0';
        ELSIF (rising_edge(mod_clk_in)) THEN
            IF (pwm_adv_in = '1') THEN
                -- Drive state
                IF (count < unsigned(pwm_duty_in)) THEN
                    state <= '1';
                ELSE
                    state <= '0';
                END IF;
                
                -- Increment count
                IF (count = c_count_max) THEN
                    count <= (OTHERS => '0');
                ELSE
                    count <= count + 1;
                END IF;			
            END IF;
        END IF;
            
    END PROCESS pr_pwm;
    
    pwm_out <= state;
       
END ARCHITECTURE rtl;
