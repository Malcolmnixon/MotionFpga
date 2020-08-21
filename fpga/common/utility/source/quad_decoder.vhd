-------------------------------------------------------------------------------
--! @file
--! @brief Quadrature decoder module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Quadrature decoder entity
ENTITY quad_decoder IS
    GENERIC (
        bit_width : natural := 8 --! Width of the quadrature decoder
    );
    PORT (
        mod_clk_in     : IN    std_logic;                       --! Clock
        mod_rst_in     : IN    std_logic;                       --! Reset
        quad_a_in      : IN    std_logic;                       --! Quadrature a input
        quad_b_in      : IN    std_logic;                       --! Quadrature b input
        quad_count_out : OUT   unsigned(bit_width - 1 DOWNTO 0) --! Quadrature count output
    );
END ENTITY quad_decoder;

--! Architecture rtl of quad_encoder entity
ARCHITECTURE rtl OF quad_decoder IS

    -- Delayed inputs
    SIGNAL quad_a_old : std_logic; --! Old copy of quad_a
    SIGNAL quad_b_old : std_logic; --! Old copy of quad_b
    
    --! Quadrature count
    SIGNAL quad_count : unsigned(bit_width - 1 DOWNTO 0);
    
BEGIN

    --! @brief Process to perform quadrature counting
    pr_count : PROCESS (mod_rst_in, mod_clk_in) IS
    
        VARIABLE v_count_en  : std_logic; --! Flag to perform count
        VARIABLE v_count_dir : std_logic; --! Flag for count direction
        
    BEGIN
    
        IF (mod_rst_in = '1') THEN
            -- Reset counter
            quad_a_old <= '0';
            quad_b_old <= '0';
            quad_count <= (OTHERS => '0');
        ELSIF (rising_edge(mod_clk_in)) THEN
            -- Evaluate whether to count and in which direction
            v_count_en  := quad_a_in XOR quad_a_old XOR quad_b_in XOR quad_b_old;
            v_count_dir := quad_a_in XOR quad_b_old;
            
            -- Perform counting
            IF (v_count_en = '1') THEN
                IF (v_count_dir = '1') THEN
                    quad_count <= quad_count + 1;
                ELSE
                    quad_count <= quad_count - 1;
                END IF;
            END IF;
            
            -- Update delayed inputs
            quad_a_old <= quad_a_in;
            quad_b_old <= quad_b_in;
        END IF;
        
    END PROCESS pr_count;

    --! Drive quadrature output
    quad_count_out <= quad_count;

END ARCHITECTURE rtl;
