-------------------------------------------------------------------------------
--! @file
--! @brief PWM device
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

ENTITY gpio_device IS
    PORT (
        clk_in         : IN    std_logic;                     --! Clock
        rst_in         : IN    std_logic;                     --! Asynchronous reset
        dat_wr_done_in : IN    std_logic;                     --! Device Write Done flag
        dat_wr_reg_in  : IN    std_logic_vector(31 DOWNTO 0); --! Device Write Register value
        dat_rd_reg_out : OUT   std_logic_vector(31 DOWNTO 0); --! Device Read Register value
        gpio_bus_in    : IN    std_logic_vector(31 DOWNTO 0); --! GPIO inputs
        gpio_bus_out   : OUT   std_logic_vector(31 DOWNTO 0)  --! GPIO outputs
    );
END ENTITY gpio_device;

ARCHITECTURE rtl OF gpio_device IS

    -- Current gpio outputs
    SIGNAL gpio_out : std_logic_vector(31 DOWNTO 0);
    
BEGIN

    --! @brief Handle outputs (reset and write)
    pr_output : PROCESS (clk_in, rst_in) IS
    BEGIN
    
        IF (rst_in = '1') THEN
            -- Reset
            gpio_out <= (OTHERS => '0');
        ELSIF (rising_edge(clk_in)) THEN
            IF (dat_wr_done_in = '1') THEN
                -- Save write data
                gpio_out <= dat_wr_reg_in;
            END IF;
        END IF;
        
    END PROCESS pr_output;

    -- Drive dat_rd_reg_out from gpio_bus_in
    dat_rd_reg_out <= gpio_bus_in;
    
    -- Drive gpio_bus_out from gpio_out
    gpio_bus_out <= gpio_out;
    
END ARCHITECTURE rtl;
