-------------------------------------------------------------------------------
--! @file
--! @brief On percentage simulation module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Entity to count edges
ENTITY sim_edge_count IS
    PORT (
        clk_in    : IN    std_logic; --! Clock
        rst_in    : IN    std_logic; --! Asynchronous reset
        signal_in : IN    std_logic; --! Signal input
        rise_out  : OUT   integer;   --! Count of rising edges
        fall_out  : OUT   integer    --! Count of falling edges
    );
END ENTITY sim_edge_count;

--! Architecture sim of entity sim_edge_count
ARCHITECTURE sim OF sim_edge_count IS

    SIGNAL prev_signal : std_logic; --! Previous signal
    SIGNAL prev_ok     : std_logic; --! Previous signal ok flag
    SIGNAL rise        : integer;   --! Count of rising edges
    SIGNAL fall        : integer;   --! Count of falling edges
    
BEGIN

    --! @brief Counting process
    --!
    --! This process counts the rising and falling edges
    pr_count : PROCESS (clk_in, rst_in) IS
    BEGIN
    
        IF (rst_in = '1') THEN
            -- Reset counts
            prev_signal <= '0';
            prev_ok     <= '0';
            rise        <= 0;
            fall        <= 0;
        ELSIF (rising_edge(clk_in)) THEN
            -- Detect edges
            IF (prev_ok = '1') THEN
                -- Count rising edges
                IF (prev_signal = '0' AND signal_in = '1') THEN
                    rise <= rise + 1;
                END IF;
                
                -- Count falling edges
                IF (prev_signal = '1' AND signal_in = '0') THEN
                    fall <= fall + 1;
                END IF;
            END IF;
            
            -- Update previous signal
            prev_signal <= signal_in;
            prev_ok     <= '1';
        END IF;
    
    END PROCESS pr_count;
    
    -- Output counts
    rise_out <= rise;
    fall_out <= fall;

END ARCHITECTURE sim;
