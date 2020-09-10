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
    CONSTANT c_clk_period : time := 10 ns;

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name    : string(1 TO 20);              --! Stimulus name
        rst     : std_logic;                    --! rst input to uut
        adv     : std_logic;                    --! adv input to uut
        duty    : std_logic_vector(1 DOWNTO 0); --! duty input to uut
        percent : integer;                      --! Expected percent
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array :=
    (
        (
            name    => "Hold in reset       ",
            rst     => '1',
            adv     => '0',
            duty    => B"00",
            percent => 0
        ),
        (
            name    => "Freeze              ",
            rst     => '0',
            adv     => '0',
            duty    => B"11",
            percent => 0
        ),
        (
            name    => "Running period 3    ",
            rst     => '0',
            adv     => '1',
            duty    => B"11",
            percent => 100
        ),
        (
            name    => "Running period 2    ",
            rst     => '0',
            adv     => '1',
            duty    => B"10",
            percent => 67
        ),
        (
            name    => "Running period 1    ",
            rst     => '0',
            adv     => '1',
            duty    => B"01",
            percent => 33
        ),
        (
            name    => "Running period 0    ",
            rst     => '0',
            adv     => '1',
            duty    => B"00",
            percent => 0
        )
    );

    -- Signals to uut
    SIGNAL clk  : std_logic;                    --! Clock input to pwm uut
    SIGNAL rst  : std_logic;                    --! Reset input to pwm uut
    SIGNAL adv  : std_logic;                    --! PWM advance input to pwm uut
    SIGNAL duty : std_logic_vector(1 DOWNTO 0); --! Duty-cycle input to pwm uut
    SIGNAL pwm  : std_logic;                    --! PWM output from pwm uut
    
    -- Signals to on_percent
    SIGNAL on_rst     : std_logic; --! Reset input to on_percent
    SIGNAL on_percent : integer;   --! Percent output from on_percent

BEGIN

    --! Instantiate PWM as uut
    i_uut : ENTITY work.pwm(rtl)
        GENERIC MAP (
            bit_width => 2
        )
        PORT MAP (
            clk_in      => clk,
            rst_in      => rst,
            pwm_adv_in  => adv,
            pwm_duty_in => duty,
            pwm_out     => pwm
        );
        
    --! Instantiate on_percent
    i_on_percent : ENTITY work.sim_on_percent(sim)
        PORT MAP (
            clk_in      => clk,
            rst_in      => on_rst,
            signal_in   => pwm,
            percent_out => on_percent
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
        rst    <= '1';
        adv    <= '0';
        duty   <= B"00";
        on_rst <= '1';
        WAIT FOR c_clk_period;

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;

            -- Set stimulus inputs
            duty <= c_stimulus(s).duty;
            adv  <= c_stimulus(s).adv;
            rst  <= c_stimulus(s).rst;

            -- Wait for pwm to stabilize
            WAIT FOR 10 * c_clk_period;
            
            -- Enable pwm counting
            on_rst <= '0';
            
            -- Accumuate 100 clocks 
            WAIT FOR 100 * c_clk_period;
            
            -- Assert outputs
            ASSERT on_percent >= c_stimulus(s).percent - 5 AND
                on_percent <= c_stimulus(s).percent + 5
                REPORT "Expected pwm of " & integer'image(c_stimulus(s).percent)
                & " but got " & integer'image(on_percent)
                SEVERITY error;

            -- Stop pwm counting
            on_rst <= '1';
        END LOOP;

        -- Log end of test
        REPORT "Finished" SEVERITY note;

        -- Finish the simulation
        std.env.finish;

    END PROCESS pr_stimulus;

END ARCHITECTURE tb;

