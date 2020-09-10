-------------------------------------------------------------------------------
--! @file
--! @brief Counter module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Clock divider entity
--!
--! This clock divider takes an input clock and divides it by an integer
--! value.
ENTITY clk_div_n IS
    GENERIC (
        clk_div : integer RANGE 2 TO integer'high := 4 --! Divider amount
    );
    PORT (
        clk_in      : IN    std_logic; --! Clock
        rst_in      : IN    std_logic; --! Asynchronous reset
        div_clr_in  : IN    std_logic; --! Divider clear flag
        div_adv_in  : IN    std_logic; --! Divider advance flag
        div_end_out : OUT   std_logic; --! Divider end flag
        div_pls_out : OUT   std_logic  --! Divider pulse flag
    );
END ENTITY clk_div_n;

--! Architecture rtl of clk_div_n entity
ARCHITECTURE rtl OF clk_div_n IS

    --! Clock counter
    SIGNAL count : integer RANGE 0 TO clk_div - 1;
    
BEGIN

    --! @brief Clock divider count process
    --!
    --! This process handles counting and reset.
    pr_count : PROCESS (clk_in, rst_in) IS
    BEGIN
        
        IF (rst_in = '1') THEN
            -- Asynchronous aeset
            count       <= 0;
            div_end_out <= '0';
            div_pls_out <= '0';
        ELSIF (rising_edge(clk_in)) THEN
            -- Default pulse to low
            div_pls_out <= '0';
            
            -- Handle conditional advance
            IF (div_clr_in = '1') THEN
                -- Synchronous clear
                count       <= 0;
                div_end_out <= '0';
            ELSIF (div_adv_in = '1') THEN
                IF (count = clk_div - 1) THEN
                    -- Handle roll-over
                    count       <= 0;
                    div_end_out <= '1';
                    div_pls_out <= '1';
                ELSE
                    -- Handle normal advance
                    count       <= count + 1;
                    div_end_out <= '0';
                END IF;
            END IF;
        END IF;
        
    END PROCESS pr_count;

END ARCHITECTURE rtl;

