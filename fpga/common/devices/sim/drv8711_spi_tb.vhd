-------------------------------------------------------------------------------
--! @file
--! @brief DRV8711 SPI test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief DRV8711 SPI test bench
ENTITY drv8711_spi_tb IS
END ENTITY drv8711_spi_tb;

--! Architecture tb of drv8711_spi_tb entity
ARCHITECTURE tb OF drv8711_spi_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name     : string(1 TO 30);               --! Stimulus name
        data_wr  : std_logic_vector(15 DOWNTO 0); --! Write data to gpio_device
        data_rd  : std_logic_vector(15 DOWNTO 0); --! Expected read data from gpio_device
    END RECORD t_stimulus;

    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;

    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name     => "Transfer                      ",
            data_wr  => X"A501",
            data_rd  => X"0000"
        ),
        ( 
            name     => "Transfer                      ",
            data_wr  => X"AAAA",
            data_rd  => X"0000"
        ),
        ( 
            name     => "Transfer                      ",
            data_wr  => X"5555",
            data_rd  => X"0000"
        )
    );
    
    -- Signals to uut
    SIGNAL clk        : std_logic;                     --! Clock input to uut
    SIGNAL rst        : std_logic;                     --! Reset input to uut
    SIGNAL data_send  : std_logic_vector(15 DOWNTO 0); --! Data to send
    SIGNAL data_recv  : std_logic_vector(15 DOWNTO 0); --! Data received
    SIGNAL xfer_adv   : std_logic;                     --! Transfer advance pulse
    SIGNAL xfer_start : std_logic;                     --! Transfer start flag
    SIGNAL xfer_done  : std_logic;                     --! Transfer done pulse
    SIGNAL spi_scs    : std_logic;                     --! SPI chip-select line
    SIGNAL spi_sclk   : std_logic;                     --! SPI clock line
    SIGNAL spi_mosi   : std_logic;                     --! SPI mosi line
    SIGNAL spi_miso   : std_logic;                     --! SPI miso line

    -- Signals to transfer clock
    SIGNAL xfer_clk_rst : std_logic; --! Reset transfer clock
    
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

    --! Instantiate DRV8711 SPI as uut
    i_uut : ENTITY work.drv8711_spi
        PORT MAP (
            clk_in        => clk,
            rst_in        => rst,
            data_send_in  => data_send,
            data_recv_out => data_recv,
            xfer_adv_in   => xfer_adv,
            xfer_start_in => xfer_start,
            xfer_done_out => xfer_done,
            spi_scs_out   => spi_scs,
            spi_sclk_out  => spi_sclk,
            spi_mosi_out  => spi_mosi,
            spi_miso_in   => spi_miso
        );

    --! Instantiate clk_div_n for transfer clock
    i_xfer_clk : ENTITY work.clk_div_n
        GENERIC MAP (
            clk_div => 14
        )
        PORT MAP (
            clk_in      => clk,
            rst_in      => xfer_clk_rst,
            div_clr_in  => '0',
            div_adv_in  => '1',
            div_end_out => OPEN,
            div_pls_out => xfer_adv
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
        rst        <= '1';
        data_send  <= (OTHERS => '0');
        xfer_start <= '0';
        spi_miso   <= '0';
        WAIT FOR c_clk_period;			  
        
        rst <= '0';
        WAIT FOR c_clk_period;			  
        
        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
        
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;

            -- Perform write to device
            data_send <= c_stimulus(s).data_wr;
            
            -- Pulse transfer-start
            xfer_start <= '1';
            WAIT FOR c_clk_period * 32;
            xfer_start <= '0';
            
            WAIT UNTIL xfer_done = '1';
            WAIT FOR c_clk_period;
            
            -- Wait for transfer
            WAIT FOR c_clk_period * 100;
        END LOOP;

        -- Log end of test
        REPORT "Finished" SEVERITY note;

        -- Finish the simulation
        std.env.finish;
        
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;
