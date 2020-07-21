-------------------------------------------------------------------------------
--! @file
--! @brief SPI Block module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief SPI Block module
ENTITY spi_block IS
    PORT (
        clk_in      : IN    std_logic;                     --! Clock
        rst_in      : IN    std_logic;                     --! Reset
        mode_in     : IN    std_logic_vector(1 DOWNTO 0);  --! Mode select
        cs_in       : IN    std_logic;                     --! SPI Chip-select
        sclk_in     : IN    std_logic;                     --! SPI Clock
        mosi_in     : IN    std_logic;                     --! SPI MOSI
        miso_out    : OUT   std_logic;                     --! SPI MISO
        rd_reg_in   : IN    std_logic_vector(31 DOWNTO 0); --! Read Register value
        rd_strt_out : OUT   std_logic;                     --! Read Start flag
        wr_reg_out  : OUT   std_logic_vector(31 DOWNTO 0); --! Write Register value 
        wr_done_out : OUT   std_logic                      --! Write Done flag
    );
END ENTITY spi_block;

--! Architecture rtl of spi_block entity
ARCHITECTURE rtl OF spi_block IS

    --! @brief SPI state enumeration
    TYPE spi_state IS (
        st_xfr_idle, --! Transfer-idle state waiting for CS-assert
        st_xfr_strt, --! Transfer-start state when transfer is beginning (triggers read)
        st_clk_1st,  --! Clock-first state waiting for SCLK-first-edge or CS-deassert
        st_clk_2nd,  --! Clock-second state waiting for SCLK-second-edge
        st_xfr_done  --! Transfer-done state where transfer is done (triggers write)
    );
    
    --! SPI state
    SIGNAL state : spi_state;
    
    --! SPI shift register
    SIGNAL shift : std_logic_vector(31 DOWNTO 0);
    
BEGIN

    --! @brief SPI shift process
    pr_shift : PROCESS (clk_in, rst_in) IS
    BEGIN
    
        IF (rst_in = '1') THEN
            -- Asynchronous reset of state
            state <= st_xfr_idle;
            shift <= (OTHERS => '0');
        ELSIF (rising_edge(clk_in)) THEN
        
            CASE state IS
            
                WHEN st_xfr_idle =>
                    -- Detect CS-assert
                    IF (cs_in = '0') THEN
                        state <= st_xfr_strt;
                    ELSE
                        state <= st_xfr_idle;
                    END IF;
                    
                WHEN st_xfr_strt =>
                    -- Load read-register
                    shift <= rd_reg_in;
                    state <= st_clk_1st;
                    
                WHEN st_clk_1st =>
                    -- Wait for CS-deassert or SCLK-first-edge
                    IF (cs_in = '1') THEN
                        wr_reg_out <= shift;                   -- Save write-register
                        state      <= st_xfr_done;
                    ELSIF (sclk_in = '1') THEN
                        shift <= mosi_in & shift(31 DOWNTO 1); -- Save bit
                        state <= st_clk_2nd;
                    ELSE
                        state <= st_clk_1st;
                    END IF;
                    
                WHEN st_clk_2nd =>
                    -- Wait for SCLK-second-edge
                    IF (sclk_in = '0') THEN
                        state <= st_clk_1st;
                    ELSE
                        state <= st_clk_2nd;
                    END IF;
                    
                WHEN st_xfr_done =>
                    -- Transition to transfer-idle state
                    state <= st_xfr_idle;
                    
                WHEN OTHERS =>
                    state <= st_xfr_idle;
                    
            END CASE;
            
        END IF;
    
    END PROCESS pr_shift;

    -- Always drive LSB of shift register to MISO
    miso_out <= shift(0);
    
    -- Trigger the read-start when in the transfer-start state
    rd_strt_out <= '1' WHEN state = st_xfr_strt ELSE
                   '0';
    
    -- Trigger the write-done when in the transfer-done state
    wr_done_out <= '1' WHEN state = st_xfr_done ELSE 
                   '0';

END ARCHITECTURE rtl;
