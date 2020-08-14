-------------------------------------------------------------------------------
--! @file
--! @brief Edge detect module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief Edge detect entity
--!
--! This edge detect entity takes a signal input and detects rising or falling
--! edges.
ENTITY edge_detect IS
    PORT (
        mod_clk_in : IN    std_logic; --! Module clock
        mod_rst_in : IN    std_logic; --! Module reset (async)
        sig_in     : IN    std_logic; --! Input signal
        rise_out   : OUT   std_logic; --! Rising edge output
        fall_out   : OUT   std_logic  --! Falling edge output
    );
END ENTITY edge_detect;

--! Architecture rtl of edge_detect entity
ARCHITECTURE rtl OF edge_detect IS

    --! Previous input signal
    SIGNAL sig_prev : std_logic;
    
BEGIN

    --! @brief Edge detection process
    pr_detect : PROCESS (mod_rst_in, mod_clk_in) IS
    BEGIN
        
        IF (mod_rst_in = '1') THEN
            -- Aynchronous reset
            sig_prev <= sig_in;
            rise_out <= '0';
            fall_out <= '0';
        ELSIF (rising_edge(mod_clk_in)) THEN
            -- Detect rising edge
            IF (sig_in = '1' AND sig_prev = '0') THEN
                rise_out <= '1';
            ELSE
                rise_out <= '0';
            END IF;
            
            -- Detect falling edge
            IF (sig_in = '0' AND sig_prev = '1') THEN
                fall_out <= '1';
            ELSE
                fall_out <= '0';
            END IF;
            
            -- Save previous sig_in
            sig_prev <= sig_in;
        END IF;
        
    END PROCESS pr_detect;

END ARCHITECTURE rtl;