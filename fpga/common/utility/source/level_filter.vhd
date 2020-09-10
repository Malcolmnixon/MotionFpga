-------------------------------------------------------------------------------
--! @file
--! @brief Level-filter module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief Level-filter entity
--!
--! This entity acts as a level-filter which changes when a signal is
--! stable at a level for the specified count.
ENTITY level_filter IS
    GENERIC (
        count : natural RANGE 1 TO natural'high := 2 --! Filter length
    );
    PORT (
        clk_in  : IN    std_logic; --! Clock
        rst_in  : IN    std_logic; --! Asynchronous reset
        sig_in  : IN    std_logic; --! Input signal
        sig_out : OUT   std_logic  --! Output signal
    );
END ENTITY level_filter;

--! Architecture rtl of level_filter entity
ARCHITECTURE rtl OF level_filter IS

    --! Constant for all-high
    CONSTANT c_high : std_logic_vector(count - 2 DOWNTO 0) := (OTHERS => '1');

    --! Constant for all-low
    CONSTANT c_low : std_logic_vector(count - 2 DOWNTO 0) := (OTHERS => '0');

    --! Input history shift register
    SIGNAL history : std_logic_vector(count - 2 DOWNTO 0);

    --! Current state
    SIGNAL state : std_logic;

BEGIN

    --! @brief Shift process
    pr_shift : PROCESS (clk_in, rst_in) IS
    BEGIN

        IF (rst_in = '1') THEN
            -- Reset
            history <= (OTHERS => '0');
            state   <= '0';
        ELSIF (rising_edge(clk_in)) THEN
            -- Detect level
            IF (sig_in = '1' AND history = c_high) THEN
                state <= '1';
            ELSIF (sig_in = '0' AND history = c_low) THEN
                state <= '0';
            END IF;

            -- Update history
            IF (count = 2) THEN
                history(0) <= sig_in;
            ELSE
                history <= sig_in & history(history'high DOWNTO 1);
            END IF;
        END IF;

    END PROCESS pr_shift;

    -- Drive sig_out from current state
    sig_out <= state;

END ARCHITECTURE rtl;
