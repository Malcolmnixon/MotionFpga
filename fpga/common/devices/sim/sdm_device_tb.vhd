-------------------------------------------------------------------------------
--! @file
--! @brief SDM device test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief SDM device test bench
ENTITY sdm_device_tb IS
END ENTITY sdm_device_tb;

--! Architecture tb of sdm_device_tb entity
ARCHITECTURE tb OF sdm_device_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    --! Type for percentage array
    TYPE t_percent_array IS ARRAY(0 TO 3) OF integer;

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name    : string(1 TO 30);               --! Stimulus name
        rst     : std_logic;                     --! Reset input to sdm_device
        data_wr : std_logic_vector(31 DOWNTO 0); --! Write data to sdm_device
        data_rd : std_logic_vector(31 DOWNTO 0); --! Expected read data from sdm_device
        percent : t_percent_array;               --! Expected sdm percents
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name    => "Reset                         ",
            rst     => '1',
            data_wr => X"FFFFFFFF",
            data_rd => X"00000000",
            percent => (0, 0, 0, 0)
        ),
        ( 
            name    => "Set 0, 0, 0, 0                ",
            rst     => '0',
            data_wr => X"00000000",
            data_rd => X"00000000",
            percent => (0, 0, 0, 0)
        ),
        ( 
            name    => "Set 255, 255, 255, 255        ",
            rst     => '0',
            data_wr => X"FFFFFFFF",
            data_rd => X"FFFFFFFF",
            percent => (100, 100, 100, 100)
        ),
        ( 
            name    => "Set 127, 127, 127, 127        ",
            rst     => '0',
            data_wr => X"7F7F7F7F",
            data_rd => X"7F7F7F7F",
            percent => (50, 50, 50, 50)
        ),
        ( 
            name    => "Set 0, 85, 170, 255           ",
            rst     => '0',
            data_wr => X"FFAA5500",
            data_rd => X"FFAA5500",
            percent => (0, 33, 67, 100)
        ),
        ( 
            name    => "Set 0, 0, 0, 0                ",
            rst     => '0',
            data_wr => X"00000000",
            data_rd => X"00000000",
            percent => (0, 0, 0, 0)
        )
    );
    
    -- Signals to uut
    SIGNAL clk         : std_logic;                     --! Clock input to uut
    SIGNAL rst         : std_logic;                     --! Reset input to uut
    SIGNAL dat_wr_done : std_logic;                     --! Data write done input to uut
    SIGNAL dat_wr_reg  : std_logic_vector(31 DOWNTO 0); --! Data write register input to uut
    SIGNAL dat_rd_reg  : std_logic_vector(31 DOWNTO 0); --! Data read register output from uut
    SIGNAL sdm_out     : std_logic_vector(3 DOWNTO 0);  --! PWM outputs from uut
    
    -- Signals to on_percent
    SIGNAL on_rst     : std_logic;       --! Reset input to on_percent
    SIGNAL on_percent : t_percent_array; --! Percent output from on_percent

    --! Function to create string from std_logic_vector
    FUNCTION to_string (
        vector : std_logic_vector) RETURN string 
    IS
    
        VARIABLE v_str : string(1 TO vector'length);
        
    BEGIN
    
        FOR i IN vector'range LOOP
            v_str(i + 1) := std_logic'image(vector(i))(2);
        END LOOP;
        
        RETURN v_str;
        
    END FUNCTION to_string;

BEGIN

    --! Instantiate SDM device as uut
    i_uut : ENTITY work.sdm_device(rtl)
        PORT MAP (
            clk_in         => clk,
            rst_in         => rst,
            dat_wr_done_in => dat_wr_done,
            dat_wr_reg_in  => dat_wr_reg,
            dat_rd_reg_out => dat_rd_reg,
            sdm_out        => sdm_out
        );

    --! Generate on_percent measuring entities
    g_on_percent : FOR i IN 0 TO 3 GENERATE
        
        --! Instantiate on_percent
        i_on_percent : ENTITY work.sim_on_percent(sim)
            PORT MAP (
                clk_in      => clk,
                rst_in      => on_rst,
                signal_in   => sdm_out(i),
                percent_out => on_percent(i)
            );
    
    END GENERATE g_on_percent;

    --! @brief Clock generator process
    --!
    --! This generates the clk signal and the adv signal
    pr_clock : PROCESS IS
    BEGIN
    
        clk <= '0';
        WAIT FOR c_clk_period / 2;

        clk <= '1';
        WAIT FOR c_clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process to drive SDM unit under test
    pr_stimulus : PROCESS IS
    BEGIN
        
        -- Initialize entity inputs
        rst         <= '1';
        on_rst      <= '1';
        dat_wr_reg  <= (OTHERS => '0');
        dat_wr_done <= '0';
        WAIT FOR c_clk_period;
        
        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
        
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;

            -- Perform write to device
            rst         <= c_stimulus(s).rst;
            dat_wr_reg  <= c_stimulus(s).data_wr;
            dat_wr_done <= '1';
            WAIT FOR c_clk_period;
            dat_wr_done <= '0';
            
            -- Wait for sdms to stabilize
            WAIT FOR 256 * c_clk_period;
            
            -- Enable sdm counting
            on_rst <= '0';
            
            -- Accumuate 256*10 clocks 
            WAIT FOR 2560 * c_clk_period;
            
            -- Assert sdm channels
            FOR i IN 0 TO 3 LOOP
            
                -- Assert sdm channel
                ASSERT on_percent(i) >= c_stimulus(s).percent(i) - 5 AND
                    on_percent(i) <= c_stimulus(s).percent(i) + 5
                    REPORT "SDM channel " &
                    integer'image(i) &
                    " expected sdm of " & 
                    integer'image(c_stimulus(s).percent(i)) &
                    " but got " & 
                    integer'image(on_percent(i))
                    SEVERITY error;

            END LOOP;

            -- Assert read from device
            ASSERT dat_rd_reg = c_stimulus(s).data_rd
                REPORT "Expected read of " &
                to_string(c_stimulus(s).data_rd) &
                " but got " &
                to_string(dat_rd_reg)
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
