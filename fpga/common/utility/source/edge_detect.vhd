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
        clk_in   : IN    std_logic; --! Clock
        rst_in   : IN    std_logic; --! Asynchronous reset
        sig_in   : IN    std_logic; --! Input signal
        rise_out : OUT   std_logic; --! Rising edge output
        fall_out : OUT   std_logic  --! Falling edge output
    );
END ENTITY edge_detect;

--! Architecture rtl of edge_detect entity
ARCHITECTURE rtl OF edge_detect IS

    --! Previous input valid signal
    SIGNAL prev_ok : std_logic;
    
    --! Previous input signal
    SIGNAL prev : std_logic;
    
BEGIN

    --! @brief Edge detection process
    pr_detect : PROCESS (clk_in, rst_in) IS
    BEGIN
        
        IF (rst_in = '1') THEN
            -- Aynchronous reset
            prev_ok  <= '0';
            prev     <= '0';
            rise_out <= '0';
            fall_out <= '0';
        ELSIF (rising_edge(clk_in)) THEN
            IF (prev_ok = '1') THEN
                -- Detect rising edge
                IF (sig_in = '1' AND prev = '0') THEN
                    rise_out <= '1';
                ELSE
                    rise_out <= '0';
                END IF;
                
                -- Detect falling edge
                IF (sig_in = '0' AND prev = '1') THEN
                    fall_out <= '1';
                ELSE
                    fall_out <= '0';
                END IF;
            END IF;
            
            -- Save previous sig_in
            prev    <= sig_in;
            prev_ok <= '1';
        END IF;
        
    END PROCESS pr_detect;

END ARCHITECTURE rtl;
