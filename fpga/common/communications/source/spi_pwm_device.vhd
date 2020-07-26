-------------------------------------------------------------------------------
--! @file
--! @brief SPI PWM device
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief SPI PWM device entity
--!
--! @image html spi_pwm_device_entity.png "SPI PWM Device Entity"
--!
--! This entity exposes a PWM device over SPI. The SPI data clocked in is
--! four new 8-bit PWM duty-cycles, and the SPI data clocked out is the 
--! current four 8-bit PWM duty-cycles.
ENTITY spi_pwm_device IS
    PORT (
        mod_clk_in   : IN    std_logic;                   --! Module Clock
        mod_rst_in   : IN    std_logic;                   --! Module Reset (async)
        pwm_adv_in   : IN    std_logic;                   --! PWM Advance flag
        spi_cs_in    : IN    std_logic;                   --! SPI Chip-select
        spi_sclk_in  : IN    std_logic;                   --! SPI Clock
        spi_mosi_in  : IN    std_logic;                   --! SPI MOSI
        spi_miso_out : OUT   std_logic;                   --! SPI MISO
        pwm_out      : OUT   std_logic_vector(3 DOWNTO 0) --! PWM outputs
    );
END ENTITY spi_pwm_device;

--! Architecture rtl of spi_pwm_device entity
ARCHITECTURE rtl OF spi_pwm_device IS

    SIGNAL dat_rd_reg  : std_logic_vector(31 DOWNTO 0); --! Data Read Register value
    SIGNAL dat_rd_strt : std_logic;                     --! Data Read Start flag
    SIGNAL dat_wr_reg  : std_logic_vector(31 DOWNTO 0); --! Data Write Register value 
    SIGNAL dat_wr_done : std_logic;                     --! Data Write Done flag
    
BEGIN

    --! Instantiate SPI block
    i_spi_block : ENTITY work.spi_block(rtl)
        PORT MAP (
            mod_clk_in      => mod_clk_in,
            mod_rst_in      => mod_rst_in,
            spi_cs_in       => spi_cs_in,
            spi_sclk_in     => spi_sclk_in,
            spi_mosi_in     => spi_mosi_in,
            spi_miso_out    => spi_miso_out,
            dat_rd_reg_in   => dat_rd_reg,
            dat_rd_strt_out => dat_rd_strt,
            dat_wr_reg_out  => dat_wr_reg,
            dat_wr_done_out => dat_wr_done
        );
        
    --! Instantiate PWM device
    i_pwm_device : ENTITY work.pwm_device(rtl)
        PORT MAP (
            mod_clk_in     => mod_clk_in,
            mod_rst_in     => mod_rst_in,
            pwm_adv_in     => pwm_adv_in,
            dat_wr_done_in => dat_wr_done,
            dat_wr_reg_in  => dat_wr_reg,
            dat_rd_strt_in => dat_rd_strt,
            dat_rd_reg_out => dat_rd_reg,
            pwm_out        => pwm_out
        );
    
END ARCHITECTURE rtl;
