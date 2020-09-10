-------------------------------------------------------------------------------
--! @file
--! @brief DRV8711 SPI interface
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief DRV8711 spi entity
ENTITY drv8711_spi IS
    PORT (
        clk_in        : IN    std_logic;                     --! Clock
        rst_in        : IN    std_logic;                     --! Asynchronous reset
        data_send_in  : IN    std_logic_vector(15 DOWNTO 0); --! Data to send
        data_recv_out : OUT   std_logic_vector(15 DOWNTO 0); --! Data received
        xfer_adv_in   : IN    std_logic;                     --! Transfer advance flag
        xfer_start_in : IN    std_logic;                     --! Transfer start flag
        xfer_done_out : OUT   std_logic;                     --! Transfer done flag
        spi_scs_out   : OUT   std_logic;                     --! SPI chip-select
        spi_sclk_out  : OUT   std_logic;                     --! SPI clock
        spi_mosi_out  : OUT   std_logic;                     --! SPI mosi
        spi_miso_in   : IN    std_logic                      --! SPI miso
    );
END ENTITY drv8711_spi;

--! Architecture rtl of drv8711_spi entity
ARCHITECTURE rtl OF drv8711_spi IS

    TYPE t_xfer_state IS (xfer_idle, xfer_start_delay, xfer_data, xfer_end_delay, xfer_finish);

    SIGNAL xfer_state : t_xfer_state;
    
    SIGNAL xfer_start : std_logic;
    
    SIGNAL data_send : std_logic_vector(15 DOWNTO 0);
    
    SIGNAL data_recv : std_logic_vector(15 DOWNTO 0);
    
    SIGNAL spi_count : integer RANGE 0 TO 15;
    
    SIGNAL spi_sclk : std_logic;
    
BEGIN

    pr_transfer : PROCESS (clk_in, rst_in) IS
    BEGIN
    
        IF (rst_in = '1') THEN
            xfer_state <= xfer_idle;
            xfer_start <= '0';
            data_send  <= (OTHERS => '0');
            data_recv  <= (OTHERS => '0');
            spi_count  <= 0;
            spi_sclk   <= '0';
        ELSIF (rising_edge(clk_in)) THEN
            -- Latch the transfer start
            xfer_start <= xfer_start OR xfer_start_in;
            
            -- Default done to low
            xfer_done_out <= '0';

            -- Handle transfer when told to advance
            IF (xfer_adv_in = '1') THEN
                
                CASE xfer_state IS
                
                    WHEN xfer_idle =>
                        -- Detect start request
                        IF (xfer_start = '1') THEN
                            -- Begin transfer
                            data_send <= data_send_in;
                            spi_count <= 0;
                            spi_sclk  <= '0';
                            
                            -- Transition to start delay
                            xfer_state <= xfer_start_delay;
                        END IF;
                        
                    WHEN xfer_start_delay =>
                        -- Delay complete, transition to transfer data
                        xfer_state <= xfer_data;
                        
                    WHEN xfer_data =>
                        -- Perform clocked transfer
                        IF (spi_sclk = '0') THEN   
                            -- Sclk low->high: capture incoming data
                            data_recv <= data_recv(14 DOWNTO 0) & spi_miso_in;
                        ELSE
                            -- Sclk high->low: advance outbound data
                            data_send <= data_send(14 DOWNTO 0) & '0';
                        END IF;
                        
                        -- Update state on end of bit
                        IF (spi_sclk = '1') THEN
                            IF (spi_count = 15) THEN
                                -- Transfer complete, transition to end delay
                                xfer_state <= xfer_end_delay;
                            ELSE					   
                                -- Count bytes complete
                                spi_count <= spi_count + 1;
                            END IF;
                        END IF;
                        
                        -- Toggle sclk
                        spi_sclk <= NOT spi_sclk;
                        
                    WHEN xfer_end_delay =>
                        -- Delay complete, transition to finish
                        xfer_state <= xfer_finish;
                        
                    WHEN xfer_finish =>
                        -- Handle finish
                        xfer_start    <= '0';
                        xfer_done_out <= '1';
                        xfer_state    <= xfer_idle;
                        
                    WHEN OTHERS =>
                        xfer_state <= xfer_idle;
                        
                END CASE;
                
            END IF;
        END IF;
        
    END PROCESS pr_transfer;
                                                         
    data_recv_out <= data_recv;
    
    spi_scs_out <= '1' WHEN xfer_state = xfer_start_delay ELSE
                   '1' WHEN xfer_state = xfer_data ELSE
                   '1' WHEN xfer_state = xfer_end_delay ELSE
                   '0';
                  
    spi_sclk_out <= spi_sclk;
    
    spi_mosi_out <= data_send(15) WHEN xfer_state = xfer_data ELSE
                    '0';
    
END ARCHITECTURE rtl;
