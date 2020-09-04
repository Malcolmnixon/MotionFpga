-------------------------------------------------------------------------------
--! @file
--! @brief MotionFpga top-level module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using MachX03D library
LIBRARY machxo3d;

--! Using MachX03D library components (for oscj)
USE machxo3d.ALL;

--! @brief MotionFpga top-level entity
ENTITY top IS
    GENERIC (
        version : std_logic_vector(31 DOWNTO 0) := X"00000000" --! Version number
    );
    PORT (
        rst_in        : IN    std_logic;                   --! FPGA reset input line
        spi_cs_in     : IN    std_logic;                   --! SPI chip-select input line
        spi_sclk_in   : IN    std_logic;                   --! SPI clock input line
        spi_mosi_in   : IN    std_logic;                   --! SPI MOSI input line
        spi_miso_out  : OUT   std_logic;                   --! SPI MISO output line
        spi_ver_en_in : IN    std_logic;                   --! SPI Version Enable input line
        led_out       : OUT   std_logic_vector(7 DOWNTO 0) --! LED outputs
    );
END ENTITY top;

--! Architecture rtl of top entity
ARCHITECTURE rtl OF top IS

    SIGNAL osc           : std_logic; --! Internal oscillator (11.08MHz)
    SIGNAL lock          : std_logic; --! PLL Lock
    SIGNAL clk           : std_logic; --! Main clock (99.72MHz)
    SIGNAL rst_ms        : std_logic; --! Reset (possibly metastable)
    SIGNAL rst           : std_logic; --! Reset
    SIGNAL spi_cs_ms     : std_logic; --! SPI chip-select input (metastable)
    SIGNAL spi_sclk_ms   : std_logic; --! SPI clock input (metastable)
    SIGNAL spi_mosi_ms   : std_logic; --! SPI MOSI input (metastable)
    SIGNAL spi_ver_en_ms : std_logic; --! SPI Version Enable (metastable)
    SIGNAL spi_cs_s      : std_logic; --! SPI chip-select input (stable)
    SIGNAL spi_sclk_s    : std_logic; --! SPI clock input (stable)
    SIGNAL spi_mosi_s    : std_logic; --! SPI MOSI input (stable)
    SIGNAL spi_ver_en_s  : std_logic; --! SPI Version Enable input (stable)
    SIGNAL pwm_adv       : std_logic; --! PWM advance signal
    
    -- SPI slave output signals
    SIGNAL spi_miso_out_device  : std_logic; --! SPI MISO output for devices
    SIGNAL spi_miso_out_version : std_logic; --! SPI MISO output for version

    -- SPI slave signals
    SIGNAL dat_rd_reg  : std_logic_vector(95 DOWNTO 0); --! SPI read data (response)
    SIGNAL dat_wr_reg  : std_logic_vector(95 DOWNTO 0); --! SPI write data (command)
    SIGNAL dat_wr_done : std_logic;                     --! SPI write done pulse

    -- PWM lines
    SIGNAL pwm_lines : std_logic_vector(3 DOWNTO 0); --! PWM outputs

    -- SDM lines
    SIGNAL sdm_lines : std_logic_vector(3 DOWNTO 0); --! SDM outputs

    -- GPIO lines
    SIGNAL gpio_in_lines  : std_logic_vector(31 DOWNTO 0); --! GPIO inputs
    SIGNAL gpio_out_lines : std_logic_vector(31 DOWNTO 0); --! GPIO outputs

    --! Component declaration for the MachX02 internal oscillator
    COMPONENT oscj IS
        GENERIC (
            nom_freq : string := "11.08"
        );
        PORT (
            stdby    : IN    std_logic;
            osc      : OUT   std_logic;
            sedstdby : OUT   std_logic;
            oscesb   : OUT   std_logic
        );
    END COMPONENT oscj;

    --! Component delcaration for the PLL
    COMPONENT pll IS
        PORT (
            clki  : IN    std_logic;
            clkop : OUT   std_logic;
            lock  : OUT   std_logic
        );
    END COMPONENT pll;

BEGIN

    --! Instantiate the internal oscillator for 11.08MHz
    i_oscj : oscj
        GENERIC MAP (
            nom_freq => "11.08"
        )
        PORT MAP (
            stdby    => '0',
            osc      => osc,
            sedstdby => OPEN,
            oscesb   => OPEN
        );

    --! Instantiate the PLL (11.08MHz -> 99.72MHz)
    i_pll : pll
        PORT MAP (
            clki  => osc,
            clkop => clk,
            lock  => lock
        );

    --! Instantiate the clock divider for PWM advance
    i_pwm_clk : ENTITY work.clk_div_n
        GENERIC MAP (
            clk_div => 4
        )
        PORT MAP (
            mod_clk_in  => clk,
            mod_rst_in  => rst,
            clk_adv_in  => '1',
            clk_end_out => OPEN,
            clk_pls_out => pwm_adv
        );

    --! Instantiate SPI slave device bus
    i_spi_slave_device : ENTITY work.spi_slave
        GENERIC MAP (
            size => 96
        )
        PORT MAP (
            mod_clk_in      => clk,
            mod_rst_in      => rst,
            spi_cs_in       => spi_cs_s,
            spi_sclk_in     => spi_sclk_s,
            spi_mosi_in     => spi_mosi_s,
            spi_miso_out    => spi_miso_out_device,
            dat_rd_reg_in   => dat_rd_reg,
            dat_wr_reg_out  => dat_wr_reg,
            dat_wr_done_out => dat_wr_done
        );
    
    --! Instantiate SPI slave version bus
    i_spi_slave_version : ENTITY work.spi_slave
        GENERIC MAP (
            size => 32
        )
        PORT MAP (
            mod_clk_in      => clk,
            mod_rst_in      => rst,
            spi_cs_in       => spi_cs_s,
            spi_sclk_in     => spi_sclk_s,
            spi_mosi_in     => '0',
            spi_miso_out    => spi_miso_out_version,
            dat_rd_reg_in   => version,
            dat_wr_reg_out  => OPEN,
            dat_wr_done_out => OPEN
        );
        
    --! Instantiate the PWM device
    i_pwm_device : ENTITY work.pwm_device
        PORT MAP (
            mod_clk_in     => clk,
            mod_rst_in     => rst,
            dat_wr_done_in => dat_wr_done,
            dat_wr_reg_in  => dat_wr_reg(31 DOWNTO 0),
            dat_rd_reg_out => dat_rd_reg(31 DOWNTO 0),
            pwm_adv_in     => pwm_adv,
            pwm_out        => pwm_lines
        );

    --! Instantiate the PWM device
    i_sdm_device : ENTITY work.sdm_device
        PORT MAP (
            mod_clk_in     => clk,
            mod_rst_in     => rst,
            dat_wr_done_in => dat_wr_done,
            dat_wr_reg_in  => dat_wr_reg(63 DOWNTO 32),
            dat_rd_reg_out => dat_rd_reg(63 DOWNTO 32),
            sdm_out        => sdm_lines
        );

    --! Instantiate the GPIO device
    i_gpio_device : ENTITY work.gpio_device
        PORT MAP (
            mod_clk_in     => clk,
            mod_rst_in     => rst,
            dat_wr_done_in => dat_wr_done,
            dat_wr_reg_in  => dat_wr_reg(95 DOWNTO 64),
            dat_rd_reg_out => dat_rd_reg(95 DOWNTO 64),
            gpio_bus_in    => gpio_in_lines,
            gpio_bus_out   => gpio_out_lines
        );

    --! @brief Reset process
    --!
    --! This process provides a synchronous reset signal where possible. Before
    --! the PLL has locked, it asserts reset; and after the PLL has locked it
    --! uses the resynchronized reset input pin.
    pr_reset : PROCESS (clk, lock) IS
    BEGIN

        IF (lock = '0') THEN
            rst_ms <= '1';
            rst    <= '1';
        ELSIF (rising_edge(clk)) THEN
            rst_ms <= rst_in;
            rst    <= rst_ms;
        END IF;

    END PROCESS pr_reset;

    --! @brief SPI input double-flop resynchronizer
    --!
    --! This process double-flops the SPI inputs to resolve metastability and
    --! ensure the signals are stable for SPI processing
    pr_spi_input : PROCESS (rst, clk) IS
    BEGIN

        IF (rst = '1') THEN
            spi_cs_ms     <= '0';
            spi_sclk_ms   <= '0';
            spi_mosi_ms   <= '0';
            spi_ver_en_ms <= '0';
            spi_cs_s      <= '0';
            spi_sclk_s    <= '0';
            spi_mosi_s    <= '0';
            spi_ver_en_s  <= '0';
        ELSIF (rising_edge(clk)) THEN
            spi_cs_ms     <= spi_cs_in;
            spi_sclk_ms   <= spi_sclk_in;
            spi_mosi_ms   <= spi_mosi_in;
            spi_ver_en_ms <= spi_ver_en_in;
            spi_cs_s      <= spi_cs_ms;
            spi_sclk_s    <= spi_sclk_ms;
            spi_mosi_s    <= spi_mosi_ms;
            spi_ver_en_s  <= spi_ver_en_ms;
        END IF;

    END PROCESS pr_spi_input;
    
    -- Output the version (if enabled) or the device
    spi_miso_out <= spi_miso_out_version WHEN spi_ver_en_s = '1' ELSE spi_miso_out_device;

    led_out(7) <= pwm_lines(0);
    led_out(6) <= pwm_lines(1);
    led_out(5) <= sdm_lines(0);
    led_out(4) <= sdm_lines(1);
    led_out(3) <= gpio_out_lines(3);
    led_out(2) <= gpio_out_lines(2);
    led_out(1) <= gpio_out_lines(1);
    led_out(0) <= gpio_out_lines(0);

    gpio_in_lines(31)          <= gpio_out_lines(31);
    gpio_in_lines(30)          <= gpio_out_lines(30);
    gpio_in_lines(29 DOWNTO 0) <= (OTHERS => '0');

END ARCHITECTURE rtl;
