-------------------------------------------------------------------------------
--! @file
--! @brief SPI GPIO device
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief SPI GPIO device entity
--!
--! This entity exposes a GPIO device over SPI. The SPI data clocked in is
--! 32 new GPIO outputs, and the SPI data clocked out is the current 32 GPIO 
--! inputs.
ENTITY spi_gpio_device IS
    GENERIC (
        ver_info : std_logic_vector(31 DOWNTO 0) := X"00000000" --! Version information
    );
    PORT (
        mod_clk_in    : IN    std_logic;                     --! Module Clock
        mod_rst_in    : IN    std_logic;                     --! Module Reset (async)
        spi_cs_in     : IN    std_logic;                     --! SPI Chip-select
        spi_sclk_in   : IN    std_logic;                     --! SPI Clock
        spi_mosi_in   : IN    std_logic;                     --! SPI MOSI
        spi_miso_out  : OUT   std_logic;                     --! SPI MISO
        spi_ver_en_in : IN    std_logic;                     --! SPI Version Enable
        gpio_bus_in   : IN    std_logic_vector(31 DOWNTO 0); --! GPIO inputs
        gpio_bus_out  : OUT   std_logic_vector(31 DOWNTO 0)  --! GPIO outputs
    );
END ENTITY spi_gpio_device;

--! Architecture rtl of spi_gpio_device entity
ARCHITECTURE rtl OF spi_gpio_device IS

    SIGNAL dat_rd_reg  : std_logic_vector(31 DOWNTO 0); --! Data Read Register value
    SIGNAL dat_wr_reg  : std_logic_vector(31 DOWNTO 0); --! Data Write Register value 
    SIGNAL dat_wr_done : std_logic;                     --! Data Write Done flag
    
BEGIN

    --! Instantiate SPI version block
    i_spi_version_block : ENTITY work.spi_version_block(rtl)
        GENERIC MAP (
            ver_info => ver_info
        )
        PORT MAP (
            mod_clk_in      => mod_clk_in,
            mod_rst_in      => mod_rst_in,
            spi_cs_in       => spi_cs_in,
            spi_sclk_in     => spi_sclk_in,
            spi_mosi_in     => spi_mosi_in,
            spi_miso_out    => spi_miso_out,
            spi_ver_en_in   => spi_ver_en_in,
            dat_rd_reg_in   => dat_rd_reg,
            dat_wr_reg_out  => dat_wr_reg,
            dat_wr_done_out => dat_wr_done
        );
        
    --! Instantiate GPIO device
    i_gpio_device : ENTITY work.gpio_device(rtl)
        PORT MAP (
            mod_clk_in     => mod_clk_in,
            mod_rst_in     => mod_rst_in,
            dat_wr_done_in => dat_wr_done,
            dat_wr_reg_in  => dat_wr_reg,
            dat_rd_reg_out => dat_rd_reg,
            gpio_bus_in    => gpio_bus_in,
            gpio_bus_out   => gpio_bus_out
        );
    
END ARCHITECTURE rtl;
