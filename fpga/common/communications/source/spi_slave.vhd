-------------------------------------------------------------------------------
--! @file
--! @brief SPI Slave module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief SPI Slave module
--!
--! This SPI slave works with SPI signals using the following format:
--! - CPOL = 0: sclk low when idle.
--! - CPHA = 1: data written on first edge and read on second.
--!
--! This SPI slave provides a simple SPI shift register for reading/writing 
--! data. At the start of a transfer when the CS goes low the 'dat_rd_reg_in'
--! is latched for transmitting.
--!
--! At the end of transfer when the CS goes high the module loads the received
--! data into 'dat_wr_reg_out' then drives the 'dat_wr_done_out' signal for
--! one clock indicating new data has been written to the SPI block.
ENTITY spi_slave IS
    GENERIC (
        size : natural RANGE 1 TO natural'high --! Size of the SPI data
    );
    PORT (
        clk_in          : IN    std_logic;                           --! Clock
        rst_in          : IN    std_logic;                           --! Asynchronous reset
        spi_cs_in       : IN    std_logic;                           --! SPI Chip-select
        spi_sclk_in     : IN    std_logic;                           --! SPI Clock
        spi_mosi_in     : IN    std_logic;                           --! SPI MOSI
        spi_miso_out    : OUT   std_logic;                           --! SPI MISO
        dat_rd_reg_in   : IN    std_logic_vector(size - 1 DOWNTO 0); --! Data Read Register value
        dat_wr_reg_out  : OUT   std_logic_vector(size - 1 DOWNTO 0); --! Data Write Register value
        dat_wr_done_out : OUT   std_logic                            --! Data Write Done flag
    );
END ENTITY spi_slave;

--! Architecture rtl of spi_slave entity
ARCHITECTURE rtl OF spi_slave IS

    --! Flag indicating a transfer is in progress.
    SIGNAL in_xfer : std_logic;

    --! SPI shift register
    SIGNAL shift : std_logic_vector(size - 1 DOWNTO 0);
    
    --! Signal indicating rise of sclk
    SIGNAL sclk_rise : std_logic;
    
    --! Signal indicating fall fo sclk
    SIGNAL sclk_fall : std_logic;

BEGIN

    --! Edge detector for SCLK signal
    i_sclk_edge : ENTITY work.edge_detect(rtl)
        PORT MAP (
            clk_in   => clk_in,
            rst_in   => rst_in,
            sig_in   => spi_sclk_in,
            rise_out => sclk_rise,
            fall_out => sclk_fall
        );

    --! @brief SPI shift process
    pr_shift : PROCESS (clk_in, rst_in) IS
    BEGIN

        IF (rst_in = '1') THEN
            -- Asynchronous reset of state
            in_xfer         <= '0';
            shift           <= (OTHERS => '0');
            spi_miso_out    <= '0';
            dat_wr_reg_out  <= (OTHERS => '0');
            dat_wr_done_out <= '0';
        ELSIF (rising_edge(clk_in)) THEN
            -- Default dat_wr_done_out to 0 (set only on end transfer)
            dat_wr_done_out <= '0';
            
            -- Handle transfer
            IF (in_xfer = '0') THEN
                IF (spi_cs_in = '0') THEN
                    -- Start transfer
                    in_xfer <= '1';
                    shift   <= dat_rd_reg_in;
                END IF;
            ELSE
                IF (spi_cs_in = '1') THEN
                    -- End transfer
                    in_xfer         <= '0';
                    dat_wr_reg_out  <= shift;
                    dat_wr_done_out <= '1';
                ELSIF (sclk_rise = '1') THEN
                    -- First edge - write data
                    spi_miso_out <= shift(size - 1);
                ELSIF (sclk_fall = '1') THEN
                    -- Second edge - capture data
                    shift <= shift(size - 2 DOWNTO 0) & spi_mosi_in;
                END IF;
            END IF;
        END IF;

    END PROCESS pr_shift;

END ARCHITECTURE rtl;
