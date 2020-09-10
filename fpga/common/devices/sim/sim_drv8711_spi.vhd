-------------------------------------------------------------------------------
--! @file
--! @brief Simulated drv8711 SPI device
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Simulated drv8711 entity
ENTITY sim_drv8711_spi IS
    PORT (
        mod_rst_in   : IN    std_logic;                     --! Asynchronous reset
        spi_scs_in   : IN    std_logic;                     --! SPI scs line
        spi_sclk_in  : IN    std_logic;                     --! SPI sclk line
        spi_mosi_in  : IN    std_logic;                     --! SPI mosi line
        spi_miso_out : OUT   std_logic;                     --! SPI miso line
        dat_miso_in  : IN    std_logic_vector(15 DOWNTO 0); --! SPI data to send
        dat_mosi_out : OUT   std_logic_vector(15 DOWNTO 0)  --! SPI data received
    );
END ENTITY sim_drv8711_spi;

--! Architectur sim of entity sim_drv8711_spi
ARCHITECTURE sim OF sim_drv8711_spi IS

    SIGNAL dat_miso : std_logic_vector(15 DOWNTO 0);
    SIGNAL dat_mosi : std_logic_vector(15 DOWNTO 0);
    
BEGIN

    --! @brief Process to handle SPI traffic
    pr_spi : PROCESS (mod_rst_in, spi_scs_in, spi_sclk_in) IS
    BEGIN
    
        IF (mod_rst_in = '1') THEN
            -- Reset
            dat_miso <= (OTHERS => '0');
            dat_mosi <= (OTHERS => '0');
        ELSIF (rising_edge(spi_scs_in)) THEN
            -- Populate shift registers
            dat_miso <= dat_miso_in;
            dat_mosi <= (OTHERS => '0');
        ELSIF (rising_edge(spi_sclk_in)) THEN
            -- Capture incoming data on rising edge
            dat_mosi <= dat_mosi(14 DOWNTO 0) & spi_mosi_in;
        ELSIF (falling_edge(spi_sclk_in)) THEN
            -- Shift outgoing data on falling edge
            dat_miso <= dat_miso(14 DOWNTO 0) & '0';
        END IF;
            
    END PROCESS pr_spi;
    
    spi_miso_out <= dat_miso(15) WHEN spi_scs_in = '1' ELSE
                    '0';
    
    dat_mosi_out <= dat_mosi;
    
END ARCHITECTURE sim;
