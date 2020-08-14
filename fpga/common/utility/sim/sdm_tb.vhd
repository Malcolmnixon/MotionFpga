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

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name      : string(1 TO 20);           --! Stimulus name
        rst       : std_logic_vector(0 TO 12); --! rst input to uut
        sdm_level : unsigned(1 DOWNTO 0);      --! sdm_level input to uut
        sdm_out   : std_logic_vector(0 TO 12); --! sdm_out expected from uut
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
            rst       => "1111111111111",
            sdm_level => B"11",
            sdm_out   => "0000000000000"
        ),
        (
            name      => "Running value 0     ",
            rst       => "1000000000000",
            sdm_level => B"00",
            sdm_out   => "0000000000000"
        ),
        (
            name      => "Running value 1     ",
            rst       => "1000000000000",
            sdm_level => B"01",
            sdm_out   => "0000100010001"
        ),
        (
            name      => "Running value 2     ",
            rst       => "1000000000000",
            sdm_level => B"10",
            sdm_out   => "0010101010101"
        ),
        (
            name      => "Running value 3     ",
            rst       => "1000000000000",
            sdm_level => B"11",
            sdm_out   => "0011101110111"
        )
    );

    -- Signals to unit under test
    SIGNAL clk       : std_logic;            --! Clock input to unit under test
    SIGNAL rst       : std_logic;            --! Reset input to unit under test
    SIGNAL sdm_level : unsigned(1 DOWNTO 0); --! Level input to unit under test
    SIGNAL sdm_out   : std_logic;            --! Modulator output from unit under test

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
        
        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;

            -- Set level for this stimulus
            sdm_level <= c_stimulus(s).sdm_level;

            -- Loop for test stimulus
            FOR t IN 0 TO 9 LOOP
                -- Set inputs then wait for clock to rise
                rst <= c_stimulus(s).rst(t);
                WAIT UNTIL clk = '1';

                -- Wait for clk to fall
                WAIT UNTIL clk = '0';

                -- Assert outputs
                ASSERT sdm_out = c_stimulus(s).sdm_out(t)
                    REPORT "At time " & integer'image(t)
                    & " expected " & std_logic'image(c_stimulus(s).sdm_out(t))
                    & " but got " & std_logic'image(sdm_out)
                    SEVERITY error;
            END LOOP;
        END LOOP;

        -- Log end of test
        REPORT "Finished" SEVERITY note;

        -- Finish the simulation
        std.env.finish;

    END PROCESS pr_stimulus;

END ARCHITECTURE tb;

