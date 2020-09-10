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
        div_clr : std_logic_vector(0 TO 7); --! div_clr input to uut
        div_adv : std_logic_vector(0 TO 7); --! div_adv input to uut
        div_end : std_logic_vector(0 TO 7); --! div_end expected from uut
        div_pls : std_logic_vector(0 TO 7); --! div_pls expected from uut
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
            div_clr => "00000000",
            div_adv => "00000000",
            div_end => "00000000",
            div_pls => "00000000"
        ),
        ( 
            name    => "Not enabled         ",
            rst     => "00000000",
            div_clr => "00000000",
            div_adv => "00000000",
            div_end => "00000000",
            div_pls => "00000000"
        ),
        ( 
            name    => "Clear               ",
            rst     => "00000000",
            div_clr => "11111111",
            div_adv => "00000000",
            div_end => "00000000",
            div_pls => "00000000"
        ),
        ( 
            name    => "Normal counting 1   ",
            rst     => "00000000",
            div_clr => "00000000",
            div_adv => "11111111",
            div_end => "00010001",
            div_pls => "00010001"
        ),
        ( 
            name    => "Normal counting 2   ",
            rst     => "00000000",
            div_clr => "00000000",
            div_adv => "11111111",
            div_end => "00010001",
            div_pls => "00010001"
        ),
        ( 
            name    => "Freezing count      ",
            rst     => "00000000",
            div_clr => "00000000",
            div_adv => "00001111",
            div_end => "11110001",
            div_pls => "00000001"
        ),
        (
            name    => "Count and clear     ",
            rst     => "00000000",
            div_clr => "00110000",
            div_adv => "11111111",
            div_end => "00000001",
            div_pls => "00000001"
        )
    );
    
    -- Signals to clk_div_n uut
    SIGNAL clk     : std_logic; --! Clock
    SIGNAL rst     : std_logic; --! Reset
    SIGNAL div_clr : std_logic; --! Divider clear to uut
    SIGNAL div_adv : std_logic; --! Divider advance to uut
    SIGNAL div_end : std_logic; --! Divider end from uut
    SIGNAL div_pls : std_logic; --! Divider pulse from uut
    
BEGIN

    --! Instantiate clk_div_n as unit under test
    i_uut : ENTITY work.clk_div_n(rtl)
        GENERIC MAP (
            clk_div => 4
        )
        PORT MAP (
            clk_in      => clk,
            rst_in      => rst,
            div_clr_in  => div_clr,
            div_adv_in  => div_adv,
            div_end_out => div_end,
            div_pls_out => div_pls
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
        rst     <= '1';
        div_clr <= '0';
        div_adv <= '0';
        WAIT FOR c_clk_period;

        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;
            
            -- Loop for test stimulus
            FOR t IN 0 TO 7 LOOP
                -- Set inputs then wait for clock to rise
                rst     <= c_stimulus(s).rst(t);
                div_clr <= c_stimulus(s).div_clr(t);
                div_adv <= c_stimulus(s).div_adv(t);
                WAIT UNTIL clk = '1';
                
                -- Wait for clk to fall
                WAIT UNTIL clk = '0';
                
                -- Assert outputs
                ASSERT div_end = c_stimulus(s).div_end(t)
                    REPORT "At time " & integer'image(t) 
                    & " expected div_end = " & std_logic'image(c_stimulus(s).div_end(t)) 
                    & " but got " & std_logic'image(div_end)
                    SEVERITY error;
                ASSERT div_pls = c_stimulus(s).div_pls(t)
                    REPORT "At time " & integer'image(t) 
                    & " expected div_pls = " & std_logic'image(c_stimulus(s).div_pls(t)) 
                    & " but got " & std_logic'image(div_pls)
                    SEVERITY error;
            END LOOP;
        END LOOP;
		
        -- Log end of test
        REPORT "Finished" SEVERITY note;
        
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;
    
END ARCHITECTURE tb;
