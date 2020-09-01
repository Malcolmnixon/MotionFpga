-------------------------------------------------------------------------------
--! @file
--! @brief Top testbench module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief Top testbench module
ENTITY top_tb IS
END ENTITY top_tb;

ARCHITECTURE tb OF top_tb IS

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name : string(1 TO 20);               --! Stimulus name
        rst  : std_logic;                     --! Reset input
        mosi : std_logic_vector(95 DOWNTO 0); --! Mosi data to top
        miso : std_logic_vector(95 DOWNTO 0); --! Expected miso data from top
    END RECORD t_stimulus;
    
    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;
    
    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name => "Reset               ",
            rst  => '1',
            mosi => (OTHERS => '0'),
            miso => (OTHERS => '0')
        ),
        (
            name => "Zero                ",
            rst  => '0',
            mosi => (OTHERS => '0'),
            miso => (OTHERS => '0')
        ),
        (
            name => "Activate            ",
            rst  => '0',
            mosi => X"C0000000" & X"FFAA5500" & X"0055AAFF",
            miso => X"00000000" & X"00000000" & X"00000000"
        ),
        (
            name => "Deactivate          ",
            rst  => '0',
            mosi => X"00000000" & X"00000000" & X"00000000",
            miso => X"C0000000" & X"FFAA5500" & X"0055AAFF"
        )
    );
        
    -- Signals for uut
    SIGNAL rst      : std_logic;                    --! Reset line
    SIGNAL spi_cs   : std_logic;                    --! SPI cs line
    SIGNAL spi_sclk : std_logic;                    --! SPI sclk line
    SIGNAL spi_mosi : std_logic;                    --! SPI mosi line
    SIGNAL spi_miso : std_logic;                    --! SPI miso line
    SIGNAL led      : std_logic_vector(7 DOWNTO 0); --! LED outputs
    
    -- Signals for sim_spi_master
    SIGNAL spi_rst    : std_logic;                     --! Reset to sim_spi_master
    SIGNAL data_mosi  : std_logic_vector(95 DOWNTO 0); --! Input to top
    SIGNAL data_miso  : std_logic_Vector(95 DOWNTO 0); --! Output from top
    SIGNAL xfer_start : std_logic;                     --! Transfer start
    SIGNAL xfer_done  : std_logic;                     --! Transfer done
    
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

    --! Instantiate top as uut
    i_uut : ENTITY work.top(rtl)
        PORT MAP (
            rst_in        => rst,
            spi_cs_in     => spi_cs,
            spi_sclk_in   => spi_sclk,
            spi_mosi_in   => spi_mosi,
            spi_miso_out  => spi_miso,
            spi_ver_en_in => '0',
            led_out       => led
        );
        
    --! Instantiate sim_spi_master
    i_spi : ENTITY work.sim_spi_master(sim)
        GENERIC MAP (
            spi_width => 96
        )
        PORT MAP (
            mod_rst_in    => spi_rst,
            spi_cs_out    => spi_cs,
            spi_sclk_out  => spi_sclk,
            spi_mosi_out  => spi_mosi,
            spi_miso_in   => spi_miso,
            data_mosi_in  => data_mosi,
            data_miso_out => data_miso,
            xfer_start_in => xfer_start,
            xfer_done_out => xfer_done
        );
            
    --! @brief Stimulus process
    pr_stimulus : PROCESS IS
    BEGIN

        -- Initialize and reset entities
        rst        <= '1';
        spi_rst    <= '1';
        data_mosi  <= (OTHERS => '0');
        xfer_start <= '0';
        WAIT FOR 100 ns;
        
        -- Take SPI out of reset
        spi_rst <= '0';
        WAIT FOR 100 ns;
        
        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;
            
            -- Set inputs
            rst       <= c_stimulus(s).rst;
            data_mosi <= c_stimulus(s).mosi;

            -- Perform SPI transfer
            xfer_start <= '1';
            WAIT UNTIL xfer_done = '1';
            xfer_start <= '0';

            -- Assert count
            ASSERT data_miso = c_stimulus(s).miso
                REPORT "Expected miso = " & 
                to_string(c_stimulus(s).miso) &
                " but got " &
                to_string(data_miso)
                SEVERITY error;
            
            -- Wait for full cycle
            WAIT FOR 125 us;
            
        END LOOP;
    
        -- Log end of test
        REPORT "Finished" SEVERITY note;
        
        -- Finish the simulation
        std.env.finish;
    
    END PROCESS pr_stimulus;
            
END ARCHITECTURE tb;
