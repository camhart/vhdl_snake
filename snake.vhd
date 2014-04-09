library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity snake is
	generic(
		MAX_COUNT : natural := 250_000_0;	--default 500_00
		WIN : natural := 32;
		SPEED_UP : natural := 39062 --(MAX_COUNT / 2) / WIN
	);
	port (
		clk, rx_in, btn : in std_logic;
		HS, VS : out std_logic;
		red, green : out std_logic_vector(2 downto 0);
		blue : out std_logic_vector(1 downto 0);
		seg: out std_logic_vector(6 downto 0);
		dp, rx_busy, audio_out: out std_logic;
		an: out std_logic_vector(3 downto 0)
	);
end snake;

architecture arch of snake is
	signal maxCount : natural := MAX_COUNT;
	signal eating : std_logic := '0';
	signal red_next, green_next : std_logic_vector(2 downto 0);
	signal blue_next : std_logic_vector(1 downto 0);
	--direction & valid & xcoord & ycoord
	signal food_reg, food_reg_next : std_logic_vector(13 downto 0) := "00000110000011";
	signal snake_head_reg : std_logic_vector(16 downto 0) := "10" & "1" & "0100111" & "0011101";
	signal snake_tail_reg : std_logic_vector(16 downto 0) := "10" & "1" & "0000000" & "0000000";
	signal HS_delay, VS_delay : std_logic;
	signal move : std_logic;
	type body_ram is array (0 to 35) of std_logic_vector(16 downto 0);
	signal snake_body_ram : body_ram := (
		"10" &"1" & "0000000" & "0000000",
		"10" & "1" & "0000000" & "0000000",
		"10" & "1" & "0000000" & "0000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000",
		"00000000000000000"
		);
	signal blank, last_column, last_row : std_logic;
	signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	signal draw_tail, draw_head, draw_body, draw_food, draw_wall, draw_background : std_logic;
	signal coord_x, coord_y : std_logic_vector(6 downto 0);
	signal sprite_x, sprite_y : std_logic_vector(2 downto 0);
	signal sprite_direction : std_logic_vector(1 downto 0);
	signal next_head_coord, head_coord : std_logic_vector(13 downto 0);
	--Rx UART signals
	signal data_strobe, rx_1, rx_2 : std_logic;
	signal char, next_char, data_out : std_logic_vector(7 downto 0);
	signal direction, next_direction : std_logic_vector(1 downto 0) := "00";
	--Count signal
	signal counter, count : unsigned(31 downto 0) := (others=>'0');
	signal background : std_logic_vector(7 downto 0) := "00000010";
	signal data_in : std_logic_vector(15 downto 0);
	signal you_lose, i_lost : std_logic := '0';
	signal food_eaten : unsigned(5 downto 0) := "000000";
	type state_type is (start_up, play, won, lost);
	signal state, next_state : state_type := start_up;	
	signal index : unsigned(5 downto 0) := "000011";
	signal music_state : std_logic_vector(2 downto 0) := "001";
begin

	music_state <= "001" when state=play or state=start_up else
						"010" when state=won else
						"100";

	mm : entity work.music_maker
		port map(clk=>clk, reset=>btn, state=>music_state, audio_out=>audio_out);

	process(clk, btn)
	begin
		if(btn='1') then
			state <= start_up;
		elsif(clk'event and clk='1') then
			state <= next_state;
		end if;
	end process;
	
	i_lost <= '1' when you_lose='1' and btn='0' else '0';

--	next_state <= lost when you_lose='1' else
--				play when (state=play and food_eaten<WIN) or (state=start_up and char /= "00000000") else
--				start_up when (state=start_up and char="00000000") or btn='1' else
--				won;

	next_state <= lost when i_lost='1' else
					  won when ((state=play and food_eaten>=WIN) or state=won) and btn='0' else
					  start_up when (state=start_up and char="00000000") or btn='1' else
					  play;

	--UART control system
	rx : entity work.rx
		port map(clk=>clk, rst=>btn, rx_in=>rx_1,
				data_out=>data_out, rx_busy=>rx_busy, data_strobe=>data_strobe);
				
	process(clk, btn)
	begin
		if(btn='1')then
			char <= "00000000";
		elsif(clk'event and clk='1') then
			char <= next_char;
			direction <= next_direction;
			rx_1 <= rx_2;
			rx_2 <= rx_in;
			food_reg <= food_reg_next;
		end if;
	end process;
	
	--next coord logic
	process(direction, snake_head_reg)
	begin
		if(direction="00")then
			next_head_coord <= snake_head_reg(13 downto 7) & std_logic_vector(unsigned(snake_head_reg(6 downto 0)) - 1);
		elsif(direction="01")then
			next_head_coord <= snake_head_reg(13 downto 7) & std_logic_vector(unsigned(snake_head_reg(6 downto 0)) + 1);
		elsif(direction="10")then
			next_head_coord <= std_logic_vector(unsigned(snake_head_reg(13 downto 7)) - 1) & snake_head_reg(6 downto 0);
		else
			next_head_coord <= std_logic_vector(unsigned(snake_head_reg(13 downto 7)) + 1) & snake_head_reg(6 downto 0);
		end if;
	end process;

	next_char <= data_out when data_strobe='1' else
			char;
			
	next_direction <= "00" when char="01110111" and snake_head_reg(16 downto 15) /= "01" else  --add and snake_head_reg(16 downto 15) /= "01"
			"01" when char="01110011" and snake_head_reg(16 downto 15) /= "00" else
			"10" when char="01100001" and snake_head_reg(16 downto 15) /= "11" else
			"11" when char="01100100" and snake_head_reg(16 downto 15) /= "10" else
			direction;
	--end UART control system
	
	--Count process for moving snake
	process(clk)
	begin
		if(clk'event and clk='1') then
			counter <= counter+1;
			count <= count + 1;
			move <= '0';
			--if(counter > MAX_COUNT) then
			if(counter > maxCount) then
				if(state=play) then
					move <= '1';
					head_coord <= next_head_coord;
				end if;
				counter <= (others=>'0');
			end if;
		end if;
	end process;
	
	--7 segment display
	ssd : entity work.seven_segment_display
	generic map(COUNTER_BITS =>15)
	port map(clk=>clk, data_in=>data_in, dp_in=>"0000", blank=>"0000", 
			an=>an, seg=>seg, dp=>dp);
	
	data_in <= "0000000000" & std_logic_vector(food_eaten) when food_eaten < 10 else
			"0000000000" & "01" & std_logic_vector(food_eaten(3 downto 0)-10) when food_eaten < 20 else
			"000000000010" & std_logic_vector(food_eaten(3 downto 0)-20) when food_eaten < 30 else
			"000000000011" & std_logic_vector(food_eaten(3 downto 0)-30);
	
	process(eating, state, food_reg)
	begin
		food_reg_next <= food_reg;
		if(state=start_up) then
			if(count(13 downto 7) > 77) then
				food_reg_next(13 downto 7) <= std_logic_vector(count(13 downto 7)-50);
			elsif(count(13 downto 7) < 2) then
				food_reg_next(13 downto 7) <= std_logic_vector(count(13 downto 7)+3);
			else
				food_reg_next(13 downto 7) <= std_logic_vector(count(13 downto 7));
			end if;
			if(count(6 downto 0) > 57) then
				if(count(6 downto 0) > 63) then
					food_reg_next(6 downto 0) <= "0001101";
				else
					food_reg_next(6 downto 0) <= "00" & std_logic_vector(count(4 downto 0));
				end if;
			elsif(count(6 downto 0) < 2) then
				food_reg_next(6 downto 0) <= std_logic_vector(count(6 downto 0)+3);
			else
				food_reg_next(6 downto 0) <= std_logic_vector(count(6 downto 0));
			end if;
		elsif(eating='1') then
			if(count(13 downto 7) > 77) then
				food_reg_next(13 downto 7) <= std_logic_vector(count(13 downto 7)-50);
			elsif(count(13 downto 7) < 2) then
				food_reg_next(13 downto 7) <= std_logic_vector(count(13 downto 7)+3);
			else
				food_reg_next(13 downto 7) <= std_logic_vector(count(13 downto 7));
			end if;
			if(count(6 downto 0) > 57) then
				if(count(6 downto 0) > 63) then
					food_reg_next(6 downto 0) <= "0001101";
				else
					food_reg_next(6 downto 0) <= "00" & std_logic_vector(count(4 downto 0));
				end if;
			elsif(count(6 downto 0) < 2) then
				food_reg_next(6 downto 0) <= std_logic_vector(count(6 downto 0)+3);
			else
				food_reg_next(6 downto 0) <= std_logic_vector(count(6 downto 0));
			end if;
		end if;
	end process;
	
	vga : entity work.vga_timing
		port map (clk=>clk, rst=>btn, HS=>HS_delay, VS=>VS_delay, last_column=>last_column, last_row=>last_row,
					blank=>blank, pixel_x=>pixel_x, pixel_y=>pixel_y);
					
	coord_x <= pixel_x(9 downto 3);
	coord_y <= pixel_y(9 downto 3);
	
	sprite_x <= pixel_x(2 downto 0);
	sprite_y <= pixel_y(2 downto 0);
	
	background <= "00000010" when state=play or state=start_up else 
			std_logic_vector(count(29 downto 22)) when state=won else
			"11100000";
	--detect objects on screen
	process(clk)
	begin
		if(clk'event and clk='1')then
			draw_tail <= '0';
			draw_head <= '0';
			draw_body <= '0';
			draw_food <= '0';
			draw_wall <= '0';
			if(unsigned(coord_x) < 2 or unsigned(coord_x) > 77 or unsigned(coord_y) < 2 or unsigned(coord_y) > 57)then
				draw_wall <= '1';
			elsif(state/=start_up and snake_tail_reg(13 downto 7) = coord_x and snake_tail_reg(6 downto 0) = coord_y)then
				sprite_direction <= snake_tail_reg(16 downto 15);
				draw_tail <= '1';
			elsif(state/=start_up and snake_head_reg(13 downto 7) = coord_x and snake_head_reg(6 downto 0) = coord_y)then
				sprite_direction <= snake_head_reg(16 downto 15);
				draw_head <= '1';
			elsif(state/=start_up and food_reg(13 downto 7) = coord_x and food_reg(6 downto 0) = coord_y)then
				draw_food <= '1';
			elsif(state/=start_up)then
				bodyLabel: 
				for i in 0 to 35 loop
					--if(snake_body_ram(i)(14)='1')then
					if(i < index)then
						if(snake_body_ram(i)(13 downto 7) = coord_x and snake_body_ram(i)(6 downto 0) = coord_y)then
							sprite_direction <= snake_body_ram(i)(16 downto 15);						
							draw_body <= '1';
						end if;
					else
						exit; --once one invalid body found, don't keep searching
					end if;
				end loop;					
			end if;
		end if;
	end process;
	
	process(blank, draw_tail, draw_head, draw_body, draw_food, draw_wall, draw_background, sprite_direction, background, sprite_x, sprite_y, counter, count)
	begin
		if(blank='1')then
			red_next <= "000";
			green_next <= "000";
			blue_next <= "00";
		elsif(draw_head='1')then
			red_next <= background(7 downto 5);
			green_next <= background(4 downto 2);
			blue_next <= background(1 downto 0);
			if(sprite_direction="10")then
				if(unsigned(sprite_y)>0 or unsigned(sprite_y)<7) then
					if((sprite_x="000" and (sprite_y="011" or sprite_y="100")) or (sprite_x="001" and sprite_y="100")) then
						red_next <= "111";
						blue_next <= "00";
						green_next <= "000";
					end if;
					if(unsigned(sprite_x)>1) then
						if((sprite_y="011" or sprite_y="100" or sprite_y="101") or (unsigned(sprite_x)>2 and sprite_y="010") or (unsigned(sprite_x)>5 and (sprite_y="001" or sprite_y="110"))) then
							green_next <= "111";
							red_next <= "000";
							blue_next <= "00";
						end if;
					end if;
					if(sprite_x="100" and sprite_y="011") then
						green_next <= "111";
						red_next <= "111";
						blue_next <= "00";
					elsif(sprite_x="111" and (sprite_y="011" or sprite_y="100")) then
						green_next <= "100";
						red_next <= "000";
						blue_next <= "00";
					end if;
				end if;
			elsif(sprite_direction="00") then
				if(unsigned(sprite_x)>0 or unsigned(sprite_x)<7) then
					if((sprite_y="000" and (sprite_x="011" or sprite_x="100")) or (sprite_y="001" and sprite_x="100")) then
						red_next <= "111";
						blue_next <= "00";
						green_next <= "000";
					end if;
					if(unsigned(sprite_y)>1) then
						if((sprite_x="011" or sprite_x="100" or sprite_x="101") or (unsigned(sprite_y)>2 and sprite_x="010") or (unsigned(sprite_y)>5 and (sprite_x="001" or sprite_x="110"))) then
							green_next <= "111";
							red_next <= "000";
							blue_next <= "00";
						end if;
					end if;
					if(sprite_y="100" and sprite_x="011") then
						green_next <= "111";
						red_next <= "111";
						blue_next <= "00";
					elsif(sprite_y="111" and (sprite_x="011" or sprite_x="100")) then
						green_next <= "100";
						red_next <= "000";
						blue_next <= "00";
					end if;
				end if;
			elsif(sprite_direction="01") then
				if(unsigned(sprite_x)>0 or unsigned(sprite_x)<7) then
					if((sprite_y="111" and (sprite_x="011" or sprite_x="100")) or (sprite_y="110" and sprite_x="100")) then
						red_next <= "111";
						blue_next <= "00";
						green_next <= "000";
					end if;
					if(unsigned(sprite_y)<6) then
						if((sprite_x="011" or sprite_x="100" or sprite_x="101") or (unsigned(sprite_y)<5 and sprite_x="010") or (unsigned(sprite_y)<2 and (sprite_x="001" or sprite_x="110"))) then
							green_next <= "111";
							red_next <= "000";
							blue_next <= "00";
						end if;
					end if;
					if(sprite_y="011" and sprite_x="011") then
						green_next <= "111";
						red_next <= "111";
						blue_next <= "00";
					elsif(sprite_y="000" and (sprite_x="011" or sprite_x="100")) then
						green_next <= "100";
						red_next <= "000";
						blue_next <= "00";
					end if;
				end if;	
			else
				if(unsigned(sprite_y)>0 or unsigned(sprite_y)<7) then
					if((sprite_x="111" and (sprite_y="011" or sprite_y="100")) or (sprite_x="110" and sprite_y="100")) then
						red_next <= "111";
						blue_next <= "00";
						green_next <= "000";
					end if;
					if(unsigned(sprite_x)<6) then
						if((sprite_y="011" or sprite_y="100" or sprite_y="101") or (unsigned(sprite_x)<5 and sprite_y="010") or (unsigned(sprite_x)<2 and (sprite_y="001" or sprite_y="110"))) then
							green_next <= "111";
							red_next <= "000";
							blue_next <= "00";
						end if;
					end if;
					if(sprite_x="011" and sprite_y="011") then
						green_next <= "111";
						red_next <= "111";
						blue_next <= "00";
					elsif(sprite_x="000" and (sprite_y="011" or sprite_y="100")) then
						green_next <= "100";
						red_next <= "000";
						blue_next <= "00";
					end if;
				end if;	
			end if;
		elsif(draw_tail='1')then
			red_next <=  background(7 downto 5);
			green_next <= background(4 downto 2);
			blue_next <= background(1 downto 0);
			if(sprite_direction="10")then
				if(sprite_y = "001")then
					if(unsigned(sprite_x) < 3)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "010")then
					if(unsigned(sprite_x) < 5)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "011")then
					if(unsigned(sprite_x) < 8)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "100")then
					if(unsigned(sprite_x) < 8)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "101")then
					if(unsigned(sprite_x) < 5)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "110")then
					if(unsigned(sprite_x) < 3)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				end if;
			elsif(sprite_direction="11") then
				if(sprite_y = "001")then
					if(unsigned(sprite_x) > 4)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "010")then
					if(unsigned(sprite_x) > 2)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "011")then
					if(unsigned(sprite_x) > 0)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "100")then
					if(unsigned(sprite_x) > 0)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "101")then
					if(unsigned(sprite_x) > 2)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_y = "110")then
					if(unsigned(sprite_x) > 4)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				end if;
			elsif(sprite_direction="01") then
				if(sprite_x = "001")then
					if(unsigned(sprite_y) > 3)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "010")then
					if(unsigned(sprite_y) > 1)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "011")then
					if(unsigned(sprite_y) > 0)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "100")then
					if(unsigned(sprite_y) > 0)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "101")then
					if(unsigned(sprite_y) > 1)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "110")then
					if(unsigned(sprite_y) > 3)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				end if;
			else 
				if(sprite_x = "001")then
					if(unsigned(sprite_y) < 4)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "010")then
					if(unsigned(sprite_y) < 6)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "011")then
					if(unsigned(sprite_y) < 8)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "100")then
					if(unsigned(sprite_y) < 8)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "101")then
					if(unsigned(sprite_y) < 6)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				elsif(sprite_x = "110")then
					if(unsigned(sprite_y) < 4)then
						red_next <= "000";
						blue_next <= "00";
						green_next <= "111";
					end if;
				end if;
			end if;
		elsif(draw_body='1')then
			red_next <= "000";
			green_next <= std_logic_vector(count(1 downto 0) & '1');
			blue_next <= "00";
		elsif(draw_food='1')then
			red_next <= background(7 downto 5);
			green_next <= background(4 downto 2);
			blue_next <= background(1 downto 0);
			--green
			if((unsigned(sprite_x) < 5 and sprite_y="000" and unsigned(sprite_x) > 2) or (unsigned(sprite_x)=4 and sprite_y="001")) then
				green_next <= "111";
			--red
			elsif((unsigned(sprite_x)<6 and unsigned(sprite_x)>1 and (sprite_y="010" or sprite_y="110")) or (unsigned(sprite_x)<7 and unsigned(sprite_x)>0 and (sprite_y="011" or sprite_y="101")) or sprite_y="100") then
					--or (unsigned(sprite_x)<5 and unsigned(sprite_x)>2 and sprite_y="111")) then
				red_next <= "111";
			end if;
			--white
			if(sprite_x="100" and sprite_y="011") then
				green_next <= "111";
				blue_next <= "11";
			end if;
		--wall color logic
		elsif(draw_wall='1')then
			red_next <= "101"; --'1' & std_logic(count(18)) & std_logic(count(17));
			green_next <= "010"; --std_logic(count(16))& '1' & std_logic(count(15));
			blue_next <= "10"; --std_logic_vector(count(16 downto 15));
		else --draw background
			red_next <= background(7 downto 5);
			green_next <= background(4 downto 2);
			blue_next <= background(1 downto 0);			
		end if;
	end process;
	
	--background <= "00000010";
	
	--change the snake direction
	process(clk, btn)
		variable dir_next, tail_next_dir : std_logic_vector(1 downto 0);
		variable coord_next : std_logic_vector(13 downto 0);
	begin
		if(btn='1')then
			--index <= "000011";
--			snake_body_ram(0) <= "10" &"1" & "1000000" & "0110000";
--			snake_body_ram(1) <= "10" & "1" & "1000001" & "0110000";
--			snake_body_ram(2) <= "10" & "1" & "1000010" & "0110000";
--			snake_head_reg <= "10" & "1" & "0111111" & "0110000";
--			snake_tail_reg <= "10" & "1" & "1000011" & "0110000";

			snake_body_ram(0) <= "10" &"1" & "0000000" & "0000000";
			snake_body_ram(1) <= "10" & "1" & "0000000" & "0000000";
			snake_body_ram(2) <= "10" & "1" & "0000000" & "0000000";
			snake_head_reg <= "10" & "1" & "0100111" & "0011101";
			snake_tail_reg <= "10" & "1" & "0000000" & "0000000";

			alabel:
				for i in 3 to 35 loop
					snake_body_ram(i) <= (others => '0');
				end loop;
		elsif(clk'event and clk='1')then
			if(move='1')then
				dir_next := snake_head_reg(16 downto 15);
				coord_next := snake_head_reg(13 downto 0);
				snake_head_reg(16 downto 15) <= direction;
				snake_head_reg(13 downto 0) <= head_coord;
				--look here brian
				bodyLabel: 
					for i in 0 to 35 loop
						if(i < index)then
							snake_body_ram(i)(16 downto 15) <= dir_next;	
							snake_body_ram(i)(13 downto 0) <= coord_next;
							snake_body_ram(i)(14) <= '1';
							dir_next := snake_body_ram(i)(16 downto 15);
							coord_next := snake_body_ram(i)(13 downto 0);
							if(i > 1)then
								tail_next_dir:=snake_body_ram(i-1)(16 downto 15);
							end if;
						end if;
					end loop;	
				snake_tail_reg(13 downto 0) <= coord_next;
				snake_tail_reg(14)<='1';
				snake_tail_reg(16 downto 15) <= tail_next_dir;
			end if;
		end if;
	end process;
	
	process(clk, btn)
	begin
		if(btn='1')then
			index <= "000011";
			you_lose <= '0';
			food_eaten <= (others => '0');
			maxCount <= MAX_COUNT;
		elsif(clk'event and clk='1')then
			eating <= '0';
			if(move='1' and state=play)then
				you_lose <= '0';
					if(food_reg = snake_head_reg(13 downto 0))then
						--eating food
						food_eaten <= food_eaten + 1;
						eating <= '1';
						index <= index + 1;
						maxCount <= maxCount - SPEED_UP;
					elsif(snake_head_reg(13 downto 0) = snake_tail_reg(13 downto 0))then
						--hit tail
						you_lose <= '1';
					elsif(unsigned(snake_head_reg(13 downto 7)) < 2 or unsigned(snake_head_reg(13 downto 7)) > 77 or unsigned(snake_head_reg(6 downto 0)) < 2 or unsigned(snake_head_reg(6 downto 0)) > 57)then
						--hit a wall
						you_lose <= '1';
					else
						--check for body
						bodyLabel: 
							for i in 0 to 35 loop
								--if(snake_body_ram(i)(14)='1' and you_lose = '0')then
								if(i < index and you_lose = '0')then
									if(snake_head_reg(13 downto 0) = snake_body_ram(i)(13 downto 0)) then
										you_lose <= '1';
										exit;
									end if;
								else
									exit;
								end if;
							end loop;
					end if;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if(clk'event and clk='1')then
			red <= red_next;
			green <= green_next;
			blue <= blue_next;
			HS <= HS_delay;
			VS <= VS_delay;
		end if;
	end process;
	
end arch;