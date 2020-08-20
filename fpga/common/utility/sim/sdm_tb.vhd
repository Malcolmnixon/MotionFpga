-------------------------------------------------------------------------------
--! @file
--! @brief Sigma-Delta modulator test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Sigma-Delta modulator test bench
ENTITY sdm_tb IS
END ENTITY sdm_tb;

--! Architecture tb of sdm_tb entity
ARCHITECTURE tb OF sdm_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name      : string(1 TO 20);      --! Stimulus name
        rst       : std_logic;            --! rst input to uut
        sdm_level : unsigned(1 DOWNTO 0); --! sdm_level input to uut
        percent   : integer;              --! Expected on-percent from uut
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array :=
    (
        (
            name      => "Hold in reset       ",
            rst       => '1',
            sdm_level => B"11",
            percent   => 0
        ),
        (
            name      => "Running value 0     ",
            rst       => '0',
            sdm_level => B"00",
            percent   => 0
        ),
        (
            name      => "Running value 1     ",
            rst       => '0',
            sdm_level => B"01",
            percent   => 25
        ),
        (
            name      => "Running value 2     ",
            rst       => '0',
            sdm_level => B"10",
            percent   => 50
        ),
        (
            name      => "Running value 3     ",
            rst       => '0',
            sdm_level => B"11",
            percent   => 75
        )
    );

    -- Signals to uut
    SIGNAL clk       : std_logic;            --! Clock input to sdm uut
    SIGNAL rst       : std_logic;            --! Reset input to sdm uut
    SIGNAL sdm_level : unsigned(1 DOWNTO 0); --! Level input to sdm uut
    SIGNAL sdm_out   : std_logic;            --! Modulator output from sdm uut
    
    -- Signals to on_percent
    SIGNAL on_rst     : std_logic; --! Reset input to on_percent
    SIGNAL on_percent : integer;   --! Percent output from on_percent

BEGIN

    --! Instantiate sigma-delta modulator as unit under test
    i_uut : ENTITY work.sdm(rtl)
        GENERIC MAP (
            bit_width => 2
        )
        PORT MAP (
            mod_clk_in   => clk,
            mod_rst_in   => rst,
            sdm_level_in => sdm_level,
            sdm_out      => sdm_out
        );

    --! Instantiate on_percent
    i_on_percent : ENTITY work.sim_on_percent(sim)
        PORT MAP (
            mod_clk_in  => clk,
            mod_rst_in  => on_rst,
            signal_in   => sdm_out,
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
        rst       <= '1';
        sdm_level <= (OTHERS => '0');
        on_rst    <= '1';
        WAIT FOR c_clk_period;
        
        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;

            -- Set stimulus inputs
            sdm_level <= c_stimulus(s).sdm_level;
            rst       <= c_stimulus(s).rst;

            -- Wait for sdm to stabilize
            WAIT FOR 10 * c_clk_period;
            
            -- Enable sdm counting
            on_rst <= '0';
            
            -- Accumuate 100 clocks 
            WAIT FOR 100 * c_clk_period;
            
            -- Assert outputs
            ASSERT on_percent >= c_stimulus(s).percent - 5 AND
                on_percent <= c_stimulus(s).percent + 5
                REPORT "Expected sdm of " & integer'image(c_stimulus(s).percent)
                & " but got " & integer'image(on_percent)
                SEVERITY error;

            -- Stop sdm counting
            on_rst <= '1';
        END LOOP;

        -- Log end of test
        REPORT "Finished" SEVERITY note;

        -- Finish the simulation
        std.env.finish;

    END PROCESS pr_stimulus;

END ARCHITECTURE tb;

