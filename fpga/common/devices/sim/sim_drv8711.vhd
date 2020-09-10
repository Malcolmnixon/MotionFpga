-------------------------------------------------------------------------------
--! @file
--! @brief Simulated drv8711
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Simulated drv8711 entity
ENTITY sim_drv8711 IS
    PORT (
        mod_rst_in   : IN    std_logic;                     --! Asynchronous reset
        spi_scs_in   : IN    std_logic;                     --! SPI scs line
        spi_sclk_in  : IN    std_logic;                     --! SPI sclk line
        spi_mosi_in  : IN    std_logic;                     --! SPI mosi line
        spi_miso_out : OUT   std_logic;                     --! SPI miso line
        dat_miso_in  : IN    std_logic_vector(15 DOWNTO 0); --! SPI data to send
        dat_mosi_out : OUT   std_logic_vector(15 DOWNTO 0); --! SPI data received
        step_in      : IN    std_logic;                     --! Step input
        dir_in       : IN    std_logic;                     --! Direction input
        steps_out    : OUT   integer                        --! Steps count
    );
END ENTITY sim_drv8711;

--! Architectur sim of entity sim_drv8711
ARCHITECTURE sim OF sim_drv8711 IS

BEGIN

    --! Create instance of simulated drv8711 spi
    i_drv8711_spi : ENTITY work.sim_drv8711_spi
        PORT MAP (
            mod_rst_in => mod_rst_in,
            spi_scs_in => spi_scs_in,
            spi_sclk_in => spi_sclk_in,
            spi_mosi_in => spi_mosi_in,
            spi_miso_out => spi_miso_out,
            dat_miso_in => dat_miso_in,
            dat_mosi_out => dat_mosi_out
        );

    --! Create instance of step counter
    i_step_counter : ENTITY work.sim_step_counter
        PORT MAP (
            mod_rst_in => mod_rst_in,
            step_in    => step_in,
            dir_in     => dir_in,
            size_in    => 1,
            steps_out  => steps_out
        );
    
END ARCHITECTURE sim;
