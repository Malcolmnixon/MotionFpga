-------------------------------------------------------------------------------
--! @file
--! @brief SPI Version Block module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief SPI Version Block module
--!
--! The spi_version_block entity is similar to the spi_block entity, but it
--! handles providing version information over the SPI bus. When the ver_en_in
--! signal is asserted, all reads provide the version and all writes are
--! ignored.
ENTITY spi_version_block IS
    GENERIC (
        ver_info : std_logic_vector(31 DOWNTO 0) --! Version information
    );
    PORT (
        mod_clk_in      : IN    std_logic;                     --! Module Clock
        mod_rst_in      : IN    std_logic;                     --! Module Reset (async)
        spi_cs_in       : IN    std_logic;                     --! SPI Chip-select
        spi_sclk_in     : IN    std_logic;                     --! SPI Clock
        spi_mosi_in     : IN    std_logic;                     --! SPI MOSI
        spi_miso_out    : OUT   std_logic;                     --! SPI MISO
        spi_ver_en_in   : IN    std_logic;                     --! SPI Version Enable flag
        dat_rd_reg_in   : IN    std_logic_vector(31 DOWNTO 0); --! Data Read Register value
        dat_rd_strt_out : OUT   std_logic;                     --! Data Read Start flag
        dat_wr_reg_out  : OUT   std_logic_vector(31 DOWNTO 0); --! Data Write Register value 
        dat_wr_done_out : OUT   std_logic                      --! Data Write Done flag
    );
END ENTITY spi_version_block;

--! Architecture rtl of spi_version_block entity
ARCHITECTURE rtl OF spi_version_block IS

    -- Internal data signals
    SIGNAL dat_rd_reg  : std_logic_vector(31 DOWNTO 0); --! Internal data read register
    SIGNAL dat_rd_strt : std_logic;                     --! Internal data read start
    SIGNAL dat_wr_done : std_logic;                     --! Internal data write done

BEGIN

    --! Instance of spi_block
    i_spi_block : ENTITY work.spi_block
        PORT MAP (
            mod_clk_in      => mod_clk_in,
            mod_rst_in      => mod_rst_in,
            spi_cs_in       => spi_cs_in,
            spi_sclk_in     => spi_sclk_in,
            spi_mosi_in     => spi_mosi_in,
            spi_miso_out    => spi_miso_out,
            dat_rd_reg_in   => dat_rd_reg,
            dat_rd_strt_out => dat_rd_strt,
            dat_wr_reg_out  => dat_wr_reg_out,
            dat_wr_done_out => dat_wr_done
        );

    -- Expose read and write when not performing version operations
    dat_rd_strt_out <= dat_rd_strt AND NOT spi_ver_en_in;
    dat_wr_done_out <= dat_wr_done AND NOT spi_ver_en_in;

    -- Data read is either version information, or modules read dat
    dat_rd_reg <= ver_info WHEN spi_ver_en_in = '1' ELSE 
                  dat_rd_reg_in;

END ARCHITECTURE rtl;
