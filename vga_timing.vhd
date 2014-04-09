library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_timing is
	port(
		clk,rst : in std_logic;
		HS,VS,last_column,last_row,blank : out std_logic;
		pixel_x,pixel_y : out std_logic_vector(9 downto 0)
	);
end vga_timing;

architecture vga of vga_timing is
signal pixel_en : std_logic := '0';
signal hs_counter, vs_counter, hs_counter_next, vs_counter_next : unsigned(9 downto 0) := (others => '0');
begin

	--pixel_clk
	process(clk)
	begin
		if(clk'event and clk='1')then
			pixel_en <= not pixel_en;
		end if;
	end process;
	
	--hs counter
	process(clk,rst)
	begin	
		if(rst='1') then
			hs_counter <= (others => '0');
		elsif(clk'event and clk='1') then
			if pixel_en = '1' then
				hs_counter <= hs_counter_next;
			end if;
		end if;			
	end process;
	
	hs_counter_next <= hs_counter + 1 when hs_counter < 799 else (others=>'0');
	
	last_column <= '1' when hs_counter = 639 else '0';
	HS <= '0' when hs_counter >= 656 and hs_counter <= 751 else '1';
	pixel_x <= std_logic_vector(hs_counter);
	
	--vs counter
	process(clk,rst)
	begin
		if(rst='1')then
			vs_counter <= (others => '0');
		elsif(clk'event and clk='1') then
			if(hs_counter = 799 and pixel_en='1') then
				vs_counter <= vs_counter_next;
			end if;
		end if;
	end process;
	
	vs_counter_next <= vs_counter + 1 when vs_counter < 520 else (others=>'0');
			
	last_row <= '1' when vs_counter = 479 else '0';
	
	VS <= '0' when vs_counter = 490 or vs_counter = 491 else '1';
	
	pixel_y <= std_logic_vector(vs_counter);
	
	blank <= '1' when hs_counter > 639 or vs_counter > 479 else '0';
	
end vga;
