-------------------------------------------------------------------------------
--! @file
--! @brief SPI Master simulation module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief SPI Master simulation entity
ENTITY sim_spi_master IS
    GENERIC (
        spi_width       : natural := 32;     --! SPI transfer width
        spi_cs_delay    : time    := 500 ns; --! SPI chip-select rise/fall delay
        spi_sclk_period : time    := 400 ns  --! SPI clock period
    );
    PORT (
        mod_rst_in    : IN    std_logic;                                --! Reset
        spi_cs_out    : OUT   std_logic;                                --! SPI chip-select line
        spi_sclk_out  : OUT   std_logic;                                --! SPI sclk line
        spi_mosi_out  : OUT   std_logic;                                --! SPI mosi line
        spi_miso_in   : IN    std_logic;                                --! SPI miso line
        data_mosi_in  : IN    std_logic_vector(spi_width - 1 DOWNTO 0); --! Data to send
        data_miso_out : OUT   std_logic_vector(spi_width - 1 DOWNTO 0); --! Data received
        xfer_start_in : IN    std_logic;                                --! Start transfer flag
        xfer_done_out : OUT   std_logic                                 --! Transfer done flag
    );
END ENTITY sim_spi_master;

--! Architecture sim of entity sim_spi_master
ARCHITECTURE sim OF sim_spi_master IS

BEGIN

    --! @brief SPI transfer process
    --!
    --! This process performs SPI transfers when requested by xfer_start.
    pr_xfer : PROCESS IS
    
        VARIABLE v_data_miso : std_logic_vector(spi_width - 1 DOWNTO 0);
        
    BEGIN
    
        LOOP
            
            IF (mod_rst_in = '1') THEN
                -- Reset
                spi_cs_out    <= '1';
                spi_sclk_out  <= '0';
                spi_mosi_out  <= '0';
                data_miso_out <= (OTHERS => '0');
                xfer_done_out <= '0';
                
                -- Wait for reset to clear
                WAIT UNTIL mod_rst_in = '0';
            ELSIF (xfer_start_in = '1') THEN
                -- Drop chip-select
                WAIT FOR spi_cs_delay;
                spi_cs_out <= '0';
                WAIT FOR spi_cs_delay;
                
                -- Transfer all bits
                FOR b in spi_width - 1 DOWNTO 0 LOOP
                
                    -- First half of clock
                    spi_mosi_out <= data_mosi_in(b);
                    spi_sclk_out <= '1';
                    WAIT FOR spi_sclk_period / 2;
                    
                    -- Second half of clock
                    v_data_miso(b) := spi_miso_in;
                    spi_sclk_out   <= '0';
                    WAIT FOR spi_sclk_period / 2;
                    
                END LOOP;
        
                -- Raise chip-select
                WAIT FOR spi_cs_delay;
                spi_cs_out <= '1';
                WAIT FOR spi_cs_delay;
                
                -- Hand-shake transfer complete
                data_miso_out <= v_data_miso;
                xfer_done_out <= '1';
                WAIT UNTIL xfer_start_in = '0';
                xfer_done_out <= '0';
            ELSE
                -- Wait for work
                WAIT ON mod_rst_in, xfer_start_in;
            END IF;
            
        END LOOP;
        
    END PROCESS pr_xfer;
    
END ARCHITECTURE sim;
