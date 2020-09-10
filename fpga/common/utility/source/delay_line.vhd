-------------------------------------------------------------------------------
--! @file
--! @brief Delay-line module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief Delay-line entity
--!
--! This entity acts as a delay-line for signals
ENTITY delay_line IS
    GENERIC (
        count : natural RANGE 1 TO natural'high := 2 --! Delay length
    );
    PORT (
        clk_in  : IN    std_logic; --! Clock
        rst_in  : IN    std_logic; --! Asynchronous reset
        sig_in  : IN    std_logic; --! Input signal
        sig_out : OUT   std_logic  --! Output signal
    );
END ENTITY delay_line;

--! Architecture rtl of delay_line entity
ARCHITECTURE rtl OF delay_line IS

    --! Input history shift register
    SIGNAL history : std_logic_vector(count - 1 DOWNTO 0);
    
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
            -- Update history
            history <= sig_in & history(history'high DOWNTO 1);
            state   <= history(0);
        END IF;
    
    END PROCESS pr_shift;
    
    -- Drive sig_out from current state
    sig_out <= state;
    
END ARCHITECTURE rtl;
