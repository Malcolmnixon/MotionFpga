-------------------------------------------------------------------------------
--! @file
--! @brief MotionFpga top-level module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief MotionFpga top-level entity
ENTITY top IS
    PORT (
        rst_in       : IN    std_logic;                   --! FPGA reset input line
        ready_out    : OUT   std_logic;                   --! FPGA ready status output line
        blink_out    : OUT   std_logic;                   --! FPGA health blink output line
        spi_cs_in    : IN    std_logic;                   --! SPI chip-select input line
        spi_sclk_in  : IN    std_logic;                   --! SPI clock input line
        spi_mosi_in  : IN    std_logic;                   --! SPI MOSI input line
        spi_miso_out : OUT   std_logic;                   --! SPI MISO output line
        pwm_out      : OUT   std_logic_vector(3 DOWNTO 0) --! PWM outputs
    );
END ENTITY top;

--! Architecture rtl of top entity
ARCHITECTURE rtl OF top IS

    SIGNAL osc         : std_logic; --! Internal oscillator (11.08MHz)
    SIGNAL lock        : std_logic; --! PLL Lock 
    SIGNAL clk         : std_logic; --! Main clock (99.72MHz)
    SIGNAL rst_ms      : std_logic; --! Reset (possibly metastable)
    SIGNAL rst         : std_logic; --! Reset
    SIGNAL spi_cs_ms   : std_logic; --! SPI chip-select input (metastable)
    SIGNAL spi_sclk_ms : std_logic; --! SPI clock input (metastable)
    SIGNAL spi_mosi_ms : std_logic; --! SPI MOSI input (metastable)
    SIGNAL spi_cs_s    : std_logic; --! SPI chip-select input (stable)
    SIGNAL spi_sclk_s  : std_logic; --! SPI clock input (stable)
    SIGNAL spi_mosi_s  : std_logic; --! SPI MOSI input (stable)
    SIGNAL pwm_adv     : std_logic; --! PWM advance signal

    --! Component declaration for the MachX02 internal oscillator
    COMPONENT osch IS
        GENERIC (
            nom_freq : string := "11.08"
        );
        PORT ( 
            stdby    : IN    std_logic;
            osc      : OUT   std_logic;
            sedstdby : OUT   std_logic
        );
    END COMPONENT osch;

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
    i_osch : osch
        GENERIC MAP (
            nom_freq => "11.08"
        )
        PORT MAP (
            stdby    => '0',
            osc      => osc,
            sedstdby => OPEN
        );

    --! Instantiate the PLL (9.85MHz -> 98.5MHz)
    i_pll : pll
        PORT MAP (
            clki  => osc,
            clkop => clk,
            lock  => lock
        );

    --! Instantiate the blink at 10Hz
    i_blink : ENTITY work.blink(rtl)
        GENERIC MAP (
            max_count => 5_000_000 - 1
        )
        PORT MAP (
            clk_in  => clk,
            rst_in  => rst,
            led_out => blink_out
        );
    
    --! Instantiate the clock divider for PWM advance    
    i_pwm_clk : ENTITY work.clk_div_n(rtl)
        GENERIC MAP (
            divide => 4
        )
        PORT MAP (
            mod_clk_in => clk,
            mod_rst_in => rst,
            cnt_en_in  => '1',
            cnt_out    => pwm_adv
        );
        
    --! Instantiate the PWM device
    i_spi_pwm_device : ENTITY work.spi_pwm_device(rtl)
        PORT MAP (
            mod_clk_in   => clk,
            mod_rst_in   => rst,
            pwm_adv_in   => pwm_adv,
            spi_cs_in    => spi_cs_s,
            spi_sclk_in  => spi_sclk_s,
            spi_mosi_in  => spi_mosi_s,
            spi_miso_out => spi_miso_out,
            pwm_out      => pwm_out
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
            spi_cs_ms   <= spi_cs_in;
            spi_sclk_ms <= spi_sclk_in;
            spi_mosi_ms <= spi_mosi_in;
            spi_cs_s    <= spi_cs_ms;
            spi_sclk_s  <= spi_sclk_ms;
            spi_mosi_s  <= spi_mosi_ms;
        END IF;
        
    END PROCESS pr_spi_input;

    ready_out <= NOT rst; -- Ready when not in reset

END ARCHITECTURE rtl;
