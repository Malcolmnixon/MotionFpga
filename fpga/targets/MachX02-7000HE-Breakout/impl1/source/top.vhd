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
        rst_in    : IN    std_logic;
        ready_out : OUT   std_logic;
        blink_out : OUT   std_logic
    );
END ENTITY top;

--! Architecture rtl of top entity
ARCHITECTURE rtl OF top IS

    SIGNAL osc    : std_logic; --! Internal oscillator (11.08MHz)
    SIGNAL lock   : std_logic; --! PLL Lock 
    SIGNAL clk    : std_logic; --! Main clock (99.72MHz)
    SIGNAL rst_ms : std_logic; --! Reset (possibly metastable)
    SIGNAL rst    : std_logic; --! Reset

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

    ready_out <= NOT rst; -- Ready when not in reset

END ARCHITECTURE rtl;
