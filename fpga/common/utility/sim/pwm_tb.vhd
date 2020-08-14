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

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name : string(1 TO 20);          --! Stimulus name
        rst  : std_logic_vector(0 TO 9); --! rst input to uut
        adv  : std_logic_vector(0 TO 9); --! adv input to uut
        duty : integer RANGE 0 TO 3;     --! duty input to uut
        pwm  : std_logic_vector(0 TO 9); --! pwm expected from uut
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array :=
    (
        (
            name => "Hold in reset       ",
            rst  => "1111111111",
            adv  => "0000000000",
            duty => 3,
            pwm  => "0000000000"
        ),
        (
            name => "Freeze              ",
            rst  => "1000000000",
            adv  => "0000000000",
            duty => 3,
            pwm  => "0000000000"
        ),
        (
            name => "Running period 3    ",
            rst  => "1000000000",
            adv  => "1111111111",
            duty => 3,
            pwm  => "0111111111"
        ),
        (
            name => "Running period 2    ",
            rst  => "1000000000",
            adv  => "1111111111",
            duty => 2,
            pwm  => "0110110110"
        ),
        (
            name => "Running period 1    ",
            rst  => "1000000000",
            adv  => "1111111111",
            duty => 1,
            pwm  => "0100100100"
        ),
        (
            name => "Running period 0    ",
            rst  => "1000000000",
            adv  => "1111111111",
            duty => 0,
            pwm  => "0000000000"
        )
    );

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
            mod_clk_in  => clk,
            mod_rst_in  => rst,
            pwm_adv_in  => adv,
            pwm_duty_in => duty,
            pwm_out     => pwm
        );

    --! @brief Clock generation process
    pr_clock : PROCESS IS
    BEGIN
    
        -- Low for 1/2 clock period
        clk <= '0';
        WAIT FOR c_clk_period / 2;
        
        -- High for 1/2 clock period
        clk <= '1';
        WAIT FOR c_clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process to drive PWM unit under test
    pr_stimulus : PROCESS IS
    BEGIN

        -- Initialize entity inputs
        rst  <= '1';
        adv  <= '0';
        duty <= 0;
        WAIT FOR c_clk_period;

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;

            -- Set duty for this stimulus
            duty <= c_stimulus(s).duty;

            -- Loop for test stimulus
            FOR t IN 0 TO 9 LOOP
                -- Set inputs then wait for clock to rise
                adv <= c_stimulus(s).adv(t);
                rst <= c_stimulus(s).rst(t);
                WAIT UNTIL clk = '1';

                -- Wait for clk to fall
                WAIT UNTIL clk = '0';

                -- Assert outputs
                ASSERT pwm = c_stimulus(s).pwm(t)
                    REPORT "At time " & integer'image(t)
                    & " expected " & std_logic'image(c_stimulus(s).pwm(t))
                    & " but got " & std_logic'image(pwm)
                    SEVERITY error;
            END LOOP;
        END LOOP;

        -- Log end of test
        REPORT "Finished" SEVERITY note;

        -- Finish the simulation
        std.env.finish;

    END PROCESS pr_stimulus;

END ARCHITECTURE tb;

