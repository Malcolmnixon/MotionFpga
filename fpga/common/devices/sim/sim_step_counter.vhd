-------------------------------------------------------------------------------
--! @file
--! @brief Step counter module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Entity to count steps
ENTITY sim_step_counter IS
    PORT (
        rst_in    : IN    std_logic; --! Asynchronous reset
        step_in   : IN    std_logic; --! Step input
        dir_in    : IN    std_logic; --! Direction 
        size_in   : IN    integer;   --! Size of steps
        steps_out : OUT   integer    --! Current steps
    );
END ENTITY sim_step_counter;

--! Architecture sim of entity sim_step_counter
ARCHITECTURE sim OF sim_step_counter IS

    --! Current step count
    SIGNAL steps : integer;
    
BEGIN

    --! @brief Process to count steps
    pr_count : PROCESS (rst_in, step_in) IS
    BEGIN
        
        IF (rst_in = '1') THEN
            -- Reset state
            steps <= 0;
        ELSIF (rising_edge(step_in)) THEN
            -- Count steps
            IF (dir_in = '0') THEN
                steps <= steps + size_in;
            ELSE
                steps <= steps - size_in;
            END IF;
        END IF;
        
    END PROCESS pr_count;

    steps_out <= steps;
    
END ARCHITECTURE sim;
