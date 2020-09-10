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

--! @brief Entity to measure on-percentage of signal
ENTITY sim_on_percent IS
    PORT (
        clk_in      : IN    std_logic; --! Clock
        rst_in      : IN    std_logic; --! Asynchronous reset
        signal_in   : IN    std_logic; --! Signal input
        percent_out : OUT   integer    --! On percentage output
    );
END ENTITY sim_on_percent;

--! Architecture sim of entity sim_on_percent
ARCHITECTURE sim OF sim_on_percent IS

    SIGNAL count    : integer; --! Clock count
    SIGNAL count_on : integer; --! On count
    
BEGIN

    --! @brief Counting process
    --!
    --! This process counts the clocks and signal on-time to get the percentage
    pr_count : PROCESS (clk_in, rst_in) IS
    BEGIN
    
        IF (rst_in = '1') THEN
            -- Reset counts
            count       <= 0;
            count_on    <= 0;
            percent_out <= 0;
        ELSIF (rising_edge(clk_in)) THEN
            -- Update counts
            count <= count + 1;
            IF (signal_in = '1') THEN
                count_on <= count_on + 1;
            END IF;
            
            -- Calculate percentage
            IF (count > 0) THEN
                percent_out <= (count_on * 100) / count;
            END IF;
        END IF;
    
    END PROCESS pr_count;

END ARCHITECTURE sim;
