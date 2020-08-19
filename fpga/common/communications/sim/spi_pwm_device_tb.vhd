-------------------------------------------------------------------------------
--! @file
--! @brief SPI PWM device testbench module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief SPI PWM device testbench module
ENTITY spi_pwm_device_tb IS
END ENTITY spi_pwm_device_tb;

--! Architecture tb of spi_pwm_device_tb entity
ARCHITECTURE tb OF spi_pwm_device_tb IS

    --! Clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    --! Service period
    CONSTANT c_svc_period : time := 100 us;

    --! Module Version information
    CONSTANT c_ver_info : std_logic_vector(31 DOWNTO 0) := X"12345678";
    
    --! Type for percentage array
    TYPE t_percent_array IS ARRAY(0 TO 3) OF integer;

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name    : string(1 TO 30);               --! Stimulus name
        ver_en  : std_logic;                     --! Version enable line
        mosi    : std_logic_vector(31 DOWNTO 0); --! MOSI data
        miso    : std_logic_vector(31 DOWNTO 0); --! MISO data
        percent : t_percent_array;               --! Expected PWM percentages
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name    => "Read version                  ",
            ver_en  => '1',
            mosi    => X"00000000",
            miso    => X"12345678",
            percent => (0, 0, 0, 0)
        ),
        ( 
            name    => "Set 0, 0, 0, 0                ",
            ver_en  => '0',
            mosi    => X"00000000",
            miso    => X"00000000",
            percent => (0, 0, 0, 0)
        ),
        ( 
            name    => "Set 255, 255, 255, 255        ",
            ver_en  => '0',
            mosi    => X"FFFFFFFF",
            miso    => X"00000000",
            percent => (100, 100, 100, 100)
        ),
        ( 
            name    => "Set 127, 127, 127, 127        ",
            ver_en  => '0',
            mosi    => X"7F7F7F7F",
            miso    => X"FFFFFFFF",
            percent => (50, 50, 50, 50)
        ),
        ( 
            name    => "Set 0, 85, 170, 255           ",
            ver_en  => '0',
            mosi    => X"FFAA5500",
            miso    => X"7F7F7F7F",
            percent => (0, 33, 67, 100)
        ),
        ( 
            name    => "Set 0, 0, 0, 0                ",
            ver_en  => '0',
            mosi    => X"00000000",
            miso    => X"FFAA5500",
            percent => (0, 0, 0, 0)
        ),
        ( 
            name    => "Set 0, 0, 0, 0                ",
            ver_en  => '0',
            mosi    => X"00000000",
            miso    => X"00000000",
            percent => (0, 0, 0, 0)
        )
    );

    -- Signals to uut
    SIGNAL clk        : std_logic;                    --! Clock
    SIGNAL rst        : std_logic;                    --! Reset
    SIGNAL spi_cs     : std_logic;                    --! SPI chip select input to uut
    SIGNAL spi_sclk   : std_logic;                    --! SPI clock input to uut
    SIGNAL spi_mosi   : std_logic;                    --! SPI MOSI input to uut
    SIGNAL spi_miso   : std_logic;                    --! SPI MISO output from uut
    SIGNAL spi_ver_en : std_logic;                    --! SPI Version Enable input to uut
    SIGNAL pwm_out    : std_logic_vector(3 DOWNTO 0); --! PWM outputs

    -- Signals to spi_master
    SIGNAL spi_data_mosi  : std_logic_vector(31 DOWNTO 0); --! SPI data to send
    SIGNAL spi_data_miso  : std_logic_vector(31 DOWNTO 0); --! SPI data received
    SIGNAL spi_xfer_start : std_logic;                     --! SPI transfer start
    SIGNAL spi_xfer_done  : std_logic;                     --! SPI transfer done
    
    -- Signals to on_percent
    SIGNAL pwm_rst        : std_logic;       --! Reset PWM percent
    SIGNAL pwm_on_percent : t_percent_array; --! Percent on

    --! Function to create string from std_logic_vector
    FUNCTION to_string (
        vector : std_logic_vector) RETURN string 
    IS
    
        VARIABLE v_str : string(1 TO vector'length);
        
    BEGIN
    
        FOR i IN vector'range LOOP
            v_str(i + 1) := std_logic'image(vector(i))(1);
        END LOOP;
        
        RETURN v_str;
        
    END FUNCTION to_string;
    
BEGIN

    --! Instantiate spi_pwm_device as unit under test
    i_uut : ENTITY work.spi_pwm_device(rtl)
        GENERIC MAP (
            ver_info => c_ver_info
        )
        PORT MAP (
            mod_clk_in      => clk,
            mod_rst_in      => rst,
            spi_cs_in       => spi_cs,
            spi_sclk_in     => spi_sclk,
            spi_mosi_in     => spi_mosi,
            spi_miso_out    => spi_miso,
            spi_ver_en_in   => spi_ver_en,
            pwm_adv_in      => '1',
            pwm_out         => pwm_out
        );
        
    --! Instantiate sim_spi_master to drive spi_pwm_device
    i_spi_master : ENTITY work.sim_spi_master(sim)
        PORT MAP (
            mod_rst_in    => rst,
            spi_cs_out    => spi_cs,
            spi_sclk_out  => spi_sclk,
            spi_mosi_out  => spi_mosi,
            spi_miso_in   => spi_miso,
            data_mosi_in  => spi_data_mosi,
            data_miso_out => spi_data_miso,
            xfer_start_in => spi_xfer_start,
            xfer_done_out => spi_xfer_done
        );
    
    --! Generate PWM percent measuring entities
    g_on_percent : FOR i IN 0 TO 3 GENERATE
        
        --! Instantiate sim_on_percent for pwm output
        i_on_percent : ENTITY work.sim_on_percent(sim)
            PORT MAP (
                mod_clk_in  => clk,
                mod_rst_in  => pwm_rst,
                signal_in   => pwm_out(i),
                percent_out => pwm_on_percent(i)
            );
    
    END GENERATE g_on_percent;

    --! @brief Clock generation process
    pr_clock : PROCESS IS
    BEGIN
    
        -- Low for 1/2 clock
        clk <= '0';
        WAIT FOR c_clk_period / 2;
        
        -- High for 1/2 clock
        clk <= '1';
        WAIT FOR c_clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process to drive PWM unit under test
    pr_stimulus : PROCESS IS
    BEGIN
        
        -- Reset entities
        rst     <= '1';
        pwm_rst <= '1';
        WAIT FOR c_clk_period;
        
        -- Take out of reset
        rst <= '0';
        WAIT FOR c_clk_period;

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;
            
            -- Set inputs
            spi_ver_en    <= c_stimulus(s).ver_en;
            spi_data_mosi <= c_stimulus(s).mosi;
            
            -- Trigger SPI transfer
            spi_xfer_start <= '1';
            WAIT UNTIL spi_xfer_done = '1';
            spi_xfer_start <= '0';
            
            -- Assert outputs
            ASSERT spi_data_miso = c_stimulus(s).miso
                REPORT "Expected miso of " & 
                to_string(c_stimulus(s).miso) & 
                " but got " &
                to_string(spi_data_miso)
                SEVERITY error;           
            
            -- Enable PWM counting
            pwm_rst <= '0';
            
            -- Wait for full service period
            WAIT FOR c_svc_period;
            
            -- Inspect PWM outputs
            FOR i IN 0 TO 3 LOOP   

                -- Assert PWM is within 5%
                ASSERT pwm_on_percent(i) >= c_stimulus(s).percent(i) - 5 AND 
                    pwm_on_percent(i) <= c_stimulus(s).percent(i)
                    REPORT "Expected pwm of " &
                    integer'image(c_stimulus(s).percent(i)) &
                    " but got " &
                    integer'image(pwm_on_percent(i))
                    SEVERITY error;

            END LOOP;
            
            -- Stop PWM counting
            pwm_rst <= '1';
            
        END LOOP;
        
        -- Log end of test
        REPORT "Finished" SEVERITY note;
        
        -- Finish the simulation
        std.env.finish;
        
    END PROCESS pr_stimulus;
        
END ARCHITECTURE tb;

