
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity project_tb is
end project_tb;

architecture projecttb of project_tb is
constant c_CLOCK_PERIOD         : time := 15 ns;
signal   tb_done                : std_logic;
signal   mem_address            : std_logic_vector (15 downto 0) := (others => '0');
signal   tb_rst                 : std_logic := '0';
signal   tb_start               : std_logic := '0';
signal   tb_clk                 : std_logic := '0';
signal   mem_o_data,mem_i_data  : std_logic_vector (7 downto 0);
signal   enable_wire            : std_logic;
signal   mem_we                 : std_logic;

type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);

signal i: std_logic_vector(1 downto 0) := "00";


signal RAM: ram_type := (0 => std_logic_vector(to_unsigned(  2  , 8)),
			 1 => std_logic_vector(to_unsigned(  2  , 8)),
			 2 => std_logic_vector(to_unsigned(  141  , 8)),
			 3 => std_logic_vector(to_unsigned(  241  , 8)),
			 4 => std_logic_vector(to_unsigned(  56  , 8)),
			 5 => std_logic_vector(to_unsigned(  250  , 8)),
                         others => (others =>'0'));         
			 -- delta=240 shift=1    

signal RAM1: ram_type := (0 => std_logic_vector(to_unsigned(  2  , 8)),
			 1 => std_logic_vector(to_unsigned(  4  , 8)),
			 2 => std_logic_vector(to_unsigned(  141  , 8)),
			 3 => std_logic_vector(to_unsigned(  241  , 8)),
			 4 => std_logic_vector(to_unsigned(  56  , 8)),
			 5 => std_logic_vector(to_unsigned(  250  , 8)),
			 6 => std_logic_vector(to_unsigned(  227  , 8)),
			 7 => std_logic_vector(to_unsigned(  96  , 8)),
			 8 => std_logic_vector(to_unsigned(  80  , 8)),
			 9 => std_logic_vector(to_unsigned(  124  , 8)),
                         others => (others =>'0'));      

signal RAM2: ram_type := (0 => std_logic_vector(to_unsigned(  2  , 8)),
			 1 => std_logic_vector(to_unsigned(  2  , 8)),
			 2 => std_logic_vector(to_unsigned(  48  , 8)),
			 3 => std_logic_vector(to_unsigned(  241  , 8)),
			 4 => std_logic_vector(to_unsigned(  17  , 8)),
			 5 => std_logic_vector(to_unsigned(  54  , 8)),
                         others => (others =>'0'));              

component project_reti_logiche is
port (
      i_clk         : in  std_logic;
      i_start       : in  std_logic;
      i_rst         : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
      );
end component project_reti_logiche;


begin
UUT: project_reti_logiche
port map (
          i_clk      	=> tb_clk,
          i_start       => tb_start,
          i_rst      	=> tb_rst,
          i_data    	=> mem_o_data,
          o_address  	=> mem_address,
          o_done      	=> tb_done,
          o_en   	=> enable_wire,
          o_we 		=> mem_we,
          o_data    	=> mem_i_data
          );

p_CLK_GEN : process is
begin
    wait for c_CLOCK_PERIOD/2;
    tb_clk <= not tb_clk;
end process p_CLK_GEN;


MEM : process(tb_clk)
begin
if tb_clk'event and tb_clk = '1' then
    if enable_wire = '1' then
        if i = "00" then
            if mem_we = '1' then
                RAM(conv_integer(mem_address))  <= mem_i_data;
                mem_o_data                      <= mem_i_data after 1 ns;
            else
                mem_o_data <= RAM(conv_integer(mem_address)) after 1 ns;
            end if;
        elsif i ="01" then
            if mem_we = '1' then
                RAM1(conv_integer(mem_address))  <= mem_i_data;
                mem_o_data                      <= mem_i_data after 1 ns;
            else
                mem_o_data <= RAM1(conv_integer(mem_address)) after 1 ns;
            end if;
        elsif i = "10" then 
            if mem_we = '1' then
                RAM2(conv_integer(mem_address))  <= mem_i_data;
                mem_o_data                      <= mem_i_data after 1 ns;
            else
                mem_o_data <= RAM2(conv_integer(mem_address)) after 1 ns;
            end if;
        end if;
    end if;
end if;
end process;


test : process is
begin 
    wait for 100 ns;
    wait for c_CLOCK_PERIOD;
    tb_rst <= '1';
    wait for c_CLOCK_PERIOD;
    wait for 100 ns;
    tb_rst <= '0';
    wait for c_CLOCK_PERIOD;
    wait for 100 ns;
    tb_start <= '1';
    wait for c_CLOCK_PERIOD;
    wait until tb_done = '1';
    wait for c_CLOCK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for 100 ns;
    i <= "01";

    
    wait for 100 ns;
    tb_start <= '1';
    wait for c_CLOCK_PERIOD;
    wait until tb_done = '1';
    wait for c_CLOCK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for 100 ns;
    i <= "10";

    
    wait for 100 ns;
    tb_start <= '1';
    wait for c_CLOCK_PERIOD;
    wait until tb_done = '1';
    wait for c_CLOCK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for 100 ns;
    
	assert RAM(6) = std_logic_vector(to_unsigned( 170 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  170  found " & integer'image(to_integer(unsigned(RAM(6))))  severity failure; 
	assert RAM(7) = std_logic_vector(to_unsigned( 255 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  255  found " & integer'image(to_integer(unsigned(RAM(7))))  severity failure; 
	assert RAM(8) = std_logic_vector(to_unsigned( 0 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  0  found " & integer'image(to_integer(unsigned(RAM(8))))  severity failure; 
	assert RAM(9) = std_logic_vector(to_unsigned( 255 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  255  found " & integer'image(to_integer(unsigned(RAM(9))))  severity failure;

	assert RAM1(10) = std_logic_vector(to_unsigned( 170 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  255  found " & integer'image(to_integer(unsigned(RAM1(6))))  severity failure; 
	assert RAM1(11) = std_logic_vector(to_unsigned( 255 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  32  found " & integer'image(to_integer(unsigned(RAM1(7))))  severity failure; 
	assert RAM1(12) = std_logic_vector(to_unsigned( 0 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  0  found " & integer'image(to_integer(unsigned(RAM1(8))))  severity failure; 
	assert RAM1(13) = std_logic_vector(to_unsigned( 255 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  88  found " & integer'image(to_integer(unsigned(RAM1(9))))  severity failure;
    assert RAM1(14) = std_logic_vector(to_unsigned( 255 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  255  found " & integer'image(to_integer(unsigned(RAM1(6))))  severity failure; 
	assert RAM1(15) = std_logic_vector(to_unsigned( 80 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  32  found " & integer'image(to_integer(unsigned(RAM1(7))))  severity failure; 
	assert RAM1(16) = std_logic_vector(to_unsigned( 48 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  0  found " & integer'image(to_integer(unsigned(RAM1(8))))  severity failure; 
	assert RAM1(17) = std_logic_vector(to_unsigned( 136 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  88  found " & integer'image(to_integer(unsigned(RAM1(9))))  severity failure;

	assert RAM2(6) = std_logic_vector(to_unsigned( 62 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  62  found " & integer'image(to_integer(unsigned(RAM2(6))))  severity failure; 
	assert RAM2(7) = std_logic_vector(to_unsigned( 255 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  255  found " & integer'image(to_integer(unsigned(RAM2(7))))  severity failure; 
	assert RAM2(8) = std_logic_vector(to_unsigned( 0 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  0  found " & integer'image(to_integer(unsigned(RAM2(8))))  severity failure; 
	assert RAM2(9) = std_logic_vector(to_unsigned( 74 , 8)) report " TEST FALLITO (WORKING ZONE). Expected  74  found " & integer'image(to_integer(unsigned(RAM2(9))))  severity failure;


    assert false report "Simulation Ended! TEST PASSATO" severity failure;
end process test;

end projecttb; 
