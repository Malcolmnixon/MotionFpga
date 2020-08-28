-------------------------------------------------------------------------------
--! @file
--! @brief Step Generator test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief step_generator test bench
ENTITY step_generator_tb IS
END ENTITY step_generator_tb;

--! Architecture tb of step_generator_tb entity
ARCHITECTURE tb OF step_generator_tb IS

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name    : string(1 TO 20);              --! Stimulus name
        rst     : std_logic;                    --! rst input to uut
        count   : std_logic_vector(2 DOWNTO 0); --! count input to uut
        delay   : std_logic_vector(2 DOWNTO 0); --! delay input to uut
        rise    : integer;                      --! Expected rise count
        fall    : integer;                      --! Expected fall count
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;
    
    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name  => "Hold in reset       ",
            rst   => '1',
            count => B"000",
            delay => B"000",
            rise  => 0,
            fall  => 0
        ),
        ( 
            name  => "No steps            ",
            rst   => '0',
            count => B"000",
            delay => B"000",
            rise  => 0,
            fall  => 0
        ),
        ( 
            name  => "One step            ",
            rst   => '0',
            count => B"001",
            delay => B"111",
            rise  => 1,
            fall  => 1
        ),
        ( 
            name  => "Two steps           ",
            rst   => '0',
            count => B"010",
            delay => B"100",
            rise  => 2,
            fall  => 2
        ),
        ( 
            name  => "Three steps         ",
            rst   => '0',
            count => B"011",
            delay => B"011",
            rise  => 3,
            fall  => 3
        ),
        ( 
            name  => "Four steps          ",
            rst   => '0',
            count => B"100",
            delay => B"010",
            rise  => 4,
            fall  => 4
        ),
        ( 
            name  => "Five steps          ",
            rst   => '0',
            count => B"101",
            delay => B"001",
            rise  => 5,
            fall  => 5
        ),
        ( 
            name  => "Six steps           ",
            rst   => '0',
            count => B"110",
            delay => B"001",
            rise  => 6,
            fall  => 6
        ),
        ( 
            name  => "Seven steps         ",
            rst   => '0',
            count => B"111",
            delay => B"000",
            rise  => 7,
            fall  => 7
        ),
        ( 
            name  => "Overrun             ",
            rst   => '0',
            count => B"111",
            delay => B"111",
            rise  => 3,
            fall  => 2
        )
    );

    -- Signals to step_generator uut
    SIGNAL clk     : std_logic;                    --! Clock
    SIGNAL rst     : std_logic;                    --! Reset
    SIGNAL enable  : std_logic;                    --! Enable input to uut
    SIGNAL advance : std_logic;                    --! Advance input to uut
    SIGNAL count   : std_logic_vector(2 DOWNTO 0); --! Count input to uut
    SIGNAL delay   : std_logic_vector(2 DOWNTO 0); --! Delay input to uut
    SIGNAL step    : std_logic;                    --! Step output from uut

    -- Signals for edge counter
    SIGNAL edge_rst  : std_logic; --! Reset edge counter
    SIGNAL edge_rise : integer;   --! Count of rising edges
    SIGNAL edge_fall : integer;   --! Count of falling edges
    
BEGIN

    --! Instantiate step_generator as unit under test
    i_uut : ENTITY work.step_generator(rtl)
        GENERIC MAP (
            count_wid => 3,
            delay_wid => 3
        )
        PORT MAP (
            mod_clk_in  => clk,
            mod_rst_in  => rst,
            enable_in   => enable,
            advance_in  => advance,
            count_in    => count,
            delay_in    => delay,
            step_out    => step
        );
        
    --! Instantiate clk_div_n to generate advance pulses every 4th clock
    i_adv_divisor : ENTITY work.clk_div_n(rtl)
        GENERIC MAP (
            clk_div => 4
        )
        PORT MAP (
            mod_clk_in  => clk,
            mod_rst_in  => rst,
            clk_adv_in  => '1',
            clk_end_out => OPEN,
            clk_pls_out => advance
        );
    
    --! Instantiate edge counter to analyze edges
    i_edge_count : ENTITY work.sim_edge_count(sim)
        PORT MAP (
            mod_clk_in => clk,
            mod_rst_in => edge_rst,
            signal_in  => step,
            rise_out   => edge_rise,
            fall_out   => edge_fall
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
        rst      <= '1';
        edge_rst <= '1';
        enable   <= '0';
        WAIT FOR c_clk_period;

        -- Assert step is idle
        ASSERT step = '0'
            REPORT "Expected step = 0 but got " & std_logic'image(step)
            SEVERITY error;

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;
            
            -- Enable edge counter
            edge_rst <= '0';
            WAIT UNTIL clk = '1';
            WAIT UNTIL clk = '0';
            
            -- Set inputs then wait for clock to rise
            rst    <= c_stimulus(s).rst;
            count  <= c_stimulus(s).count;
            delay  <= c_stimulus(s).delay;
            enable <= '1';
            WAIT UNTIL clk = '1';
            WAIT UNTIL clk = '0';
            
            -- Wait for the clock generation to finish (other than the overrun case)
            WAIT FOR c_clk_period * 4 * 7 * 5;
            
            -- Assert edges
            ASSERT edge_rise = c_stimulus(s).rise 
                REPORT "Expected " & integer'image(c_stimulus(s).rise)
                & " rising edges, but got " & integer'image(edge_rise)
                SEVERITY error;
            ASSERT edge_fall = c_stimulus(s).fall
                REPORT "Expected " & integer'image(c_stimulus(s).fall)
                & " falling edges, but got " & integer'image(edge_fall)
                SEVERITY error;

            -- Clear enable
            edge_rst <= '1';
            enable   <= '0';
            WAIT FOR c_clk_period;

            -- Assert step is idle
            ASSERT step = '0'
                REPORT "Expected step = 0 but got " & std_logic'image(step)
                SEVERITY error;
        END LOOP;

        -- Log end of test
        REPORT "Finished" SEVERITY note;
        
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;

END ARCHITECTURE tb;
