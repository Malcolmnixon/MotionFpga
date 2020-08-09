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
        name    : string(1 TO 20);
        rst_in  : std_logic_vector(0 TO 9);
        duty_in : integer RANGE 0 TO 3;
        pwm_out : std_logic_vector(0 TO 9);
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array :=
    (
        (
            name      => "Hold in reset       ",
            rst_in    => "1111111111",
            duty_in   => 3,
            pwm_out   => "0000000000"
        ),
        (
            name      => "Running period 3    ",
            rst_in    => "1000000000",
            duty_in   => 3,
            pwm_out   => "0111111111"
        ),
        (
            name      => "Running period 2    ",
            rst_in    => "1000000000",
            duty_in   => 2,
            pwm_out   => "0110110110"
        ),
        (
            name      => "Running period 1    ",
            rst_in    => "1000000000",
            duty_in   => 1,
            pwm_out   => "0100100100"
        ),
        (
            name      => "Running period 0    ",
            rst_in    => "1000000000",
            duty_in   => 0,
            pwm_out   => "0000000000"
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

    --! @brief Stimulus process to drive PWM unit under test
    pr_stimulus : PROCESS IS
    BEGIN

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;

            duty <= c_stimulus(s).duty_in;

            -- Loop for test stimulus
            FOR t IN 0 TO 9 LOOP
                -- Drive inputs
                clk <= '0';
                adv <= '0';
                rst <= c_stimulus(s).rst_in(t);
                WAIT FOR c_clk_period / 2;

                -- Rising edge
                clk <= '1';
                adv <= '1';
                WAIT FOR c_clk_period / 2;

                -- Assert outputs
                ASSERT pwm = c_stimulus(s).pwm_out(t)
                    REPORT "At time " & integer'image(t)
                    & " expected " & std_logic'image(c_stimulus(s).pwm_out(t))
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

