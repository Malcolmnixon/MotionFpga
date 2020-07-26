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
--! @image html clk_div_n_entity.png "Clock Divider Entity"
--!
--! This clock divider takes an input clock and divides it by an integer
--! value.
ENTITY clk_div_n IS
    GENERIC (
        divide : integer RANGE 1 TO integer'high := 4 --! Divider amount
    );
    PORT (
        mod_clk_in : IN    std_logic; --! Module clock
        mod_rst_in : IN    std_logic; --! Module reset (async)
        cnt_en_in  : IN    std_logic; --! Count enable
        cnt_out    : OUT   std_logic  --! Count output
    );
END ENTITY clk_div_n;

--! Architecture rtl of clk_div_n entity
ARCHITECTURE rtl OF clk_div_n IS

    --! Clock counter
    SIGNAL count : integer RANGE 0 TO divide - 1;
    
BEGIN

    --! @brief Clock divider count process
    --!
    --! This process handles counting and reset.
    pr_count : PROCESS (mod_clk_in, mod_rst_in) IS
    BEGIN
        
        IF (mod_rst_in = '1') THEN
            count   <= 0;
            cnt_out <= '0';
        ELSIF (rising_edge(mod_clk_in) AND cnt_en_in = '1') THEN
            IF (count = divide - 1) THEN
                count   <= 0;
                cnt_out <= '1';
            ELSE
                count   <= count + 1;
                cnt_out <= '0';
            END IF;
        END IF;
        
    END PROCESS pr_count;

END ARCHITECTURE rtl;

