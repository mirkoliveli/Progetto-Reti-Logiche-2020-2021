----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineers: Longhi Leonardo, Li Veli Mirko
-- Codice persona: 10548811, 10562617
-- Componente project_reti_logiche
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
ENTITY project_reti_logiche IS
    PORT (
        i_clk : IN STD_LOGIC;
        i_rst : IN STD_LOGIC;
        i_start : IN STD_LOGIC;
        i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        o_done : OUT STD_LOGIC;
        o_en : OUT STD_LOGIC;
        o_we : OUT STD_LOGIC;
        o_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
END project_reti_logiche;
ARCHITECTURE Behavioral OF project_reti_logiche IS
    COMPONENT datapath IS
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst : IN STD_LOGIC;
            i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_next_state : OUT STD_LOGIC;
            compute_size_dim_1 : IN STD_LOGIC;
            compute_size_dim_2 : IN STD_LOGIC;
            compute_size : IN STD_LOGIC;
            compute_max_min : IN STD_LOGIC;
            compute_shift_level : IN STD_LOGIC;
            compute_filter_r : IN STD_LOGIC;
            compute_filter_w : IN STD_LOGIC
        );
    END COMPONENT;
    TYPE state IS (reset, sd_1, sd_2, sd, seek, shift_state, filter_r, filter_w, end_state);
    SIGNAL size_dim_1 : STD_LOGIC;
    SIGNAL size_dim_2 : STD_LOGIC;
    SIGNAL size_compute : STD_LOGIC;
    SIGNAL compute_max_min : STD_LOGIC;
    SIGNAL compute_shift_value : STD_LOGIC;
    SIGNAL filter_read : STD_LOGIC;
    SIGNAL filter_write : STD_LOGIC;
    SIGNAL rst_datapath : STD_LOGIC;

    SIGNAL next_state_ready : STD_LOGIC;
    SIGNAL next_state : state; -- stato prossimo
    SIGNAL curr_state : state; -- stato corrente

BEGIN
    DATAPATH0 : datapath PORT MAP(
        i_clk => i_clk,
        i_rst => rst_datapath,
        i_data => i_data,
        o_data => o_data,
        o_address => o_address,
        o_next_state => next_state_ready,
        compute_size_dim_1 => size_dim_1,
        compute_size_dim_2 => size_dim_2,
        compute_size => size_compute,
        compute_max_min => compute_max_min,
        compute_shift_level => compute_shift_value,
        compute_filter_r => filter_read,
        compute_filter_w => filter_write
    );

    assign_new_state : PROCESS (i_clk, i_rst)
    BEGIN
        IF (i_rst = '1') THEN
            curr_state <= reset;
        ELSIF (i_clk'event AND i_clk = '1') THEN
            curr_state <= next_state;
        END IF;
    END PROCESS;

    compute_next_state : PROCESS (curr_state, i_start, next_state_ready)
    BEGIN
        next_state <= curr_state;
        CASE curr_state IS
            WHEN reset =>
                IF (i_start = '1') THEN
                    next_state <= sd_1;
                ELSE
                    next_state <= reset;
                END IF;
            WHEN sd_1 =>
                next_state <= sd_2;
            WHEN sd_2 =>
                next_state <= sd;
            WHEN sd =>
                next_state <= seek;
            WHEN seek =>
                IF (next_state_ready = '1') THEN
                    next_state <= shift_state;
                ELSE
                    next_state <= seek;
                END IF;
            WHEN shift_state =>
                next_state <= filter_r;
            WHEN filter_r =>
                IF (next_state_ready = '1') THEN
                    next_state <= end_state;
                ELSE
                    next_state <= filter_w;
                END IF;
            WHEN filter_w =>
                next_state <= filter_r;
            WHEN end_state =>
                next_state <= end_state;
                IF (i_start = '0') THEN
                    next_state <= reset;
                END IF;
        END CASE;
    END PROCESS;

    assign_new_signal : PROCESS (curr_state)
    BEGIN
        size_dim_1 <= '0';
        size_dim_2 <= '0';
        size_compute <= '0';
        compute_max_min <= '0';
        compute_shift_value <= '0';
        filter_read <= '0';
        filter_write <= '0';
        o_we <= '0';
        o_en <= '1';
        o_done <= '0';
        CASE curr_state IS
            WHEN reset =>
            WHEN sd_1 =>
                size_dim_1 <= '1';
            WHEN sd_2 =>
                size_dim_2 <= '1';
            WHEN sd =>
                size_compute <= '1';
            WHEN seek =>
                compute_max_min <= '1';
            WHEN shift_state =>
                compute_shift_value <= '1';
            WHEN filter_r =>
                filter_read <= '1';
                o_we <= '1';
            WHEN filter_w =>
                filter_write <= '1';
                o_we <= '0';
            WHEN end_state =>
                o_done <= '1';
        END CASE;
    END PROCESS;
    rst_datapath <= (i_rst OR NOT(i_start));
END Behavioral;

---------------------------------------------------------------------------------
--*****************************************************************************--
---------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;
ENTITY datapath IS
    PORT (
        i_clk : IN STD_LOGIC;
        i_rst : IN STD_LOGIC;
        i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        o_next_state : OUT STD_LOGIC;
        compute_size_dim_1 : IN STD_LOGIC;
        compute_size_dim_2 : IN STD_LOGIC;
        compute_size : IN STD_LOGIC;
        compute_max_min : IN STD_LOGIC;
        compute_shift_level : IN STD_LOGIC;
        compute_filter_r : IN STD_LOGIC;
        compute_filter_w : IN STD_LOGIC
    );
END datapath;

ARCHITECTURE Behavioral OF datapath IS
    SIGNAL max_pixel : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL min_pixel : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL dim_1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dim_2 : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL shift_value : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL size : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL offset_f : INTEGER RANGE 0 TO 16384;
    SIGNAL offset_mms : INTEGER RANGE 0 TO 16384;

BEGIN
    save_first_image_dimention : PROCESS (i_clk, i_rst)
    BEGIN
        IF (i_rst = '1') THEN
            dim_1 <= "00000000";
        ELSIF (i_clk'event AND i_clk = '0') THEN
            IF (compute_size_dim_1 = '1') THEN
                dim_1 <= i_data;
            END IF;
        END IF;
    END PROCESS;

    save_second_image_dimention : PROCESS (i_clk, i_rst)
    BEGIN
        IF (i_rst = '1') THEN
            dim_2 <= "00000000";
        ELSIF (i_clk'event AND i_clk = '0') THEN
            IF (compute_size_dim_2 = '1') THEN
                dim_2 <= i_data;
            END IF;
        END IF;
    END PROCESS;

    compute_image_size : PROCESS (i_clk, i_rst)
    BEGIN
        IF (i_rst = '1') THEN
            size <= "0000000000000000";
        ELSIF (i_clk'event AND i_clk = '0') THEN
            IF (compute_size = '1') THEN
                size <= STD_LOGIC_VECTOR(TO_UNSIGNED(TO_INTEGER(UNSIGNED(dim_1)) * TO_INTEGER(UNSIGNED(dim_2)), 16));
            END IF;
        END IF;
    END PROCESS;

    compute_max_min_pixel : PROCESS (i_clk, i_rst)
    BEGIN
        IF (i_rst = '1') THEN
            max_pixel <= "00000000";
            min_pixel <= "11111111";
        ELSIF (i_clk'event AND i_clk = '0') THEN
            IF (compute_max_min = '1') THEN
                IF (TO_INTEGER(UNSIGNED(i_data)) > TO_INTEGER(UNSIGNED(max_pixel))) THEN
                    max_pixel <= i_data;
                END IF;
                IF (TO_INTEGER(UNSIGNED(i_data)) < TO_INTEGER(UNSIGNED(min_pixel))) THEN
                    min_pixel <= i_data;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    compute_shift_value : PROCESS (i_clk, i_rst)
        VARIABLE sel : INTEGER RANGE 0 TO 255;
    BEGIN
        IF (i_rst = '1') THEN
            shift_value <= "0000";
        ELSIF (i_clk'event AND i_clk = '0') THEN
            IF (compute_shift_level = '1') THEN
                sel := (TO_INTEGER(UNSIGNED(max_pixel)) - TO_INTEGER(UNSIGNED(min_pixel)));
                IF (sel < 2) THEN
                    shift_value <= "1000";
                ELSIF (sel > 1 AND sel < 4) THEN
                    shift_value <= "0111";
                ELSIF (sel > 3 AND sel < 8) THEN
                    shift_value <= "0110";
                ELSIF (sel > 7 AND sel < 16) THEN
                    shift_value <= "0101";
                ELSIF (sel > 15 AND sel < 32) THEN
                    shift_value <= "0100";
                ELSIF (sel > 31 AND sel < 64) THEN
                    shift_value <= "0011";
                ELSIF (sel > 63 AND sel < 128) THEN
                    shift_value <= "0010";
                ELSIF (sel > 127 AND sel < 255) THEN
                    shift_value <= "0001";
                ELSE
                    shift_value <= "0000";
                END IF;
            END IF;
        END IF;
    END PROCESS;

    compute_filter_process : PROCESS (i_clk, i_rst)
        VARIABLE shlv : INTEGER RANGE 0 TO 8;
        VARIABLE sh_pixel : UNSIGNED (15 DOWNTO 0);
        VARIABLE sh_vector : STD_LOGIC_VECTOR (15 DOWNTO 0);
        VARIABLE data : INTEGER RANGE 0 TO 255;
        VARIABLE min_val : INTEGER RANGE 0 TO 255;
    BEGIN
        IF (i_rst = '1') THEN
            o_data <= "00000000";
        ELSIF (i_clk'event AND i_clk = '0') THEN
            IF (compute_filter_r = '1') THEN
                min_val := TO_INTEGER(UNSIGNED(min_pixel));
                data := TO_INTEGER(UNSIGNED(i_data));
                shlv := TO_INTEGER(UNSIGNED(shift_value));
                sh_pixel := shift_left(TO_UNSIGNED(data - min_val, 16), shlv);
                IF (TO_INTEGER(sh_pixel) > 255) THEN
                    o_data <= "11111111";
                ELSE
                    sh_vector := STD_LOGIC_VECTOR(sh_pixel);
                    o_data <= sh_vector(7 DOWNTO 0);
                END IF;
            END IF;
        END IF;
    END PROCESS;

    update_address : PROCESS (i_clk, i_rst)
    BEGIN
        IF (i_rst = '1') THEN
            offset_mms <= 0;
            offset_f <= 0;
            o_address <= "0000000000000000";
            o_next_state <= '1';
        ELSIF (i_clk'event AND i_clk = '0') THEN
            IF (compute_size_dim_1 = '1') THEN
                offset_mms <= 0;
                offset_f <= 0;
                o_address <= "0000000000000001";
                o_next_state <= '1';
            ELSIF (compute_size_dim_2 = '1') THEN
                offset_mms <= 0;
                offset_f <= 0;
                o_address <= "0000000000000001";
                o_next_state <= '1';
            ELSIF (compute_size = '1') THEN
                offset_mms <= 0;
                offset_f <= 0;
                o_address <= "0000000000000010";
                o_next_state <= '1';
            ELSIF (compute_max_min = '1') THEN
                offset_mms <= offset_mms + 1;
                offset_f <= 0;

                IF TO_INTEGER(UNSIGNED(size)) - offset_mms > 1 THEN
                    o_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(2 + offset_mms + 1, 16));
                    o_next_state <= '0';
                ELSE
                    o_next_state <= '1';
                    o_address <= "0000000000000010";
                END IF;
            ELSIF (compute_shift_level = '1') THEN
                offset_mms <= 0;
                offset_f <= 0;
                o_address <= "0000000000000010";
            ELSIF (compute_filter_r = '1') THEN
                offset_mms <= offset_f;
                offset_f <= 0;
                o_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(2 + offset_f + TO_INTEGER(UNSIGNED(size)), 16));
                IF TO_INTEGER(UNSIGNED(size)) - offset_f > 1 THEN
                    o_next_state <= '0';
                ELSE
                    o_next_state <= '1';
                END IF;
            ELSIF (compute_filter_w = '1') THEN
                offset_mms <= 0;
                offset_f <= offset_mms + 1;
                o_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(2 + offset_mms + 1, 16));
                o_next_state <= '1';
            END IF;
        END IF;
    END PROCESS;
END Behavioral;