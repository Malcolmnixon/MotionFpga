-------------------------------------------------------------------------------
--! @file
--! @brief Sigma-Delta modulator device
-------------------------------------------------------------------------------

--! Using IEEE library
LIBRARY ieee;

--! Using IEEE standard logic components
USE ieee.std_logic_1164.ALL;

--! Using IEE standard numeric components
USE ieee.numeric_std.ALL;

--! @brief Sigma-Delta modulator device entity
--!
--! This entity manages four sigma-delta modulators. The write register 
--! contains the new four 8-bit levels. The read register contains the current
--! four 8-bit levels.
ENTITY sdm_device IS
    PORT (
        clk_in         : IN    std_logic;                     --! Clock
        rst_in         : IN    std_logic;                     --! Asynchronous reset
        dat_wr_done_in : IN    std_logic;                     --! Device Write Done flag
        dat_wr_reg_in  : IN    std_logic_vector(31 DOWNTO 0); --! Device Write Register value
        dat_rd_reg_out : OUT   std_logic_vector(31 DOWNTO 0); --! Device Read Register value
        sdm_out        : OUT   std_logic_vector(3 DOWNTO 0)   --! Modulator outputs
    );
END ENTITY sdm_device;

--! Architecture rtl of sdm_device entity
ARCHITECTURE rtl OF sdm_device IS

    --! Array type of four levels
    TYPE sdm_level_set IS ARRAY (3 DOWNTO 0) OF std_logic_vector(7 DOWNTO 0);
    
    --! Levels array
    SIGNAL sdm_level : sdm_level_set;
    
BEGIN

    --! Generate four Sigma-Delta modulators
    g_sdm : FOR i IN 0 TO 3 GENERATE

        --! Generate Sigma-Delta modulator instance
        i_sdm : ENTITY work.sdm(rtl)
            GENERIC MAP (
                bit_width => 8
            )
            PORT MAP (
                clk_in       => clk_in,
                rst_in       => rst_in,
                sdm_level_in => sdm_level(i),
                sdm_out      => sdm_out(i)
            );

    END GENERATE g_sdm;

    --! @brief Process to handle writes and resets
    pr_write : PROCESS (clk_in, rst_in) IS
    BEGIN
        
        IF (rst_in = '1') THEN
            -- Reset levels
            sdm_level(3) <= (OTHERS => '0');
            sdm_level(2) <= (OTHERS => '0');
            sdm_level(1) <= (OTHERS => '0');
            sdm_level(0) <= (OTHERS => '0');
        ELSIF (rising_edge(clk_in)) THEN
            IF (dat_wr_done_in = '1') THEN
                -- Set levels from write register
                sdm_level(3) <= dat_wr_reg_in(31 DOWNTO 24);
                sdm_level(2) <= dat_wr_reg_in(23 DOWNTO 16);
                sdm_level(1) <= dat_wr_reg_in(15 DOWNTO 8);
                sdm_level(0) <= dat_wr_reg_in(7 DOWNTO 0);
            END IF;
        END IF;
        
    END PROCESS pr_write;

    --! @brief Process to handle reads
    pr_read : PROCESS (clk_in) IS
    BEGIN
    
        IF (rising_edge(clk_in)) THEN
            -- Populate read register with levels
            dat_rd_reg_out <= std_logic_vector(sdm_level(3)) &
                              std_logic_vector(sdm_level(2)) &
                              std_logic_vector(sdm_level(1)) &
                              std_logic_vector(sdm_level(0));
        END IF;
        
    END PROCESS pr_read;
    
END ARCHITECTURE rtl;
