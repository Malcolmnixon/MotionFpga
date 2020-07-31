-------------------------------------------------------------------------------
--! @file
--! @brief SPI Version Block testbench module
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using VUnit library
LIBRARY vunit_lib;

--! Using VUnit context
CONTEXT vunit_lib.vunit_context;

--! @brief SPI Version Block testbench module
ENTITY spi_version_block_tb IS
    GENERIC (
        runner_cfg : string  
    );
END ENTITY spi_version_block_tb;

--! Architecture tb of spi_version_block_tb entity
ARCHITECTURE tb OF spi_version_block_tb IS

    --! Clock period
    CONSTANT c_clk_period : time := 100 ns;
    
    --! Module Version information
    CONSTANT c_ver_info : std_logic_vector(31 DOWNTO 0) := X"12345678";
    
    -- Signals to unit under test
    SIGNAL mod_clk     : std_logic;                     --! Module clock input to uut
    SIGNAL mod_rst     : std_logic;                     --! Module reset input to uut
    SIGNAL spi_cs      : std_logic;                     --! SPI chip select input to uut
    SIGNAL spi_sclk    : std_logic;                     --! SPI clock input to uut
    SIGNAL spi_mosi    : std_logic;                     --! SPI MOSI input to uut
    SIGNAL spi_miso    : std_logic;                     --! SPI MISO output from uut
    SIGNAL spi_ver_en  : std_logic;                     --! SPI Version Enable input to uut
    SIGNAL dat_rd_reg  : std_logic_vector(31 DOWNTO 0); --! Data read register input to uut
    SIGNAL dat_rd_strt : std_logic;                     --! Data read start output from uut
    SIGNAL dat_wr_reg  : std_logic_vector(31 DOWNTO 0); --! Data write register output from uut
    SIGNAL dat_wr_done : std_logic;                     --! Data write done output from uut
    
    -- Test signals
    SIGNAL mosi_wr : std_logic_vector(31 DOWNTO 0); --! SPI MOSI test pattern to drive into uut
    SIGNAL miso_rd : std_logic_vector(31 DOWNTO 0); --! SPI MISO output pattern driven from uut

BEGIN

    --! Instantiate spi_version_block as unit under test
    i_uut : ENTITY work.spi_version_block(rtl)
        GENERIC MAP (
            ver_info => c_ver_info
        )
        PORT MAP (
            mod_clk_in      => mod_clk,
            mod_rst_in      => mod_rst,
            spi_cs_in       => spi_cs,
            spi_sclk_in     => spi_sclk,
            spi_mosi_in     => spi_mosi,
            spi_miso_out    => spi_miso,
            spi_ver_en_in   => spi_ver_en,
            dat_rd_reg_in   => dat_rd_reg,
            dat_rd_strt_out => dat_rd_strt,
            dat_wr_reg_out  => dat_wr_reg,
            dat_wr_done_out => dat_wr_done
        );
            
    --! @brief Clock generation process
    pr_clock : PROCESS IS
    BEGIN
    
        -- Low for 1/2 clock
        mod_clk <= '0';
        WAIT FOR c_clk_period / 2;
        
        -- High for 1/2 clock
        mod_clk <= '1';
        WAIT FOR c_clk_period / 2;
        
    END PROCESS pr_clock;
    
    --! @brief Stimulus process
    pr_stimulus : PROCESS IS
    BEGIN
    
        -- Setup test
        test_runner_setup(runner, runner_cfg);

        -- Set SPI bus idle
        spi_ver_en <= '1'; -- Enable Version Read
        spi_cs     <= '1'; -- CS: high-idle
        spi_sclk   <= '0'; -- SCLK: low-idle
        spi_mosi   <= '0'; -- MOSI: idle
        
        -- Reset for 5 clocks
        mod_rst <= '1';
        WAIT FOR c_clk_period * 5;
        ASSERT (spi_miso    = '0') REPORT "Expected spi_miso low while in reset" SEVERITY warning;
        ASSERT (dat_rd_strt = '0') REPORT "Expected dat_rd_strt low while in reset" SEVERITY warning;
        ASSERT (dat_wr_done = '0') REPORT "Expected dat_wr_done low while in reset" SEVERITY warning;
        
        -- Release reset for 5 clocks
        mod_rst <= '0';
        WAIT FOR c_clk_period * 5;
        ASSERT (spi_miso    = '0') REPORT "Expected spi_miso low while idle" SEVERITY warning;
        ASSERT (dat_rd_strt = '0') REPORT "Expected dat_rd_strt low while idle" SEVERITY warning;
        ASSERT (dat_wr_done = '0') REPORT "Expected dat_wr_done low while idle" SEVERITY warning;
        
        -- Start SPI transfer with version read
        spi_cs <= '0';
        WAIT FOR c_clk_period;
        ASSERT (dat_rd_strt = '0') REPORT "Expected dat_rd_strt low for version transfer start" SEVERITY warning;
        
        -- Provide test pattern
        dat_rd_reg <= X"AA550011";
        mosi_wr    <= X"DEADBEEF";
        
        -- Wait for 5 clocks (CS-to-Start)
        WAIT FOR c_clk_period * 5;
        ASSERT (dat_rd_strt = '0') REPORT "Expected dat_rd_strt low after version transfer start" SEVERITY warning;
        
        -- Clock SPI bus
        FOR i IN 0 TO 31 LOOP
            -- Drive MOSI
            spi_mosi <= mosi_wr(i);
            
            -- Wait for first-edge delay
            WAIT FOR c_clk_period * 2;
            
            -- Read MISO and transition to second-edge
            miso_rd(i) <= spi_miso;
            spi_sclk   <= '1';

            -- Wait for second-edge delay
            WAIT FOR c_clk_period * 2;
            spi_sclk <= '0';
        END LOOP;

        -- Wait for 5 clocks (End-to-CS)
        WAIT FOR c_clk_period * 5;
        
        -- End SPI transfer
        spi_cs <= '1';
        WAIT FOR c_clk_period;
        ASSERT (dat_wr_done = '0') REPORT "Expected dat_wr_done low for version transfer done" SEVERITY warning;
    
        -- Wait for 10 clocks
        WAIT FOR c_clk_period * 10;
        ASSERT (dat_wr_done = '0') REPORT "Expected dat_wr_done low after version transfer done" SEVERITY warning;
        
        -- Verify test patterns
        ASSERT (miso_rd = c_ver_info) REPORT "Expected miso_rd matches c_ver_info" SEVERITY warning;
    
        -- Start SPI transfer to access device
        spi_ver_en <= '0';
        spi_cs     <= '0';
        WAIT FOR c_clk_period;
        ASSERT (dat_rd_strt = '1') REPORT "Expected dat_rd_strt high for data transfer start" SEVERITY warning;
        
        -- Provide test pattern
        dat_rd_reg <= X"AA550011";
        mosi_wr    <= X"DEADBEEF";
        
        -- Wait for 5 clocks (CS-to-Start)
        WAIT FOR c_clk_period * 5;
        ASSERT (dat_rd_strt = '0') REPORT "Expected dat_rd_strt low after data transfer start" SEVERITY warning;
        
        -- Clock SPI bus
        FOR i IN 0 TO 31 LOOP
            -- Drive MOSI
            spi_mosi <= mosi_wr(i);
            
            -- Wait for first-edge delay
            WAIT FOR c_clk_period * 2;
            
            -- Read MISO and transition to second-edge
            miso_rd(i) <= spi_miso;
            spi_sclk   <= '1';

            -- Wait for second-edge delay
            WAIT FOR c_clk_period * 2;
            spi_sclk <= '0';
        END LOOP;

        -- Wait for 5 clocks (End-to-CS)
        WAIT FOR c_clk_period * 5;
        
        -- End SPI transfer
        spi_cs <= '1';
        WAIT FOR c_clk_period;
        ASSERT (dat_wr_done = '1') REPORT "Expected dat_wr_done high for data transfer done" SEVERITY warning;
    
        -- Wait for 10 clocks
        WAIT FOR c_clk_period * 10;
        ASSERT (dat_wr_done = '0') REPORT "Expected dat_wr_done low after data transfer done" SEVERITY warning;
        
        -- Verify test patterns
        ASSERT (dat_wr_reg = mosi_wr) REPORT "Expected dat_wr_reg matches mosi_wr" SEVERITY warning;
        ASSERT (miso_rd = dat_rd_reg) REPORT "Expected miso_rd matches dat_rd_reg" SEVERITY warning;
    
        -- Finish the test
        test_runner_cleanup(runner);
        
    END PROCESS pr_stimulus;

END ARCHITECTURE tb;
