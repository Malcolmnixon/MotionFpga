-------------------------------------------------------------------------------
--! @file
--! @brief GPIO device test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief GPIO device test bench
ENTITY gpio_device_tb IS
END ENTITY gpio_device_tb;

--! Architecture tb of gpio_device_tb entity
ARCHITECTURE tb OF gpio_device_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name     : string(1 TO 30);               --! Stimulus name
        rst      : std_logic;                     --! Reset input to gpio_device
        data_wr  : std_logic_vector(31 DOWNTO 0); --! Write data to gpio_device
        data_rd  : std_logic_vector(31 DOWNTO 0); --! Expected read data from gpio_device
        gpio_in  : std_logic_vector(31 DOWNTO 0); --! GPIO inputs
        gpio_out : std_logic_vector(31 DOWNTO 0); --! Expected GPIO outputs
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name     => "Reset                         ",
            rst      => '1',
            data_wr  => X"00000000",
            data_rd  => X"00000000",
            gpio_in  => X"00000000",
            gpio_out => X"00000000"
        ),
        ( 
            name     => "Transfer                      ",
            rst      => '0',
            data_wr  => X"DEADBEEF",
            data_rd  => X"AA550011",
            gpio_in  => X"AA550011",
            gpio_out => X"DEADBEEF"
        )
    );
    
    -- Signals to uut
    SIGNAL clk         : std_logic;                     --! Clock input to uut
    SIGNAL rst         : std_logic;                     --! Reset input to uut
    SIGNAL dat_wr_done : std_logic;                     --! Data write done input to uut
    SIGNAL dat_wr_reg  : std_logic_vector(31 DOWNTO 0); --! Data write register input to uut
    SIGNAL dat_rd_reg  : std_logic_vector(31 DOWNTO 0); --! Data read register output from uut
    SIGNAL gpio_in     : std_logic_vector(31 DOWNTO 0); --! GPIO inputs
    SIGNAL gpio_out    : std_logic_vector(31 DOWNTO 0); --! GPIO outputs
    
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

    --! Instantiate GPIO device as uut
    i_uut : ENTITY work.gpio_device(rtl)
        PORT MAP (
            mod_clk_in     => clk,
            mod_rst_in     => rst,
            dat_wr_done_in => dat_wr_done,
            dat_wr_reg_in  => dat_wr_reg,
            dat_rd_reg_out => dat_rd_reg,
            gpio_bus_in    => gpio_in,
            gpio_bus_out   => gpio_out
        );

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
    
    --! @brief Stimulus process to drive PWM unit under test
    pr_stimulus : PROCESS IS
    BEGIN
        
        -- Initialize entity inputs
        rst         <= '1';
        dat_wr_reg  <= (OTHERS => '0');
        dat_wr_done <= '0';
        gpio_in     <= (OTHERS => '0');
        WAIT FOR c_clk_period;
        
        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
        
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;

            -- Perform write to device
            rst         <= c_stimulus(s).rst;
            dat_wr_reg  <= c_stimulus(s).data_wr;
            gpio_in     <= c_stimulus(s).gpio_in;
            dat_wr_done <= '1';
            WAIT FOR c_clk_period;
            dat_wr_done <= '0';
            
            -- Assert read from device
            ASSERT dat_rd_reg = c_stimulus(s).data_rd
                REPORT "Expected read of " &
                to_string(c_stimulus(s).data_rd) &
                " but got " &
                to_string(dat_rd_reg)
                SEVERITY error;

            -- Assert read from device
            ASSERT gpio_out = c_stimulus(s).gpio_out
                REPORT "Expected gpio_out of " &
                to_string(c_stimulus(s).gpio_out) &
                " but got " &
                to_string(gpio_out)
                SEVERITY error;
        END LOOP;

        -- Log end of test
        REPORT "Finished" SEVERITY note;

        -- Finish the simulation
        std.env.finish;
        
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;
