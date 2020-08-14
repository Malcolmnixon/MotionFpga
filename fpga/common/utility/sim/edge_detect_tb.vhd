-------------------------------------------------------------------------------
--! @file
--! @brief Edge detect test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief Test bench for edge_detect entity
ENTITY edge_detect_tb IS
END ENTITY edge_detect_tb;

--! Architecture tb of edge_detect_tb entity
ARCHITECTURE tb OF edge_detect_tb IS

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name : string(1 TO 20);          --! Stimulus name
        rst  : std_logic_vector(0 TO 7); --! rst input to uut
        sig  : std_logic_vector(0 TO 7); --! sig input to uut
        rise : std_logic_vector(0 TO 7); --! rise expected from uut
        fall : std_logic_vector(0 TO 7); --! fall expected from uut
    END RECORD t_stimulus;
    
    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;
    
    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name => "Hold in reset       ",
            rst  => "11111111",
            sig  => "00000000",
            rise => "00000000",
            fall => "00000000"
        ),
        ( 
            name => "Wake low then edges ",
            rst  => "10000000",
            sig  => "00011100",
            rise => "00010000",
            fall => "00000010"
        ),
        ( 
            name => "Wake high then edges",
            rst  => "10000000",
            sig  => "11100011",
            rise => "00000010",
            fall => "00010000"
        )
    );
    
    -- Signals to unit under test
    SIGNAL clk  : std_logic; --! Signal 'clk' to uut
    SIGNAL rst  : std_logic; --! Signal 'rst' to uut
    SIGNAL sig  : std_logic; --! Signal 'sig' to uut
    SIGNAL rise : std_logic; --! Signal 'rise' from uut
    SIGNAL fall : std_logic; --! Signal 'fall' from uut
    
BEGIN

    --! Instantiate edge_detect as unit under test
    i_uut : ENTITY work.edge_detect(rtl)
        PORT MAP (
            mod_clk_in => clk,
            mod_rst_in => rst,
            sig_in     => sig,
            rise_out   => rise,
            fall_out   => fall
        );

    --! @brief Clock generation process
    pr_clock : PROCESS IS
    BEGIN
    
        -- Low for 1/2 clock period
        clk <= '0';
        WAIT FOR c_clk_period / 2;
        
        -- High for 1/2 clock period
        clk <= '1';
        WAIT FOR c_clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process to drive PWM unit under test
    pr_stimulus : PROCESS IS
    BEGIN
        
        -- Initialize entity inputs
        rst <= '1';
        sig <= '0';
        WAIT FOR c_clk_period;

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;
            
            -- Loop for test stimulus
            FOR t IN 0 TO 7 LOOP
                -- Set inputs then wait for clock to rise
                rst <= c_stimulus(s).rst(t);
                sig <= c_stimulus(s).sig(t);
                WAIT UNTIL clk = '1';
                
                -- Wait for clk to fall
                WAIT UNTIL clk = '0';
                
                -- Assert rise
                ASSERT rise = c_stimulus(s).rise(t)
                    REPORT "At time " & integer'image(t) 
                    & " expected rise = " & std_logic'image(c_stimulus(s).rise(t)) 
                    & " but got " & std_logic'image(rise)
                    SEVERITY error;
                
                -- Assert fall
                ASSERT fall = c_stimulus(s).fall(t)
                    REPORT "At time " & integer'image(t) 
                    & " expected fall = " & std_logic'image(c_stimulus(s).fall(t)) 
                    & " but got " & std_logic'image(fall)
                    SEVERITY error;
            END LOOP;
        END LOOP;
		
        -- Log end of test
        REPORT "Finished" SEVERITY note;
        
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;
