-------------------------------------------------------------------------------
--! @file
--! @brief Level-filter test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief level-filter test bench
ENTITY level_filter_tb IS
END ENTITY level_filter_tb;

--! Architecture tb of level_filter_tb entity
ARCHITECTURE tb OF level_filter_tb IS

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name    : string(1 TO 20);          --! Stimulus name
        rst     : std_logic_vector(0 TO 7); --! rst input to uut
        sig_in  : std_logic_vector(0 TO 7); --! signal input
        sig_out : std_logic_vector(0 TO 7); --! Expected signal output
    END RECORD t_stimulus;
    
    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;
    
    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name    => "Hold in reset       ",
            rst     => "11111111",
            sig_in  => "01010101",
            sig_out => "00000000"
        ),
        ( 
            name    => "Active              ",
            rst     => "00000000",
            sig_in  => "01011000",
            sig_out => "00001100"
        )
    );
    
    -- Signals to level-filter uut
    SIGNAL clk     : std_logic; --! Clock
    SIGNAL rst     : std_logic; --! Reset
    SIGNAL sig_in  : std_logic; --! Signal in to uut
    SIGNAL sig_out : std_logic; --! Signal out from uut
    
BEGIN

    --! Instantiate level_filter as unit under test
    i_uut : ENTITY work.level_filter(rtl)
        GENERIC MAP (
            count => 2
        )
        PORT MAP (
            clk_in  => clk,
            rst_in  => rst,
            sig_in  => sig_in,
            sig_out => sig_out
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
        rst    <= '1';
        sig_in <= '0';
        WAIT FOR c_clk_period;

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;
            
            -- Loop for test stimulus
            FOR t IN 0 TO 7 LOOP
                -- Set inputs then wait for clock to rise
                rst    <= c_stimulus(s).rst(t);
                sig_in <= c_stimulus(s).sig_in(t);
                WAIT UNTIL clk = '1';
                
                -- Wait for clk to fall
                WAIT UNTIL clk = '0';
                
                -- Assert outputs
                ASSERT sig_out = c_stimulus(s).sig_out(t)
                    REPORT "At time " & integer'image(t) 
                    & " expected sig_out = " & std_logic'image(c_stimulus(s).sig_out(t)) 
                    & " but got " & std_logic'image(sig_out)
                    SEVERITY error;
            END LOOP;
        END LOOP;
		
        -- Log end of test
        REPORT "Finished" SEVERITY note;
        
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;
