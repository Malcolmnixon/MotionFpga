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
        mod_clk_in  : IN    std_logic; --! Module clock
        mod_rst_in  : IN    std_logic; --! Module reset (async)
        clk_clr_in  : IN    std_logic; --! Clock clear flag
        clk_adv_in  : IN    std_logic; --! Clock advance flag
        clk_end_out : OUT   std_logic; --! Clock end flag
        clk_pls_out : OUT   std_logic  --! Clock pulse flag
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
    pr_count : PROCESS (mod_clk_in, mod_rst_in) IS
    BEGIN
        
        IF (mod_rst_in = '1') THEN
            -- Asynchronous aeset
            count       <= 0;
            clk_end_out <= '0';
            clk_pls_out <= '0';
        ELSIF (rising_edge(mod_clk_in)) THEN
            -- Default pulse to low
            clk_pls_out <= '0';
            
            -- Handle conditional advance
            IF (clk_clr_in = '1') THEN
                -- Synchronous clear
                count       <= 0;
                clk_end_out <= '0';
            ELSIF (clk_adv_in = '1') THEN
                IF (count = clk_div - 1) THEN
                    -- Handle roll-over
                    count       <= 0;
                    clk_end_out <= '1';
                    clk_pls_out <= '1';
                ELSE
                    -- Handle normal advance
                    count       <= count + 1;
                    clk_end_out <= '0';
                END IF;
            END IF;
        END IF;
        
    END PROCESS pr_count;

END ARCHITECTURE rtl;

