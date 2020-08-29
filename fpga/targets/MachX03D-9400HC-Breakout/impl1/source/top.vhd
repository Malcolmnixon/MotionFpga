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

    --! Version information for this FPGA
    CONSTANT ver_info : std_logic_vector(31 DOWNTO 0) := X"00000000";

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

    -- PWM lines
    SIGNAL pwm_lines : std_logic_vector(3 DOWNTO 0); --! PWM outputs

    -- SDM lines
    SIGNAL sdm_lines : std_logic_vector(3 DOWNTO 0); --! SDM outputs

    -- GPIO lines
    SIGNAL gpio_in_lines  : std_logic_vector(31 DOWNTO 0); --! GPIO inputs
    SIGNAL gpio_out_lines : std_logic_vector(31 DOWNTO 0); --! GPIO outputs

    -- Block links (miso/mosi)
    SIGNAL block_link_01 : std_logic; --! Link from block 0 to 1
    SIGNAL block_link_12 : std_logic; --! Link from block 1 to 2

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
    i_pwm_clk : ENTITY work.clk_div_n(rtl)
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

    --! Instantiate the PWM device
    i_spi_pwm_device : ENTITY work.spi_pwm_device(rtl)
        GENERIC MAP (
            ver_info => ver_info
        )
        PORT MAP (
            mod_clk_in    => clk,
            mod_rst_in    => rst,
            spi_cs_in     => spi_cs_s,
            spi_sclk_in   => spi_sclk_s,
            spi_mosi_in   => spi_mosi_s,
            spi_miso_out  => block_link_01,
            spi_ver_en_in => spi_ver_en_s,
            pwm_adv_in    => pwm_adv,
            pwm_out       => pwm_lines
        );

    --! Instantiate the PWM device
    i_spi_sdm_device : ENTITY work.spi_sdm_device(rtl)
        GENERIC MAP (
            ver_info => ver_info
        )
        PORT MAP (
            mod_clk_in    => clk,
            mod_rst_in    => rst,
            spi_cs_in     => spi_cs_s,
            spi_sclk_in   => spi_sclk_s,
            spi_mosi_in   => block_link_01,
            spi_miso_out  => block_link_12,
            spi_ver_en_in => spi_ver_en_s,
            sdm_out       => sdm_lines
        );

    --! Instantiate the GPIO device
    i_spi_gpio_device : ENTITY work.spi_gpio_device(rtl)
        GENERIC MAP (
            ver_info => ver_info
        )
        PORT MAP (
            mod_clk_in    => clk,
            mod_rst_in    => rst,
            spi_cs_in     => spi_cs_s,
            spi_sclk_in   => spi_sclk_s,
            spi_mosi_in   => block_link_12,
            spi_miso_out  => spi_miso_out,
            spi_ver_en_in => spi_ver_en_s,
            gpio_bus_in   => gpio_in_lines,
            gpio_bus_out  => gpio_out_lines
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
    pr_spi_input : PROCESS (clk) IS
    BEGIN

        IF (rising_edge(clk)) THEN
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
