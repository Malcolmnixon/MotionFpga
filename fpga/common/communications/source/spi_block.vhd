-------------------------------------------------------------------------------
--! @file
--! @brief SPI Block module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief SPI Block module
--!
--! @image html spi_block_entity.png "SPI Block Entity"
--!
--! This SPI block provides a simple 32-bit wide SPI shift register for 
--! reading/writing data. At the start of a transfer when the CS goes low,
--! the module drives the 'dat_rd_strt_out' signal for one clock to request
--! new data be loaded into the 'dat_rd_reg_in' signal for transmitting.
--! At the end of transfer when the CS goes high the module loads the received
--! data into 'dat_wr_reg_out' then drives the 'dat_wr_done_out' signal for
--! one clock indicating new data has been written to the SPI block.
--!
--! @image html spi_block_transfer.png "SPI Block Transfer"
ENTITY spi_block IS
    PORT (
        mod_clk_in      : IN    std_logic;                     --! Module Clock
        mod_rst_in      : IN    std_logic;                     --! Module Reset (async)
        spi_cs_in       : IN    std_logic;                     --! SPI Chip-select
        spi_sclk_in     : IN    std_logic;                     --! SPI Clock
        spi_mosi_in     : IN    std_logic;                     --! SPI MOSI
        spi_miso_out    : OUT   std_logic;                     --! SPI MISO
        dat_rd_reg_in   : IN    std_logic_vector(31 DOWNTO 0); --! Data Read Register value
        dat_rd_strt_out : OUT   std_logic;                     --! Data Read Start flag
        dat_wr_reg_out  : OUT   std_logic_vector(31 DOWNTO 0); --! Data Write Register value 
        dat_wr_done_out : OUT   std_logic                      --! Data Write Done flag
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
    pr_shift : PROCESS (mod_clk_in, mod_rst_in) IS
    BEGIN
    
        IF (mod_rst_in = '1') THEN
            -- Asynchronous reset of state
            state <= st_xfr_idle;
            shift <= (OTHERS => '0');
        ELSIF (rising_edge(mod_clk_in)) THEN
        
            CASE state IS
            
                WHEN st_xfr_idle =>
                    -- Detect CS-assert
                    IF (spi_cs_in = '0') THEN
                        state <= st_xfr_strt;
                    ELSE
                        state <= st_xfr_idle;
                    END IF;
                    
                WHEN st_xfr_strt =>
                    -- Load read-register
                    shift <= dat_rd_reg_in;
                    state <= st_clk_1st;
                    
                WHEN st_clk_1st =>
                    -- Wait for CS-deassert or SCLK-first-edge
                    IF (spi_cs_in = '1') THEN
                        dat_wr_reg_out <= shift;                   -- Save write-register
                        state          <= st_xfr_done;
                    ELSIF (spi_sclk_in = '1') THEN
                        shift <= spi_mosi_in & shift(31 DOWNTO 1); -- Save bit
                        state <= st_clk_2nd;
                    ELSE
                        state <= st_clk_1st;
                    END IF;
                    
                WHEN st_clk_2nd =>
                    -- Wait for SCLK-second-edge
                    IF (spi_sclk_in = '0') THEN
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
    spi_miso_out <= shift(0);
    
    -- Trigger the read-start when in the transfer-start state
    dat_rd_strt_out <= '1' WHEN state = st_xfr_strt ELSE
                       '0';
    
    -- Trigger the write-done when in the transfer-done state
    dat_wr_done_out <= '1' WHEN state = st_xfr_done ELSE 
                       '0';

END ARCHITECTURE rtl;
