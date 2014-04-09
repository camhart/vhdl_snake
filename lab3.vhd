library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_segment_display is
	generic(
		COUNTER_BITS : natural := 15
	);
	port(
		clk: in std_logic;
		data_in: in std_logic_vector(15 downto 0);
		dp_in: in std_logic_vector(3 downto 0);
		blank: in std_logic_vector(3 downto 0);
		seg: out std_logic_vector(6 downto 0);
		dp: out std_logic;
		an: out std_logic_vector(3 downto 0)
	);
end seven_segment_display;

architecture ssd of seven_segment_display is
	signal counter : std_logic_vector(COUNTER_BITS-1 downto 0) := (others => '0');
	signal anode_select : std_logic_vector(1 downto 0);
	signal wireA : std_logic_vector(3 downto 0);
begin
	process (clk)
	begin
		if (clk'event and clk='1') then
			counter <= std_logic_vector(unsigned(counter) + 1);
		end if;
	end process;
	
	anode_select <= counter(COUNTER_BITS-1 downto COUNTER_BITS-2);
	
	with anode_select select
		wireA <= data_in(3 downto 0) when "00",
					data_in(7 downto 4) when "01",
					data_in(11 downto 8) when "10",
					data_in(15 downto 12) when others;
			
	with anode_select select
		dp <= not dp_in(0) when "00",
				not dp_in(1) when "01",
				not dp_in(2) when "10",
				not dp_in(3) when others;
	
	with wireA select
		--0
		seg <= "1000000" when "0000",
		--1
		"1111001" when "0001",
		--2
		"0100100" when "0010",
		--3
		"0110000" when "0011",
		--4
		"0011001" when "0100",
		--5
		"0010010" when "0101",
		--6
		"0000010" when "0110",
		--7
		"1111000" when "0111",
		--8
		"0000000" when "1000",
		--9
		"0010000" when "1001",
		--A
		"0001000" when "1010",
		--B
		"0000011" when "1011",
		--C
		"1000110" when "1100",
		--D
		"0100001" when "1101",				
		--E
		"0000110" when "1110",				
		--F
		"0001110" when others;	
		
		an <= "1110" when anode_select="00" and blank(0)='0' else
				"1101" when anode_select="01" and blank(1)='0' else
				"1011" when anode_select="10" and blank(2)='0' else
				"0111" when anode_select="11" and blank(3)='0' else
				"1111";
end ssd;