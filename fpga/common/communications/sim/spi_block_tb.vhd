-------------------------------------------------------------------------------
--! @file
--! @brief SPI Block testbench module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! @brief SPI Block testbench module
ENTITY spi_block_tb IS
END ENTITY spi_block_tb;

--! Architecture tb of spi_block_tb entity
ARCHITECTURE tb OF spi_block_tb IS

    -- Clock period
    CONSTANT clk_period : time := 100ns;
    
    -- Signals to unit under test
    SIGNAL clk     : std_logic;
    SIGNAL rst     : std_logic;
    SIGNAL mode    : std_logic_vector(1 DOWNTO 0);
    SIGNAL cs      : std_logic;
    SIGNAL sclk    : std_logic;
    SIGNAL mosi    : std_logic;
    SIGNAL miso    : std_logic;
    SIGNAL rd_reg  : std_logic_vector(31 DOWNTO 0);
    SIGNAL rd_strt : std_logic;
    SIGNAL wr_reg  : std_logic_vector(31 DOWNTO 0);
    SIGNAL wr_done : std_logic;    
    
    -- Test signals
    SIGNAL mosi_wr : std_logic_vector(31 DOWNTO 0);
    SIGNAL miso_rd : std_logic_vector(31 DOWNTO 0);

BEGIN

    --! Instantiate spi_block as unit under test
    i_uut : ENTITY work.spi_block(rtl)
        PORT MAP (
            clk_in      => clk,
            rst_in      => rst,
            mode_in     => mode,
            cs_in       => cs,
            sclk_in     => sclk,
            mosi_in     => mosi,
            miso_out    => miso,
            rd_reg_in   => rd_reg,
            rd_strt_out => rd_strt,
            wr_reg_out  => wr_reg,
            wr_done_out => wr_done
        );
            
    --! @brief Clock generation process
    pr_clock : PROCESS IS
    BEGIN
    
        -- Low for 1/2 clock
        clk <= '0';
        WAIT FOR clk_period / 2;
        
        -- High for 1/2 clock
        clk <= '1';
        WAIT FOR clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process
    pr_stimulus : PROCESS IS
    BEGIN
    
        -- Set SPI bus idle
        cs   <= '1'; -- CS: high-idle
        sclk <= '0'; -- SCLK: low-idle
        mosi <= '0'; -- MOSI: idle
        
        -- Reset for 5 clocks
        rst <= '1';
        WAIT FOR clk_period * 5;
        ASSERT (miso    = '0') REPORT "Expected miso low while in reset" SEVERITY warning;
        ASSERT (rd_strt = '0') REPORT "Expected rd_strt low while in reset" SEVERITY warning;
        ASSERT (wr_done = '0') REPORT "Expected wr_done low while in reset" SEVERITY warning;
        
        -- Release reset for 5 clocks
        rst <= '0';
        WAIT FOR clk_period * 5;
        ASSERT (miso    = '0') REPORT "Expected miso low while idle" SEVERITY warning;
        ASSERT (rd_strt = '0') REPORT "Expected rd_strt low while idle" SEVERITY warning;
        ASSERT (wr_done = '0') REPORT "Expected wr_done low while idle" SEVERITY warning;
        
        -- Start SPI transfer
        cs <= '0';
        WAIT FOR clk_period;
        ASSERT (rd_strt = '1') REPORT "Expected rd_strt high for transfer start" SEVERITY warning;
        
        -- Provide test pattern
        rd_reg  <= X"AA550011";
        mosi_wr <= X"DEADBEEF";
        
        -- Wait for 5 clocks (CS-to-Start)
        WAIT FOR clk_period * 5;
        ASSERT (rd_strt = '0') REPORT "Expected rd_strt low after transfer start" SEVERITY warning;
        
        -- Clock SPI bus
        FOR i IN 0 TO 31 LOOP
            -- Drive MOSI
            mosi <= mosi_wr(i);
            
            -- Wait for first-edge delay
            WAIT FOR clk_period * 2;
            
            -- Read MISO and transition to second-edge
            miso_rd(i) <= miso;
            sclk       <= '1';

            -- Wait for second-edge delay
            WAIT FOR clk_period * 2;
            sclk <= '0';
        END LOOP;

        -- Wait for 5 clocks (End-to-CS)
        WAIT FOR clk_period * 5;
        
        -- End SPI transfer
        cs <= '1';
        WAIT FOR clk_period;
        ASSERT (wr_done = '1') REPORT "Expected wr_done high for transfer done" SEVERITY warning;
    
        -- Wait for 5 clocks
        WAIT FOR clk_period * 5;
        ASSERT (wr_done = '0') REPORT "Expected wr_done low after transfer done" SEVERITY warning;
        
        -- Verify test patterns
        ASSERT (wr_reg = mosi_wr) REPORT "Expected wr_reg matches mosi_wr" SEVERITY warning;
        ASSERT (miso_rd = rd_reg) REPORT "Expected miso_rd matches rd_reg" SEVERITY warning;
    
        -- Finish the simulation
        std.env.finish;
        
    END PROCESS pr_stimulus;

END ARCHITECTURE tb;
