-------------------------------------------------------------------------------
--! @file
--! @brief Quadrature Decoder test bench
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Test bench for quad_decoder entity
ENTITY quad_decoder_tb IS
END ENTITY quad_decoder_tb;

--! Architecture tb of quad_decoder_tb entity
ARCHITECTURE tb OF quad_decoder_tb IS

    --! Test bench clock period
    CONSTANT c_clk_period : time := 10 ns;
    
    --! Stimulus record type
    TYPE t_stimulus IS RECORD
        name   : string(1 TO 20);      --! Stimulus name
        rst    : std_logic;            --! Reset input
        quad_a : std_logic;            --! Quadrature a signal
        quad_b : std_logic;            --! Quadrature b signal
        count  : unsigned(2 DOWNTO 0); --! Expected quadrature count
    END RECORD t_stimulus;
    
    --! Stimulus array type
    TYPE t_stimulus_array IS ARRAY(natural RANGE <>) OF t_stimulus;
    
    --! Test stimulus
    CONSTANT c_stimulus : t_stimulus_array := 
    (
        ( 
            name   => "Reset               ",
            rst    => '1',
            quad_a => '0',
            quad_b => '0',
            count  => B"000"
        ),
        ( 
            name   => "No change (0)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '0',
            count  => B"000"
        ),
        ( 
            name   => "Increment (1)       ",
            rst    => '0',
            quad_a => '1',
            quad_b => '0',
            count  => B"001"
        ),
        ( 
            name   => "Increment (2)       ",
            rst    => '0',
            quad_a => '1',
            quad_b => '1',
            count  => B"010"
        ),
        ( 
            name   => "Increment (3)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '1',
            count  => B"011"
        ),
        ( 
            name   => "Increment (4)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '0',
            count  => B"100"
        ),
        ( 
            name   => "Increment (5)       ",
            rst    => '0',
            quad_a => '1',
            quad_b => '0',
            count  => B"101"
        ),
        ( 
            name   => "Increment (6)       ",
            rst    => '0',
            quad_a => '1',
            quad_b => '1',
            count  => B"110"
        ),
        ( 
            name   => "Increment (7)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '1',
            count  => B"111"
        ),
        ( 
            name   => "Increment (0)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '0',
            count  => B"000"
        ),
        ( 
            name   => "No change (0)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '0',
            count  => B"000"
        ),
        ( 
            name   => "Decrement (7)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '1',
            count  => B"111"
        ),
        ( 
            name   => "Decrement (6)       ",
            rst    => '0',
            quad_a => '1',
            quad_b => '1',
            count  => B"110"
        ),
        ( 
            name   => "Decrement (5)       ",
            rst    => '0',
            quad_a => '1',
            quad_b => '0',
            count  => B"101"
        ),
        ( 
            name   => "Decrement (4)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '0',
            count  => B"100"
        ),
        ( 
            name   => "No change (4)       ",
            rst    => '0',
            quad_a => '0',
            quad_b => '0',
            count  => B"100"
        ),
        ( 
            name   => "Glitch (4)          ",
            rst    => '0',
            quad_a => '1',
            quad_b => '1',
            count  => B"100"
        ),
        ( 
            name   => "Glitch (4)          ",
            rst    => '0',
            quad_a => '0',
            quad_b => '0',
            count  => B"100"
        ),
        ( 
            name   => "Increment (5)       ",
            rst    => '0',
            quad_a => '1',
            quad_b => '0',
            count  => B"101"
        ),
        ( 
            name   => "Reset               ",
            rst    => '1',
            quad_a => '1',
            quad_b => '0',
            count  => B"000"
        ),
        ( 
            name   => "No change (1)       ",
            rst    => '0',
            quad_a => '1',
            quad_b => '0',
            count  => B"001"
        )
    );
    
    -- Signals to unit under test
    SIGNAL clk        : std_logic;            --! Signal 'clk' to uut
    SIGNAL rst        : std_logic;            --! Signal 'rst' to uut
    SIGNAL quad_a     : std_logic;            --! Signal 'quad_a' to uut
    SIGNAL quad_b     : std_logic;            --! Signal 'quad_b' to uut
    SIGNAL quad_count : unsigned(2 DOWNTO 0); --! Signal 'quad_count' from uut

    --! Function to create string from unsigned
    FUNCTION to_string (
        vector : unsigned) RETURN string 
    IS
    
        VARIABLE v_str : string(1 TO vector'length);
        
    BEGIN
    
        FOR i IN vector'range LOOP
            v_str(i + 1) := std_logic'image(vector(i))(2);
        END LOOP;
        
        RETURN v_str;
        
    END FUNCTION to_string;
    
BEGIN

    --! Instantiate quad_decoder as unit under test
    i_uut : ENTITY work.quad_decoder(rtl)
        GENERIC MAP (
            bit_width => 3
        )
        PORT MAP (
            mod_clk_in     => clk,
            mod_rst_in     => rst,
            quad_a_in      => quad_a,
            quad_b_in      => quad_b,
            quad_count_out => quad_count
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
        quad_a <= '0';
        quad_b <= '0';
        WAIT FOR c_clk_period;
        
        -- Loop over stimulus
        FOR s IN c_stimulus'range LOOP
            -- Log start of stimulus
            REPORT "Starting: " & c_stimulus(s).name SEVERITY note;
            
            -- Set inputs then wait for clock to rise
            rst    <= c_stimulus(s).rst;
            quad_a <= c_stimulus(s).quad_a;
            quad_b <= c_stimulus(s).quad_b;

            -- Wait for clk to fall
            WAIT UNTIL clk = '0';

            -- Assert count
            ASSERT quad_count = c_stimulus(s).count
                REPORT "Expected count = " & 
                to_string(c_stimulus(s).count) &
                " but got " &
                to_string(quad_count)
                SEVERITY error;
        END LOOP;
		
        -- Log end of test
        REPORT "Finished" SEVERITY note;
        
        -- Finish the simulation
        std.env.finish;
		
    END PROCESS pr_stimulus;

END ARCHITECTURE tb;
