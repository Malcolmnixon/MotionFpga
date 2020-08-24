-------------------------------------------------------------------------------
--! @file
--! @brief Sigma-Delta Modulator module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Sigma-Delta modulator entity
--!
--! This entity is a configurable first-order sigma-delta modulator with
--! a configurable bit-width.
ENTITY sdm IS
    GENERIC (
        bit_width : integer RANGE 1 TO 32 := 8 --! Bit width
    );
    PORT (
        mod_clk_in   : IN    std_logic;                                --! Clock
        mod_rst_in   : IN    std_logic;                                --! Reset (async)
        sdm_level_in : IN    std_logic_vector(bit_width - 1 DOWNTO 0); --! Modulator level
        sdm_out      : OUT   std_logic                                 --! Modulator output
    );
END ENTITY sdm;

--! Architecture rtl of sdm entity
ARCHITECTURE rtl OF sdm IS

    --! Modulator accumulator
    SIGNAL accumulator : unsigned(sdm_level_in'HIGH + 1 DOWNTO 0);
    
BEGIN

    --! @brief Process for sigma-delta generation
    pr_sdm : PROCESS (mod_clk_in, mod_rst_in) IS
    BEGIN
    
        IF (mod_rst_in = '1') THEN
            -- Reset state
            accumulator <= (OTHERS => '0');
        ELSIF (rising_edge(mod_clk_in)) THEN
            -- Accumulate
            accumulator <= unsigned('0' & accumulator(accumulator'HIGH - 1 DOWNTO 0)) + unsigned('0' & sdm_level_in);
        END IF;
            
    END PROCESS pr_sdm;
    
    -- Drive output with MSB of accumulator
    sdm_out <= accumulator(accumulator'HIGH);
       
END ARCHITECTURE rtl;
