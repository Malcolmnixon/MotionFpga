-------------------------------------------------------------------------------
--! @file
--! @brief Clock divider test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief clk_div_n test bench
ENTITY clk_div_n_tb IS
END ENTITY clk_div_n_tb;

--! Architecture tb of clk_div_n_tb entity
ARCHITECTURE tb OF clk_div_n_tb IS

    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name    : string(1 TO 20);          --! Stimulus name
        rst     : std_logic_vector(0 TO 7); --! rst input to uut
        cnt_en  : std_logic_vector(0 TO 7); --! cnt_en input to uut
        cnt_out : std_logic_vector(0 TO 7); --! cnt_out expected from uut
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
            cnt_en  => "00000000",
            cnt_out => "00000000"
        ),
        ( 
            name    => "Not enabled         ",
            rst     => "00000000",
            cnt_en  => "00000000",
            cnt_out => "00000000"
        ),
        ( 
            name    => "Normal counting 1   ",
            rst     => "00000000",
            cnt_en  => "11111111",
            cnt_out => "00010001"
        ),
        ( 
            name    => "Normal counting 2   ",
            rst     => "00000000",
            cnt_en  => "11111111",
            cnt_out => "00010001"
        ),
        ( 
            name    => "Freezing count      ",
            rst     => "00000000",
            cnt_en  => "00001111",
            cnt_out => "11110001"
        )
    );
    
    -- Signals to unit under test
    SIGNAL clk     : std_logic; --! Clock input to unit under test
    SIGNAL rst     : std_logic; --! Reset input to unit under test
    SIGNAL cnt_en  : std_logic; --! Count enable input to unit under test
    SIGNAL cnt_out : std_logic; --! Count output from unit under test
    
BEGIN

    --! Instantiate clk_div_n as unit under test
    i_uut : ENTITY work.clk_div_n(rtl)
        GENERIC MAP (
            divide => 4
        )
        PORT MAP (
            mod_clk_in => clk,
            mod_rst_in => rst,
            cnt_en_in  => cnt_en,
            cnt_out    => cnt_out
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
        cnt_en <= '0';
        WAIT FOR c_clk_period;

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;
            
            -- Loop for test stimulus
            FOR t IN 0 TO 7 LOOP
                -- Set inputs then wait for clock to rise
                rst    <= c_stimulus(s).rst(t);
                cnt_en <= c_stimulus(s).cnt_en(t);
                WAIT UNTIL clk = '1';
                
                -- Wait for clk to fall
                WAIT UNTIL clk = '0';
                
                -- Assert outputs
                ASSERT cnt_out = c_stimulus(s).cnt_out(t)
                    REPORT "At time " & integer'image(t) 
                    & " expected " & std_logic'image(c_stimulus(s).cnt_out(t)) 
                    & " but got " & std_logic'image(cnt_out)
                    SEVERITY error;
            END LOOP;
        END LOOP;
		
        -- Log end of test
        REPORT "Finished" SEVERITY note;
        
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;
