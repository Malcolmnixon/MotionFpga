-------------------------------------------------------------------------------
--! @file
--! @brief Blink module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief Blink entity
--!
--! This entity blinks an LED, toggling the output when max_count number of clocks
--! has been generated.
ENTITY blink IS
    GENERIC (
        max_count : integer := 10 --! Maximum Count value
    );
    PORT (
        clk_in  : IN    std_logic; --! Clock
        rst_in  : IN    std_logic; --! Asynchronous reset
        led_out : OUT   std_logic  --! LED output
    );
END ENTITY blink;

--! Architecture rtl of blink entity
ARCHITECTURE rtl OF blink IS

    --! Internal counter
    SIGNAL count : integer RANGE 0 TO max_count;

    --! Current led
    SIGNAL led : std_logic;

BEGIN

    --! @brief Process to count and toggle
    --!
    --! This process counts clocks and toggles the state when appropriate.
    pr_count : PROCESS (clk_in, rst_in) IS
    BEGIN

        IF (rst_in = '1') THEN
            count <= 0;
            led   <= '0';
        ELSIF (rising_edge(clk_in)) THEN
            IF (count = max_count) THEN
                count <= 0;
                led   <= NOT led;
            ELSE
                count <= count + 1;
            END IF;
        END IF;

    END PROCESS pr_count;

    led_out <= led;

END ARCHITECTURE rtl;
